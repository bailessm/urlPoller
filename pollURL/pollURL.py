import boto3
from botocore.vendored import requests

cw = boto3.client('cloudwatch')

def poll(url, namespace):
    r = requests.get(url)
    rStatusCode = r.status_code
    rLatency = r.elapsed.total_seconds()
    print('-'.join([url,str(rStatusCode),str(rLatency)]))
    cw.put_metric_data(
        Namespace= namespace,
        MetricData=[
            {
                'MetricName': 'latency',
                'Dimensions': [
                    {
                        'Name': 'website',
                        'Value': url
                    }
                ],
                'Value': rLatency,
                'Unit': 'Seconds'
            },
            {
                'MetricName': '_'.join([str(rStatusCode),'status','code']),
                'Dimensions': [
                    {
                        'Name': 'website',
                        'Value': url
                    }
                ],
                'Value': 1,
                'Unit': 'Count'
            }
            ]
        )
        
def lambda_handler(event, context):
    print(event)
    
    try:
        poll(event["URL"], event["Namespace"])
            
        print('Polled: %s' % (event["URL"]))
    except:
        print('Error Received')