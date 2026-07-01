import json

def handler(event, context):
    print("Lambda Decision Handler invoked via SQS!")
    for record in event.get('Records', []):
        body_str = record.get('body', '{}')
        print(f"Raw SQS message body: {body_str}")
        try:
            body = json.loads(body_str)
            correlation_id = body.get('correlation_id', 'unknown')
            anomaly = body.get('anomaly', {})
            print(f"[correlation_id={correlation_id}] Anomaly received:")
            print(f"  anomaly_id      : {anomaly.get('anomaly_id')}")
            print(f"  anomaly_type    : {anomaly.get('anomaly_type')}")
            print(f"  severity        : {anomaly.get('severity')}")
            print(f"  resource_id     : {anomaly.get('resource_id')}")
            print(f"  environment     : {anomaly.get('environment')}")
            print(f"  responsible_team: {anomaly.get('responsible_team')}")
            print(f"  cost_24h_usd    : {anomaly.get('unblended_cost_24h_usd')}")
            print(f"  cost_ratio_7d   : {anomaly.get('cost_ratio_to_7d_avg')}")
            print(f"  confidence      : {anomaly.get('confidence_score')}")
        except json.JSONDecodeError as e:
            print(f"Failed to parse SQS message body: {e}")
    return {
        "statusCode": 200,
        "body": "Lambda Decision Handler executed successfully!"
    }

