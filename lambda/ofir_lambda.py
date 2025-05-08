import boto3
import json

dynamo = boto3.client('dynamodb')

def lambda_handler(event, context):
    method = event.get("httpMethod")

    # Handle preflight CORS
    if method == "OPTIONS":
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            }
        }

    try:
        if method == "GET":
            response = dynamo.scan(TableName='imtech')
            items = response.get('Items', [])
            return {
                'statusCode': 200,
                'body': json.dumps(items),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                }
            }

        elif method == "POST":
            body = json.loads(event['body'])
            dynamo.put_item(
                TableName='imtech',
                Item={
                    'id': {'S': body['id']},
                    'name': {'S': body['name']},
                    'email': {'S': body['email']}
                }
            )
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Item added'}),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                }
            }

        else:
            return {
                'statusCode': 405,
                'body': json.dumps({'error': 'Method not allowed'}),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                }
            }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
