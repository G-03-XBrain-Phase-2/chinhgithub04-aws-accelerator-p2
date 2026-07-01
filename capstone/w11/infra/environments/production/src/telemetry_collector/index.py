import os
import json
import time
import gzip
import hashlib
import urllib.request
import urllib.error
from datetime import datetime, timedelta
import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
import botocore.session

def run_athena_query(query, database, workgroup, results_s3_uri):
    athena = boto3.client('athena')
    print(f"Executing Athena query: {query}")
    response = athena.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': database},
        WorkGroup=workgroup,
        ResultConfiguration={'OutputLocation': results_s3_uri}
    )
    query_execution_id = response['QueryExecutionId']
    
    # Poll query status
    while True:
        status_resp = athena.get_query_execution(QueryExecutionId=query_execution_id)
        status = status_resp['QueryExecution']['Status']['State']
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        time.sleep(1)
        
    if status != 'SUCCEEDED':
        err_msg = status_resp['QueryExecution']['Status'].get('StateChangeReason', 'Unknown error')
        raise Exception(f"Athena query {query_execution_id} failed: {err_msg}")
        
    return query_execution_id

def get_athena_results(query_execution_id):
    athena = boto3.client('athena')
    paginator = athena.get_paginator('get_query_results')
    results_pages = paginator.paginate(QueryExecutionId=query_execution_id)
    
    headers = []
    rows = []
    
    for page in results_pages:
        row_data = page['ResultSet']['Rows']
        if not row_data:
            continue
        
        if not headers:
            headers = [col.get('VarCharValue', '') for col in row_data[0]['Data']]
            row_data = row_data[1:]
            
        for row in row_data:
            val_list = [col.get('VarCharValue', '') for col in row['Data']]
            row_dict = {}
            for i, h in enumerate(headers):
                val = val_list[i] if i < len(val_list) else ''
                row_dict[h] = val
            rows.append(row_dict)
            
    return rows

def compute_std(lst):
    if len(lst) < 2:
        return 0.0
    m = sum(lst) / len(lst)
    variance = sum((x - m) ** 2 for x in lst) / (len(lst) - 1)
    return variance ** 0.5

