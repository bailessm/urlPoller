import boto3
import os

session = boto3.Session()
dynamodb = session.client('dynamodb')

dynamodbTable = os.environ['dynamodbTable'].split("/")[1]

def lambda_handler(event, context):
    response = dynamodb.put_item(
    TableName=dynamodbTable,
    Item={"URLid": {"S": "9834u5jlk"},"protocol": {"S": "http"},"hostname": {"S": "cnn.com"},"path": {"S": "/"}}
    )
    response = dynamodb.put_item(
    TableName=dynamodbTable,
    Item={"URLid": {"S": "2345sdf23"},"protocol": {"S": "https"},"hostname": {"S": "amazon.com"},"path": {"S": "/"}}
    )