def handler(event, context):
    print("Hello from Private Subnet Lambda")
    return {
        'statusCode': 200,
        'body': 'Hello from Private Subnet Lambda'
    }