def compute_median(lst):
    if not lst:
        return 0.0
    n = len(lst)
    s = sorted(lst)
    if n % 2 == 1:
        return s[n // 2]
    else:
        return (s[n // 2 - 1] + s[n // 2]) / 2.0

def compute_mad(lst):
    if not lst:
        return 0.0
    med = compute_median(lst)
    abs_devs = [abs(x - med) for x in lst]
    return compute_median(abs_devs)

def compute_slope(lst):
    n = len(lst)
    if n < 2:
        return 0.0
    x = list(range(1, n + 1))
    mean_x = sum(x) / n
    mean_y = sum(lst) / n
    num = sum((x[i] - mean_x) * (lst[i] - mean_y) for i in range(n))
    den = sum((x[i] - mean_x) ** 2 for i in range(n))
    if den == 0:
        return 0.0
    return num / den

def write_features_to_dynamodb(items, table_name):
    if not items:
        print("No feature store items to write.")
        return
    dynamodb = boto3.client('dynamodb')
    print(f"Batch writing {len(items)} items to feature store table: {table_name}")
    for i in range(0, len(items), 25):
        chunk = items[i:i+25]
        write_requests = []
        for item in chunk:
            ddb_item = {}
            for k, v in item.items():
                if v is None:
                    ddb_item[k] = {'NULL': True}
                elif isinstance(v, bool):
                    ddb_item[k] = {'BOOL': v}
                elif isinstance(v, (int, float)):
                    ddb_item[k] = {'N': str(v)}
                elif isinstance(v, str):
                    ddb_item[k] = {'S': v}
            write_requests.append({
                'PutRequest': {
                    'Item': ddb_item
                }
            })
        try:
            dynamodb.batch_write_item(
                RequestItems={
                    table_name: write_requests
                }
            )
        except Exception as e:
            print(f"Error batch writing to {table_name}: {e}")

def sign_request(url, method, headers, body_str):
    session = botocore.session.get_session()
    credentials = session.get_credentials()
    if not credentials:
        print("AWS credentials not found. Skipping SigV4 signing.")
        return headers
    
    request = AWSRequest(method=method, url=url, data=body_str, headers=headers)
    signer = SigV4Auth(credentials, 'execute-api', 'ap-southeast-1')
    signer.add_auth(request)
    return dict(request.headers)

def handler(event, context):
    print("Received event:", json.dumps(event))
    
    # Read environment variables
    telemetry_bucket = os.environ.get('TELEMETRY_BUCKET')
    raw_cur_bucket = os.environ.get('RAW_CUR_BUCKET')
    athena_database = os.environ.get('ATHENA_DATABASE')
    athena_workgroup = os.environ.get('ATHENA_WORKGROUP')
    athena_results_uri = os.environ.get('ATHENA_RESULTS_URI')
    idempotency_table = os.environ.get('IDEMPOTENCY_TABLE')
    feature_store_table = os.environ.get('FEATURE_STORE_TABLE')
    ai_engine_url = os.environ.get('AI_ENGINE_URL')
    tenant_id = os.environ.get('TENANT_ID', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d')
    
    print("Environment Config:")
    print(f"  TELEMETRY_BUCKET: {telemetry_bucket}")
    print(f"  RAW_CUR_BUCKET: {raw_cur_bucket}")
    print(f"  ATHENA_DATABASE: {athena_database}")
    print(f"  ATHENA_WORKGROUP: {athena_workgroup}")
    print(f"  ATHENA_RESULTS_URI: {athena_results_uri}")
    print(f"  IDEMPOTENCY_TABLE: {idempotency_table}")
    print(f"  FEATURE_STORE_TABLE: {feature_store_table}")
    print(f"  AI_ENGINE_URL: {ai_engine_url}")
    print(f"  TENANT_ID: {tenant_id}")
    
    # 1. Determine date range
    # Support manual date input in event like: {"date": "2026-03-26"}
    override_date = event.get('date') if isinstance(event, dict) else None
    override_account = event.get('linked_account_id') if isinstance(event, dict) else None
    is_ad_hoc = event.get('is_ad_hoc', False) if isinstance(event, dict) else False
    if override_date:
        today_dt = datetime.strptime(override_date, '%Y-%m-%d')
    else:
        today_dt = datetime.utcnow()
        
    yesterday_dt = today_dt - timedelta(days=1)
    yesterday_str = yesterday_dt.strftime('%Y-%m-%d')
    today_str = today_dt.strftime('%Y-%m-%d')
    print(f"Targeting yesterday: {yesterday_str}, today: {today_str}")
    
    # 2. Initialize Athena tables if not exists
    ddl_cur = f"""
    CREATE EXTERNAL TABLE IF NOT EXISTS cur_line_items (
      bill_billing_period_start_date string,
      bill_payer_account_id string,
      line_item_usage_account_id string,
      line_item_usage_account_name string,
      line_item_line_item_type string,
      line_item_usage_start_date string,
      line_item_usage_end_date string,
      line_item_product_code string,
      line_item_usage_type string,
      line_item_operation string,
      line_item_resource_id string,
      line_item_usage_amount double,
      pricing_unit string,
      line_item_unblended_rate double,
      line_item_unblended_cost double,
      line_item_currency_code string,
      product_product_name string,
      product_region_code string,
      product_instance_type string,
      resource_tags_user_team string,
      resource_tags_user_environment string,
      resource_tags_user_cost_center string,
      resource_tags_user_owner string
    )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION 's3://{raw_cur_bucket}/cur/'
    TBLPROPERTIES ("skip.header.line.count"="1")
    """
    
    ddl_ce = f"""
    CREATE EXTERNAL TABLE IF NOT EXISTS cost_explorer_daily (
      date string,
      linked_account_id string,
      linked_account_name string,
      service string,
      service_code string,
      region string,
      unblended_cost double,
      is_estimated string
    )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION 's3://{raw_cur_bucket}/cost-explorer/'
    TBLPROPERTIES ("skip.header.line.count"="1")
    """
    
    try:
        run_athena_query(ddl_cur, athena_database, athena_workgroup, athena_results_uri)
        run_athena_query(ddl_ce, athena_database, athena_workgroup, athena_results_uri)
    except Exception as e:
        print(f"Error creating Athena tables: {e}")
        return {
            'statusCode': 500,
            'body': f"Failed to initialize Athena tables: {str(e)}"
        }
        
    account_filter = f"AND line_item_usage_account_id = '{override_account}'" if override_account else ""
    cur_query = f"""
    SELECT * FROM cur_line_items 
    WHERE substr(line_item_usage_start_date, 1, 10) = '{yesterday_str}'
    {account_filter}
    """
    
    cur_rows = []
    try:
        qid = run_athena_query(cur_query, athena_database, athena_workgroup, athena_results_uri)
        cur_rows = get_athena_results(qid)
        print(f"CUR query returned {len(cur_rows)} records for {yesterday_str}")
    except Exception as e:
        print(f"Error querying CUR: {e}")
        
    # 4. Process data and generate payload
    telemetry_delay_event = False
    cur_items = []
    ce_items = []
    s3_object_checksum = ""
    s3_bucket_uri = ""
    
    if len(cur_rows) > 0:
        # Convert CUR rows to schema format
        for r in cur_rows:
            # Map tag environments
            env_val = r.get('resource_tags_user_environment', '').strip()
            if not env_val or env_val.lower() == 'null':
                env_val = 'unknown'
                
            item = {
                "bill_billing_period_start_date": r.get('bill_billing_period_start_date', ''),
                "bill_payer_account_id": r.get('bill_payer_account_id', ''),
                "line_item_usage_start_date": r.get('line_item_usage_start_date', ''),
                "line_item_usage_end_date": r.get('line_item_usage_end_date', ''),
                "line_item_usage_account_id": r.get('line_item_usage_account_id', ''),
                "line_item_usage_account_name": r.get('line_item_usage_account_name', ''),
                "line_item_line_item_type": r.get('line_item_line_item_type', 'Usage'),
                "line_item_product_code": r.get('line_item_product_code', ''),
                "line_item_usage_type": r.get('line_item_usage_type', ''),
                "line_item_operation": r.get('line_item_operation', ''),
                "line_item_resource_id": r.get('line_item_resource_id') or None,
                "pricing_unit": r.get('pricing_unit', 'Hrs'),
                "line_item_currency_code": r.get('line_item_currency_code', 'USD'),
                "product_product_name": r.get('product_product_name', ''),
                "product_region_code": r.get('product_region_code') or None,
                "product_instance_type": r.get('product_instance_type') or None,
                "resource_tags_user_environment": env_val,
                "resource_tags_user_team": r.get('resource_tags_user_team') or None,
                "resource_tags_user_owner": r.get('resource_tags_user_owner') or None,
                "resource_tags_user_cost_center": r.get('resource_tags_user_cost_center') or None,
            }
            
            # Numeric conversion
            try:
                item["line_item_usage_amount"] = float(r.get('line_item_usage_amount') or 0.0)
            except ValueError:
                item["line_item_usage_amount"] = 0.0
                
            try:
                item["line_item_unblended_rate"] = float(r.get('line_item_unblended_rate') or 0.0)
            except ValueError:
                item["line_item_unblended_rate"] = 0.0
                
            try:
                item["line_item_unblended_cost"] = float(r.get('line_item_unblended_cost') or 0.0)
            except ValueError:
                item["line_item_unblended_cost"] = 0.0
                
            # usage_density_24h calculation
            if item["line_item_product_code"] == 'AmazonEC2':
                item["usage_density_24h"] = min(item["line_item_usage_amount"] / 24.0, 1.0)
            else:
                item["usage_density_24h"] = 1.0
                
            cur_items.append(item)
            
        # Serialize to JSON, gzip and upload to Telemetry Bucket
        json_payload = json.dumps(cur_items).encode('utf-8')
        compressed_payload = gzip.compress(json_payload)
        s3_object_checksum = hashlib.sha256(compressed_payload).hexdigest()
        
        s3_key = f"cur/{yesterday_str}.json.gz"
        s3_bucket_uri = f"s3://{telemetry_bucket}/{s3_key}"
        
        s3 = boto3.client('s3')
        s3.put_object(
            Bucket=telemetry_bucket,
            Key=s3_key,
            Body=compressed_payload
        )
        print(f"Uploaded CUR telemetry file to: {s3_bucket_uri}")
        
    else:
        # Fallback to Cost Explorer
        print("No CUR records found. Querying Cost Explorer signal...")
        telemetry_delay_event = True
        
        # Lookback window: 30 days rolling
        thirty_days_ago_dt = yesterday_dt - timedelta(days=29)
        thirty_days_ago_str = thirty_days_ago_dt.strftime('%Y-%m-%d')
        
        ce_query = f"""
        SELECT * FROM cost_explorer_daily 
        WHERE date >= '{thirty_days_ago_str}' AND date <= '{yesterday_str}'
        """
        
        ce_rows = []
        try:
            qid = run_athena_query(ce_query, athena_database, athena_workgroup, athena_results_uri)
            ce_rows = get_athena_results(qid)
            print(f"CE fallback query returned {len(ce_rows)} records")
        except Exception as e:
            print(f"Error querying Cost Explorer signal: {e}")
            
        for r in ce_rows:
            is_est = r.get('is_estimated', 'false').lower() == 'true'
            item = {
                "date": r.get('date', ''),
                "linked_account_id": r.get('linked_account_id', ''),
                "linked_account_name": r.get('linked_account_name', ''),
                "service": r.get('service', ''),
                "service_code": r.get('service_code', ''),
                "region": r.get('region') or None,
                "is_estimated": is_est
            }
            try:
                item["unblended_cost"] = float(r.get('unblended_cost') or 0.0)
            except ValueError:
                item["unblended_cost"] = 0.0
                
            ce_items.append(item)
            
    # 5. Handle Idempotency in DynamoDB
    idempotency_key = f"{tenant_id}:{yesterday_str}:detect"
    dynamodb = boto3.client('dynamodb')
    
    if not is_ad_hoc:
        now_epoch = int(time.time())
        ttl_expiry = now_epoch + 24 * 3600  # 24 hours expiry
        
        try:
            dynamodb.put_item(
                TableName=idempotency_table,
                Item={
                    'idempotency_key': {'S': idempotency_key},
                    'status': {'S': 'IN_PROGRESS'},
                    'created_at': {'N': str(now_epoch)},
                    'ttl': {'N': str(ttl_expiry)}
                },
                ConditionExpression='attribute_not_exists(idempotency_key)'
            )
            print(f"Idempotency key {idempotency_key} registered as IN_PROGRESS")
        except dynamodb.exceptions.ConditionalCheckFailedException:
            # Check if already processed
            resp = dynamodb.get_item(
                TableName=idempotency_table,
                Key={'idempotency_key': {'S': idempotency_key}}
            )
            item = resp.get('Item', {})
            status = item.get('status', {}).get('S', '')
            if status == 'IN_PROGRESS':
                print(f"Idempotency key {idempotency_key} is IN_PROGRESS. Skipping execution.")
                return {
                    'statusCode': 409,
                    'body': f"Execution already in progress for key {idempotency_key}"
                }
            elif status == 'COMPLETED':
                print(f"Idempotency key {idempotency_key} is COMPLETED. Returning cached response.")
                cached_resp_str = item.get('response_cache', {}).get('S', '{}')
                return {
                    'statusCode': 200,
                    'body': json.loads(cached_resp_str)
                }
            
    # 6. Compute and write features to DynamoDB feature store
    if cur_items and feature_store_table:
        print(f"Generating and materializing features to DynamoDB for date {yesterday_str}...")
        try:
            # 1. Determine date range for 28-day history
            start_date_dt = yesterday_dt - timedelta(days=28)
            start_date_str = start_date_dt.strftime('%Y-%m-%d')
            print(f"Retrieving 28-day history from {start_date_str} to {yesterday_str}...")
            
            history_query = f"""
            SELECT 
              line_item_resource_id, 
              substr(line_item_usage_start_date, 1, 10) as usage_date,
              line_item_product_code,
              sum(line_item_unblended_cost) as daily_cost
            FROM cur_line_items
            WHERE substr(line_item_usage_start_date, 1, 10) >= '{start_date_str}'
              AND substr(line_item_usage_start_date, 1, 10) <= '{yesterday_str}'
              {account_filter}
            GROUP BY line_item_resource_id, substr(line_item_usage_start_date, 1, 10), line_item_product_code
            """
            
            qid = run_athena_query(history_query, athena_database, athena_workgroup, athena_results_uri)
            history_rows = get_athena_results(qid)
            print(f"Retrieved {len(history_rows)} historical rows from Athena.")
            
            # 3. Map the rows into a structured timeseries dictionary: resource_id -> { date_str: cost }
            resource_history = {}
            resource_product = {}
            for row in history_rows:
                res_id = row.get('line_item_resource_id')
                if not res_id or res_id.lower() == 'null':
                    continue
                date_str = row.get('usage_date')
                prod_code = row.get('line_item_product_code')
                
                try:
                    cost = float(row.get('daily_cost') or 0.0)
                except ValueError:
                    cost = 0.0
                    
                if res_id not in resource_history:
                    resource_history[res_id] = {}
                resource_history[res_id][date_str] = cost
                resource_product[res_id] = prod_code
                
            # 4. Generate the date list chronologically
            date_list = []
            curr = start_date_dt
            while curr <= yesterday_dt:
                date_list.append(curr.strftime('%Y-%m-%d'))
                curr += timedelta(days=1)
                
            # 5. Compute raw features for each resource
            resource_features = []
            for res_id, history in resource_history.items():
                cost_series = []
                for d in date_list:
                    cost_series.append(history.get(d, 0.0))
                
                cost_t = cost_series[-1]
                history_costs = cost_series[0:28]
                
                # Active days count (age_days)
                age_days = len(history)
                
                last_7 = history_costs[-7:]
                last_14 = history_costs[-14:]
                
                rolling_avg = sum(last_7) / len(last_7) if last_7 else 0.0
                rolling_std = compute_std(last_7)
                rolling_median = compute_median(last_14)
                rolling_mad = compute_mad(last_14)
                slope_14d = compute_slope(last_14)
                
                if age_days < 28:
                    cost_pct_change_28d = 0.0
                else:
                    cost_t_28 = history_costs[0]
                    cost_pct_change_28d = (cost_t - cost_t_28) / (cost_t_28 + 1e-6)
                    
                cost_ratio_to_7d_avg = cost_t / (rolling_avg + 1e-6)
                absolute_cost_spike = max(0.0, cost_t - 3.0 * rolling_std)
                
                resource_features.append({
                    'resource_id': res_id,
                    'date': yesterday_str,
                    'product_code': resource_product[res_id],
                    'cost_t': cost_t,
                    'age_days': age_days,
                    'rolling_avg': rolling_avg,
                    'rolling_std': rolling_std,
                    'rolling_median': rolling_median,
                    'rolling_mad': rolling_mad,
                    'slope_14d': slope_14d,
                    'cost_pct_change_28d': cost_pct_change_28d,
                    'cost_ratio_to_7d_avg': cost_ratio_to_7d_avg,
                    'absolute_cost_spike': absolute_cost_spike
                })
                
            # 6. Group costs by (account_id, product_code) to compute peer ratio
            peer_groups = {}
            resource_account = {}
            for r in cur_items:
                res_id = r.get('line_item_resource_id')
                if res_id:
                    acc_id = r.get('line_item_usage_account_id', tenant_id)
                    resource_account[res_id] = acc_id
                    
                    prod_code = r.get('line_item_product_code', '')
                    cost_t = 0.0
                    try:
                        cost_t = float(r.get('line_item_unblended_cost') or 0.0)
                    except ValueError:
                        pass
                        
                    key = (acc_id, prod_code)
                    if key not in peer_groups:
                        peer_groups[key] = []
                    peer_groups[key].append(cost_t)
                    
            peer_medians = {}
            for key, costs in peer_groups.items():
                peer_medians[key] = compute_median(costs)
                
            for f in resource_features:
                res_id = f['resource_id']
                acc_id = resource_account.get(res_id, tenant_id)
                prod_code = f['product_code']
                cost_t = f['cost_t']
                group_median = peer_medians.get((acc_id, prod_code), 0.0)
                f['peer_ratio'] = cost_t / (group_median + 1e-6)
                
            # 7. Apply Cold-start Imputation for resource with age_days < 14
            metrics_to_impute = [
                'rolling_avg', 'rolling_std', 'rolling_median', 'rolling_mad',
                'slope_14d', 'cost_pct_change_28d', 'cost_ratio_to_7d_avg',
                'absolute_cost_spike', 'peer_ratio'
            ]
            
            product_medians = {}
            global_medians = {}
            
            for metric in metrics_to_impute:
                global_vals = []
                prod_vals = {}
                for f in resource_features:
                    if f['age_days'] >= 14:
                        val = f[metric]
                        global_vals.append(val)
                        prod_code = f['product_code']
                        if prod_code not in prod_vals:
                            prod_vals[prod_code] = []
                        prod_vals[prod_code].append(val)
                        
                global_medians[metric] = compute_median(global_vals) if global_vals else 0.0
                for prod_code, vals in prod_vals.items():
                    if prod_code not in product_medians:
                        product_medians[prod_code] = {}
                    product_medians[prod_code][metric] = compute_median(vals)
                    
            for f in resource_features:
                if f['age_days'] < 14:
                    prod_code = f['product_code']
                    for metric in metrics_to_impute:
                        imputed_val = product_medians.get(prod_code, {}).get(metric)
                        if imputed_val is None:
                            imputed_val = global_medians[metric]
                        
                        # Preserve spikes for anomaly-detecting metrics
                        if metric in ('cost_ratio_to_7d_avg', 'absolute_cost_spike', 'peer_ratio'):
                            f[metric] = max(f[metric], imputed_val)
                        elif metric in ('rolling_avg', 'rolling_std'):
                            # Only impute baseline stats if they are 0.0
                            if f[metric] == 0.0:
                                f[metric] = imputed_val
                        else:
                            # Unconditionally impute 14d/28d stats
                            f[metric] = imputed_val
                        
            # 8. Build final DynamoDB items and write
            cur_lookup = {r['line_item_resource_id']: r for r in cur_items if r.get('line_item_resource_id')}
            ddb_items = []
            now_epoch = int(time.time())
            materialized_at = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
            ttl_expiry_fs = now_epoch + 35 * 24 * 3600
            
            for f in resource_features:
                res_id = f['resource_id']
                r = cur_lookup.get(res_id)
                if not r:
                    continue
                
                env = r.get('resource_tags_user_environment')
                if not env or env.lower() in ('null', 'unknown'):
                    env = None
                    
                team = r.get('resource_tags_user_team')
                if not team or team.lower() == 'null':
                    team = 'team_missing'
                    
                owner = r.get('resource_tags_user_owner')
                if not owner or owner.lower() == 'null':
                    owner = 'owner_missing'
                    
                cost_center = r.get('resource_tags_user_cost_center')
                if not cost_center or cost_center.lower() == 'null':
                    cost_center = None
                    
                usage_amount = 0.0
                try:
                    usage_amount = float(r.get('line_item_usage_amount') or 0.0)
                except ValueError:
                    pass
                    
                unblended_cost = 0.0
                try:
                    unblended_cost = float(r.get('line_item_unblended_cost') or 0.0)
                except ValueError:
                    pass
                
                # Simple logic for usage density: if product code is AmazonEC2, density is usage_amount / 24, max 1.0. Else 1.0
                if r.get('line_item_product_code') == 'AmazonEC2':
                    usage_density = min(usage_amount / 24.0, 1.0)
                else:
                    usage_density = 1.0
                
                item = {
                    'resource_id': res_id,
                    'date': yesterday_str,
                    'line_item_usage_account_id': r.get('line_item_usage_account_id', ''),
                    'line_item_product_code': r.get('line_item_product_code', ''),
                    'line_item_usage_type': r.get('line_item_usage_type', ''),
                    'pricing_unit': r.get('pricing_unit', ''),
                    'line_item_usage_amount': usage_amount,
                    'line_item_unblended_cost': unblended_cost,
                    'is_estimated': False,
                    
                    'rolling_avg': f['rolling_avg'],
                    'rolling_std': f['rolling_std'],
                    'rolling_median': f['rolling_median'],
                    'rolling_mad': f['rolling_mad'],
                    'slope_14d': f['slope_14d'],
                    'cost_pct_change_28d': f['cost_pct_change_28d'],
                    'cost_ratio_to_7d_avg': f['cost_ratio_to_7d_avg'],
                    'absolute_cost_spike': f['absolute_cost_spike'],
                    'peer_ratio': f['peer_ratio'],
                    'age_days': f['age_days'],
                    
                    'cpu_mean': None,
                    'usage_density_24h': usage_density,
                    'memory_mib': None,
                    'network_in_bytes': None,
                    'network_out_bytes': None,
                    'disk_io_ops': None,
                    'database_connections': None,
                    'gpu_utilization': None,
                    
                    'resource_tags_user_environment': env,
                    'resource_tags_user_team': team,
                    'resource_tags_user_owner': owner,
                    'resource_tags_user_cost_center': cost_center,
                    
                    'materialized_at': materialized_at,
                    'schema_version': '1.0.0',
                    'ttl_expiry': ttl_expiry_fs
                }
                ddb_items.append(item)
                
            write_features_to_dynamodb(ddb_items, feature_store_table)
            print("Successfully materialized all features to feature store.")
        except Exception as ex:
            print(f"Error computing or materializing features: {ex}")
            

    
    # 7. TODO: Thu thập và gửi metrics hiệu năng từ CloudWatch (chưa có mẫu metrics)
    print("TODO: Thu thập và gửi metrics hiệu năng từ CloudWatch (chưa có mẫu metrics)")
    
    # 8. Build POST Request Body
    # Get linked account id for business context
    if override_account:
        linked_acc = override_account
    else:
        linked_acc = "200000000010"
        if cur_items:
            linked_acc = cur_items[0]["line_item_usage_account_id"]
        elif ce_items:
            linked_acc = ce_items[0]["linked_account_id"]
        
    business_context = {
        "linked_account_id": linked_acc,
        "traffic_volume": 1250000,
        "traffic_source": "ALB",
        "campaign_flag": False,
        "load_test_flag": False,
        "migration_flag": False
    }
    
    if not telemetry_delay_event:
        req_body = {
            "data_source_type": "S3_POINTER",
            "is_ad_hoc": is_ad_hoc,
            "telemetry_delay_event": False,
            "s3_bucket_uri": s3_bucket_uri,
            "s3_object_checksum": s3_object_checksum,
            "business_context": business_context
        }
    else:
        req_body = {
            "data_source_type": "RAW_JSON",
            "is_ad_hoc": is_ad_hoc,
            "telemetry_delay_event": True,
            "missing_resources": ["AmazonRDS", "AmazonDynamoDB"],
            "current_ce_cost_gap_usd": 50.0,
            "comparison_window": {
                "start_date": yesterday_str,
                "end_date": yesterday_str
            },
            "business_context": business_context,
            "aws_cost_explorer_daily": ce_items
        }
        
    req_body_str = json.dumps(req_body)
    req_body_hash = hashlib.sha256(req_body_str.encode('utf-8')).hexdigest()
    
    # Build request headers
    req_timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Tenant-Id': tenant_id,
        'X-Idempotency-Key': idempotency_key,
        'X-Payload-SHA256': req_body_hash,
        'X-Request-Timestamp': req_timestamp,
        'X-Dry-Run-Mode': 'false'
    }
    
    # 9. Sign request using AWS SigV4
    headers = sign_request(ai_engine_url, 'POST', headers, req_body_str)
    
    # 10. Call AI Engine /detect API
    print(f"Calling AI Engine URL: {ai_engine_url}")
    print(f"Headers: {json.dumps(headers)}")
    print(f"Payload sent to AI Engine: {req_body_str}")
    
    req = urllib.request.Request(
        ai_engine_url,
        data=req_body_str.encode('utf-8'),
        headers=headers,
        method='POST'
    )
    
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            response_body = response.read().decode('utf-8')
            response_data = json.loads(response_body)
            print("AI Engine Response:", response_body)
            
            # Update idempotency store to COMPLETED
            if not is_ad_hoc:
                dynamodb.update_item(
                    TableName=idempotency_table,
                    Key={'idempotency_key': {'S': idempotency_key}},
                    UpdateExpression='SET #s = :completed, response_cache = :resp, payload_sha256 = :sha',
                    ExpressionAttributeNames={'#s': 'status'},
                    ExpressionAttributeValues={
                        ':completed': {'S': 'COMPLETED'},
                        ':resp': {'S': response_body},
                        ':sha': {'S': req_body_hash}
                    }
                )
                print(f"Idempotency key {idempotency_key} updated to COMPLETED")
            
            return {
                'statusCode': 200,
                'body': response_data
            }
            
    except urllib.error.HTTPError as e:
        err_body = e.read().decode('utf-8')
        print(f"HTTP Error {e.code}: {err_body}")
        
        # Remove idempotency item so it can be retried
        if not is_ad_hoc:
            dynamodb.delete_item(
                TableName=idempotency_table,
                Key={'idempotency_key': {'S': idempotency_key}}
            )
        return {
            'statusCode': e.code,
            'body': f"AI Engine HTTP Error: {err_body}"
        }
    except Exception as e:
        print(f"Failed to request AI Engine: {e}")
        # Remove idempotency item
        dynamodb.delete_item(
            TableName=idempotency_table,
            Key={'idempotency_key': {'S': idempotency_key}}
        )
        return {
            'statusCode': 500,
            'body': f"AI Engine Connection Error: {str(e)}"
        }
