# Step 3: Deploying to AWS Lambda

(Full source code: [step3 directory](step3))

SAM CLI takes care of building, packaging, uploading, deploying the function for us.

But it does need to ask a few questions the first time you deploy the function.

For this tutorial, we only deviate from the defaults for the Stack Name (`hello-app ➎`) and for the confirmation that it is okay for HelloWorldFunction to not have authorization defined (`Is this okay? [y/N]: y ➏`)

```shell
$ sam build
$ sam deploy --guided

Configuring SAM deploy
======================

	Looking for samconfig.toml :  Not found

	Setting default arguments for 'sam deploy'
	=========================================
	Stack Name [sam-app]: hello-app ➎
	AWS Region [us-east-1]:
	#Shows you resources changes to be deployed and require a 'Y' to initiate deploy
	Confirm changes before deploy [y/N]:
	#SAM needs permission to be able to create roles to connect to the resources in your template
	Allow SAM CLI IAM role creation [Y/n]:
	HelloWorldFunction may not have authorization defined, Is this okay? [y/N]: y ➏
	Save arguments to samconfig.toml [Y/n]:

...
Successfully created/updated stack - hello-app in us-east-1

```

If you get the final `Successfully created/updated stack` message, then the function is now deployed.

Unfortunately, SAM CLI does not show the URL of the HTTP endpoint as part of the `sam deploy` command output. So we need to execute a couple more commands to find that out:

```shell
$ region=us-east-1 # use the same region as in the sam deploy command
$ apiId=$(aws cloudformation describe-stack-resource \
  --stack-name hello-app \
  --logical-resource-id ServerlessHttpApi \
  --query StackResourceDetail.PhysicalResourceId \
  --region "${region}" --output text)
$ apiUrl=$(printf "https://%s.execute-api.%s.amazonaws.com" $apiId $region)
```

Past this point, `apiUrl` contains the api's invocation URL.

Let us now invoke the deployed function through its endpoint URL, to verify that it is working:

```shell
$ echo $(curl -s $apiUrl/helloworld)
Hello World!
```

Congratulations, you've now successfully deployed your first HttpMaid function to AWS!

Next, Let's introduce some dynamic behaviour.
