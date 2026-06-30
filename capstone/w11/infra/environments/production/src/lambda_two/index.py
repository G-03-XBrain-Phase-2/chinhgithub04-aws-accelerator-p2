def handler(event, context):
    print("Hello from Lambda Two in Production Private Subnet!")
    return {
        "statusCode": 200,
        "body": "Hello from Lambda Two!"
    }
