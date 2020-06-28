# Step 5: Cleaning up

This tutorial may incur costs if you go beyond the usage allowed by the AWS free tier.
Although this is very unlikely, it's not impossible.

After all, your API is publicly accessible on the internet,
and anyone could hit it with millions of requests, forcing you over the free tier limit. It's better to avoid surprises.

When running through the steps in this tutorial we created:

- One cloudformation stack called `hello-app`. This is ours.
- One cloudformation stack called `aws-sam-cli-managed-default`. This is SAM CLI's.

To remove all traces of our tutorial, we must remove both.

## Removing the hello-app stack

You may delete the `hello-app` by running this AWS CLI command:

```shell
$ aws cloudformation delete-stack --stack-name hello-app --region us-east-1
```

## Removing the aws-sam-cli-managed-default stack

SAM CLI uses `aws-sam-cli-managed-default` to manage the S3 bucket for the upload of Java serverless function artifacts.
It is created behind the scene for you. But it will not be cleaned up for us, that's our responsibility.

First we need to delete the S3 bucket ourselves, otherwise deleting the `aws-sam-cli-managed-default` stack will fail, because the bucket is not empty.

```shell
$ region=us-east-1 # use the same region as in the sam deploy command
$ sourceBucket=$(aws cloudformation describe-stack-resource \
    --stack-name aws-sam-cli-managed-default \
    --logical-resource-id SamCliSourceBucket \
    --query StackResourceDetail.PhysicalResourceId \
    --region "${region}" --output text)
$ aws s3 rb --force "s3://${sourceBucket}"
...
remove_bucket failed: s3://aws-sam-cli-managed-default-samclisourcebucket-... An error occurred (BucketNotEmpty)
when calling the DeleteBucket operation: The bucket you tried to delete is not empty.
You must delete all versions in the bucket.
```

Uh, the bucket is versioned, which means that we need to jump through additional hoops to empty it.
A quick google search yields [this solution](https://stackoverflow.com/questions/29809105/how-do-i-delete-a-versioned-bucket-in-aws-s3-using-the-cli#35306665):

```shell
$ python3 -c "
import boto3
s3 = boto3.resource('s3')
bucket = s3.Bucket('${sourceBucket}')
bucket.object_versions.delete()
"
```

Finally, we can delete the SAM CLI stack, now that the bucket is **really** empty:

```shell
$ aws cloudformation delete-stack --stack-name aws-sam-cli-managed-default  --region us-east-1
```

This is the end of this tutorial. The QuantumMaid team hopes you found it useful.

<!---[Nav]-->
[&larr;](05_UpdatingOurFunction.md)&nbsp;&nbsp;&nbsp;[Overview](README.md)
