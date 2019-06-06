#! /bin/bash
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            --stackName)    stackName=${VALUE} ;;
            --region)   region=${VALUE} ;;
            --defaultProfile) defaultProfile=${VALUE} ;;  
            *)   
    esac    

done

stackName=${stackName:-'instanceScheduler'}
region=${region:-'us-east-1'}


if [ ! -z $defaultProfile ] 
then 
    export AWS_DEFAULT_PROFILE=$defaultProfile
fi

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
aws s3 cp . s3://$bucketName/ --recursive --exclude "*" --include "*.zip"

##Create URL Poller stack
aws cloudformation create-stack --stack-name $stackName \
    --template-body file://cfTemplate.yaml \
    --parameters ParameterKey=codeBucket,ParameterValue=$bucketName \
    --capabilities CAPABILITY_IAM --region $region

#Wait for the stack to be created
echo "Please wait for the stack to be created..."
aws cloudformation wait stack-create-complete --stack-name $stackName --region $region
echo "The stack application is ready, loading test URLs..."

lambdaArn=$(aws cloudformation describe-stacks --stack-name $stackName \
    --query 'Stacks[0].Outputs[?OutputKey==`testRecordsFunction`].OutputValue[]' --region $region)

lambdaArn="${lambdaArn//[}"
lambdaArn="${lambdaArn//]}"
lambdaArn=${lambdaArn//'"'}

aws lambda invoke --function-name $lambdaArn --region $region outputfile.txt
rm outputfile.txt

if [ ! -z $defaultProfile ] 
then 
    unset AWS_DEFAULT_PROFILE
fi