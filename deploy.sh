#! /bin/bash
stackName="PollerStack"

#If you use another cli profile for elevated priviledges uncomment the
#followind line and modify it with your profile name.  Also uncomment the
#last line in this file to change back to the default profile after the 
#script completes.

#export AWS_DEFAULT_PROFILE=admin

region='us-east-1'
pullFunction="pullURLs.zip"
pollFunction="pollURL.zip"

##Create a bucket to hold lambda function code
aws cloudformation create-stack --stack-name $stackName-Bucket --template-body file://codeBucket.yaml --region $region

##Wait for the bucket to be created
aws cloudformation wait stack-create-complete --stack-name $stackName-Bucket --region $region

##pull the s3Bucket Output from the bucket
s3BucketArn=$(aws cloudformation describe-stacks --stack-name $stackName-Bucket \
    --query 'Stacks[0].Outputs[?OutputKey==`s3Bucket`].OutputValue[]' --region $region)

##Pull the S3 bucket name from the ARN
s3BucketArn="${s3BucketArn//[}"
s3BucketArn="${s3BucketArn//]}"
s3BucketArn=${s3BucketArn//$'\n'/}
s3BucketArn=${s3BucketArn//$'"'/}
s3BucketArn=${s3BucketArn//$' '/}
bucketName=${s3BucketArn//$'arn:aws:s3:::'/}

##upload the lambda code to the code bucket
aws s3 cp pollURL s3://$bucketName/ --recursive --exclude "*" --include "*.zip"
aws s3 cp pullURLs s3://$bucketName/ --recursive --exclude "*" --include "*.zip"

##Create URL Poller stack
aws cloudformation create-stack --stack-name $stackName \
    --template-body file://cfTemplate.yaml \
    --parameters ParameterKey=codeBucket,ParameterValue=$bucketName ParameterKey=pollerFunctionCode,ParameterValue=$pollFunction ParameterKey=pullerFunctionCode,ParameterValue=$pullFunction \
    --capabilities CAPABILITY_IAM --region $region

#Wait for the stack to be created
echo "Please wait for the stack to be created..."
aws cloudformation wait stack-create-complete --stack-name $stackName --region $region
echo "The stack application is ready, loading test URLs..."

##Pull the DynamoDBTable Output from the Stack
dbTableArn=$(aws cloudformation describe-stacks --stack-name $stackName \
    --query 'Stacks[0].Outputs[?OutputKey==`DynamoDBTable`].OutputValue[]' --region $region)

##Pull the DDBTable from the ARN
dbTableArn="${dbTableArn//[}"
dbTableArn="${dbTableArn//]}"
dbTableArn=$(tr '/' ';' <<<$dbTableArn)
dbTable="$(echo $dbTableArn | cut -d';' -f2)"
dbTable=${dbTable//$'\n'/}
dbTable=${dbTable//$'"'/}

##Create two test records for the poller
aws dynamodb put-item --table-name $dbTable --item '{"URLid": {"S": "9834u5jlk"},"protocol": {"S": "http"},"hostname": {"S": "cnn.com"},"path": {"S": "/"}}' --region $region
aws dynamodb put-item --table-name $dbTable --item '{"URLid": {"S": "2345sdf23"},"protocol": {"S": "https"},"hostname": {"S": "amazon.com"},"path": {"S": "/"}}' --region $region

#Uncomment the following line if you had to change the default profile for this script

#unset AWS_DEFAULT_PROFILE