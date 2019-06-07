#! /bin/bash

### capture input variables
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

##fill in required default variables
stackName=${stackName:-'PollerStack'}
region=${region:-'us-east-1'}

###set the default profile to be used connecting to aws if you passed one.
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
    --query 'Stacks[0].Outputs[?OutputKey==`s3Bucket`].OutputValue[]' --region $region --output text)

##Pull the S3 bucket name from the ARN
bucketName=${s3BucketArn//$'arn:aws:s3:::'/}

##zip and upload the lambda code to the code bucket
for i in $(find . -name '*py')
do  
    file=$(echo $i | cut -d'/' -f3)
    echo $file
    zipFile=${file//$'.py'/}
    echo $zipFile
    echo $i
    zip $zipFile-latest.zip $i -j
done

aws s3 cp . s3://$bucketName/ --recursive --exclude "*" --include "*-latest.zip"

find . -name '*-latest.zip' | xargs rm

##Create URL Poller stack
aws cloudformation create-stack --stack-name $stackName \
    --template-body file://cfTemplate.yaml \
    --parameters ParameterKey=codeBucket,ParameterValue=$bucketName \
    --capabilities CAPABILITY_IAM --region $region

#Wait for the stack to be created
echo "Please wait for the stack to be created..."
aws cloudformation wait stack-create-complete --stack-name $stackName --region $region

echo "The stack application is ready, loading test URLs..."

#get the arn for the lambda function to inupt test records
lambdaArn=$(aws cloudformation describe-stacks --stack-name $stackName \
    --query 'Stacks[0].Outputs[?OutputKey==`testRecordsFunction`].OutputValue[]' --region $region \
    --output text)

#invoke function to input test records.
aws lambda invoke --function-name $lambdaArn --region $region outputfile.txt
rm outputfile.txt

## revert to the original default profile if you changed it for this script
if [ ! -z $defaultProfile ] 
then 
    unset AWS_DEFAULT_PROFILE
fi