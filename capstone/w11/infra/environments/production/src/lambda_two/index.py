import os
import json
import urllib.request
import urllib.error
import hashlib
import uuid
from datetime import datetime
import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
import botocore.session

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
    print("Lambda Decision Handler invoked via SQS!")
    
    ai_engine_url = os.environ.get('AI_ENGINE_URL')
    tenant_id = os.environ.get('TENANT_ID', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d')
    
    if not ai_engine_url:
        print("ERROR: AI_ENGINE_URL environment variable is not set!")
        return {
            "statusCode": 500,
            "body": "AI_ENGINE_URL is not set"
        }
        
    for record in event.get('Records', []):
        body_str = record.get('body', '{}')
        print(f"Raw SQS message body: {body_str}")
        try:
            sqs_payload = json.loads(body_str)
            correlation_id = sqs_payload.get('correlation_id', 'unknown')
            anomaly = sqs_payload.get('anomaly', {})
            anomaly_id = anomaly.get("anomaly_id", "unknown")
            
            print(f"[correlation_id={correlation_id}] Processing anomaly {anomaly_id}")
            
            # Construct Decide Request Body according to the API contract
            # To avoid key collision when processing multiple anomalies or rerunning detection,
            # we generate a deterministic UUIDv5 using correlation_id and anomaly_id.
            try:
                corr_uuid = uuid.UUID(correlation_id)
            except ValueError:
                # Fallback to tenant_id or NAMESPACE_DNS if correlation_id is not a valid UUID format
                try:
                    corr_uuid = uuid.UUID(tenant_id)
                except ValueError:
                    corr_uuid = uuid.NAMESPACE_DNS
                
            idempotency_uuid = str(uuid.uuid5(corr_uuid, anomaly_id))
            billing_date = datetime.utcnow().strftime('%Y-%m-%d')
            idempotency_key = f"{idempotency_uuid}:{billing_date}:decide"
            
            req_body = {
                "correlation_id": correlation_id,
                "idempotency_key": idempotency_key,
                "dry_run_mode": False,
                "anomaly_context": {
                    "anomaly_id": anomaly_id,
                    "anomaly_type": anomaly.get("anomaly_type"),
                    "resource_id": anomaly.get("resource_id"),
                    "environment": anomaly.get("environment"),
                    "unblended_cost_24h_usd": anomaly.get("unblended_cost_24h_usd"),
                    "cost_ratio_to_7d_avg": anomaly.get("cost_ratio_to_7d_avg"),
                    "responsible_team": anomaly.get("responsible_team") or "unknown",
                    "cost_center_code": anomaly.get("cost_center_code") or None
                }
            }
            
            req_body_str = json.dumps(req_body)
            req_body_hash = hashlib.sha256(req_body_str.encode('utf-8')).hexdigest()
            req_timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
            
            headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-Tenant-Id': tenant_id,
                'X-Idempotency-Key': idempotency_key,
                'X-Payload-SHA256': req_body_hash,
                'X-Request-Timestamp': req_timestamp,
                'X-Dry-Run-Mode': 'false',
                'X-Correlation-Id': correlation_id
            }
            
            # Sign request using AWS SigV4
            headers = sign_request(ai_engine_url, 'POST', headers, req_body_str)
            
            print(f"Calling AI Engine Decider URL: {ai_engine_url}")
            print(f"Payload sent: {req_body_str}")
            
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
                    
                    print("\n=== [AI Engine Decide Response] ===")
                    print(json.dumps(response_data, indent=2))
                    print("===================================\n")
                    
                    # Extract Slack routing configuration
                    eng_data = response_data.get("engineering_dashboard_data", {})
                    slack_routing = eng_data.get("slack_routing", {})
                    channel_name = slack_routing.get("channel_name")
                    webhook_pointer = slack_routing.get("webhook_url_pointer")
                    
                    # Map the webhook pointer to one of our two team parameters:
                    # /finops-watch/finance/slack-webhook or /finops-watch/engineer/slack-webhook
                    ssm_param_name = "/finops-watch/engineer/slack-webhook"  # Default fallback
                    if webhook_pointer:
                        ptr = webhook_pointer[4:] if webhook_pointer.startswith("ssm:") else webhook_pointer
                        if "prod" in ptr or "finance" in ptr:
                            ssm_param_name = "/finops-watch/finance/slack-webhook"
                            channel_name = "#finops-alert-finance"
                        else:
                            ssm_param_name = "/finops-watch/engineer/slack-webhook"
                            channel_name = "#finops-alert-engineering"
                            
                    print(f"Retrieving Slack Webhook URL from Parameter Store: {ssm_param_name}")
                    
                    # Query SSM
                    webhook_url = None
                    try:
                        ssm_client = boto3.client('ssm', region_name='ap-southeast-1')
                        ssm_response = ssm_client.get_parameter(
                            Name=ssm_param_name,
                            WithDecryption=True
                        )
                        webhook_url = ssm_response.get('Parameter', {}).get('Value')
                        print("Slack Webhook URL retrieved successfully from SSM.")
                    except Exception as ssm_err:
                        print(f"Warning: Failed to retrieve SSM parameter {ssm_param_name}: {ssm_err}")
                            
                        # Fallback for testing/demonstration if parameter is missing
                        if not webhook_url:
                            webhook_url = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
                            print(f"Using fallback mock Slack Webhook: {webhook_url}")
                            
                        # Build a rich Slack alert message using blocks
                        rca = eng_data.get("root_cause_analysis", {})
                        
                        slack_message = {
                            "channel": channel_name,
                            "text": f"🚨 *FinOps Watch Alert* - Anomaly Detected: {anomaly_id}",
                            "blocks": [
                                {
                                    "type": "header",
                                    "text": {
                                        "type": "plain_text",
                                        "text": "🚨 FinOps Anomaly Alert",
                                        "emoji": True
                                    }
                                },
                                {
                                    "type": "section",
                                    "fields": [
                                        {"type": "mrkdwn", "text": f"*Anomaly ID:*\n`{anomaly_id}`"},
                                        {"type": "mrkdwn", "text": f"*Resource ID:*\n`{anomaly.get('resource_id')}`"},
                                        {"type": "mrkdwn", "text": f"*Severity:*\n`{anomaly.get('severity')}`"},
                                        {"type": "mrkdwn", "text": f"*Environment:*\n`{anomaly.get('environment')}`"},
                                        {"type": "mrkdwn", "text": f"*Responsible Team:*\n`{anomaly.get('responsible_team')}`"},
                                        {"type": "mrkdwn", "text": f"*24h Cost (USD):*\n`${anomaly.get('unblended_cost_24h_usd')}`"},
                                        {"type": "mrkdwn", "text": f"*Cost Ratio to 7d Avg:*\n`{anomaly.get('cost_ratio_to_7d_avg')}x`"},
                                        {"type": "mrkdwn", "text": f"*Correlation ID:*\n`{correlation_id}`"}
                                    ]
                                },
                                {
                                    "type": "section",
                                    "text": {
                                        "type": "mrkdwn",
                                        "text": f"*Technical Reason / RCA:*\n{rca.get('technical_reason', 'N/A')}"
                                    }
                                }
                            ]
                        }
                        
                        # Add missing tags if any
                        missing_tags = rca.get("missing_mandatory_tags", [])
                        if missing_tags:
                            slack_message["blocks"].append({
                                "type": "section",
                                "text": {
                                    "type": "mrkdwn",
                                    "text": f"⚠️ *Missing Mandatory Tags:* `{', '.join(missing_tags)}`"
                                }
                            })
                            
                        # Add containment action plan details
                        applied_payload = response_data.get("applied_payload", {})
                        action_type = applied_payload.get("action_type")
                        cli_command = applied_payload.get("aws_cli_command")
                        
                        if action_type and cli_command:
                            slack_message["blocks"].append({
                                "type": "section",
                                "text": {
                                    "type": "mrkdwn",
                                    "text": f"⚙️ *Containment Action:* `{action_type}`\n`{cli_command}`"
                                }
                            })
                            
                        print(f"Sending Slack alert to channel {channel_name}...")
                        slack_payload_str = json.dumps(slack_message)
                        
                        # POST to Slack Webhook URL
                        slack_req = urllib.request.Request(
                            webhook_url,
                            data=slack_payload_str.encode('utf-8'),
                            headers={'Content-Type': 'application/json'},
                            method='POST'
                        )
                        
                        try:
                            with urllib.request.urlopen(slack_req, timeout=5) as slack_res:
                                slack_res_body = slack_res.read().decode('utf-8')
                                print(f"Slack webhook response: {slack_res_body}")
                        except urllib.error.HTTPError as slack_http_err:
                            print(f"Warning: Slack webhook returned HTTP error {slack_http_err.code}: {slack_http_err.read().decode('utf-8')}")
                        except Exception as slack_err:
                            print(f"Warning: Failed to connect to Slack webhook: {slack_err}")
                            
            except urllib.error.HTTPError as e:
                err_body = e.read().decode('utf-8')
                print(f"HTTP Error {e.code} calling AI /decide: {err_body}")
            except Exception as e:
                print(f"Connection Error calling AI /decide: {e}")
                
        except json.JSONDecodeError as e:
            print(f"Failed to parse SQS message body: {e}")
            
    return {
        "statusCode": 200,
        "body": "Lambda Decision Handler executed successfully!"
    }

