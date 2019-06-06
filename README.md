# URL Poller

This is a serverless application that will poll URLs for stability.

This application consists of a Dynamodb table two Lambda functions and Cloudwatch Events rules to tie them together.  The application also creates the IAM roles needed for everything to work properly.

The DynamoDB Table created contains urls that you want to poll. The records are formated as below...

```json
{
  "hostname": "amazon.com",
  "path": "/",
  "protocol": "https",
  "URLid": "2345sdf23"
}
```
The URLid is just a hash for the partition key and then the fields are created in 3 sections for flexibility.

There is a cloudwatch event created that by default, runs once every minute.  This event kicks off the pullURLs function that scans the dynamodb table and creates a cloudwatch event for each url.

The second cloudwatch event rule, are triggered when these first events are generated.  These rules pass the url to the pollURL function to use the request python function to poll the url. The interesting responses are then sent to cloudwatch as custom metrics for monitoring.  Currently I'm only sending two metrics per url.

+ latency of the response
+ status code count

# Deployment

In the folder that you want to download the instanceScheduler folder and files to run the following command.
~~~~
git clone https://github.com/bailessm/urlPoller.git
cd urlPoller
bash deploy.sh
~~~~

You can pass the following variables if you would like to modify the defaults to deploy.sh. All named variables are optional and must be passed as --"variable name"="variable value"

~~~~
  --stackName=
  --region=
  --defaultProfile=

  #example...
  bash deploy.sh --stackName=instanceScheduler-West --region=us-west-2 --defaultProfile=admin
~~~~

