def handler(event, context):
    print("Lambda Decision Handler invoked via SQS!")
    print(f"Received event: {event}")
    for record in event.get('Records', []):
        body = record.get('body')
        print(f"Processing SQS message body: {body}")
    return {
        "statusCode": 200,
        "body": "Lambda Decision Handler executed successfully!"
     }
