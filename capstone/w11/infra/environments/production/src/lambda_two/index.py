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
            # To avoid key collision when processing multiple anomalies on the same day,
            # we generate a deterministic UUIDv5 using tenant_id and anomaly_id.
            try:
                tenant_uuid = uuid.UUID(tenant_id)
            except ValueError:
                # Fallback to NAMESPACE_DNS if tenant_id is not a valid UUID format
                tenant_uuid = uuid.NAMESPACE_DNS
                
            idempotency_uuid = str(uuid.uuid5(tenant_uuid, anomaly_id))
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

