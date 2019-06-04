import boto3

dynamodb = boto3.resource('dynamodb')
client = boto3.client('events')

def lambda_handler(event, context):
    ddbARN = event['dynamoTable']
    ddbTable = ddbARN.split(':')[5].split('/')[1]
    urlTable = dynamodb.Table(ddbTable)
    urls = urlTable.scan()
    
    for u in urls['Items']:
        url = '://'.join([u['protocol'],u['hostname']])
        url = ''.join([url,u['path']])
        response = client.put_events(
            Entries=[
                {
                    'Source': event["pollerSource"],
                    'DetailType': 'URL to be polled',
                    'Detail': ''.join(['{"URL":"',url,'","Namespace":"',event["pollerSource"],'"}'])
                },
            ]
        )
        print(response)
#End of Loop