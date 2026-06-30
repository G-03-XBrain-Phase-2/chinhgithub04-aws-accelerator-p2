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
    ai_engine_url = os.environ.get('AI_ENGINE_URL')
    tenant_id = os.environ.get('TENANT_ID', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d')
    
    print("Environment Config:")
    print(f"  TELEMETRY_BUCKET: {telemetry_bucket}")
    print(f"  RAW_CUR_BUCKET: {raw_cur_bucket}")
    print(f"  ATHENA_DATABASE: {athena_database}")
    print(f"  ATHENA_WORKGROUP: {athena_workgroup}")
    print(f"  ATHENA_RESULTS_URI: {athena_results_uri}")
    print(f"  IDEMPOTENCY_TABLE: {idempotency_table}")
    print(f"  AI_ENGINE_URL: {ai_engine_url}")
    print(f"  TENANT_ID: {tenant_id}")
    
    # 1. Determine date range
    # Support manual date input in event like: {"date": "2026-03-26"}
    override_date = event.get('date') if isinstance(event, dict) else None
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
        
    # 3. Query CUR for yesterday
    cur_query = f"""
    SELECT * FROM cur_line_items 
    WHERE substr(line_item_usage_start_date, 1, 10) = '{yesterday_str}'
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
            
    # 6. TODO: Ghi dữ liệu vào DynamoDB feature store (Chưa có schema từ đội AI)
    print("TODO: Ghi dữ liệu vào DynamoDB feature store (chưa có schema từ đội AI)")
    
    # 7. TODO: Thu thập và gửi metrics hiệu năng từ CloudWatch (chưa có mẫu metrics)
    print("TODO: Thu thập và gửi metrics hiệu năng từ CloudWatch (chưa có mẫu metrics)")
    
    # 8. Build POST Request Body
    # Get linked account id for business context
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
            "is_ad_hoc": False,
            "telemetry_delay_event": False,
            "s3_bucket_uri": s3_bucket_uri,
            "s3_object_checksum": s3_object_checksum,
            "business_context": business_context
        }
    else:
        req_body = {
            "data_source_type": "RAW_JSON",
            "is_ad_hoc": False,
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
