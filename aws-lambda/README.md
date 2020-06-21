# AWS Lambda with QuantumMaid

This tutorial shows how to deploy your QuantumMaid application to AWS Lambda.

You'll need:

- A command-line terminal running bash or a bash-compatible shell.
- [An AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account) to deploy your AWS Lambda functions to a publicly accessible HTTP endpoint.
- [AWS Command Line Interface (CLI)](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html).
- AWS credentials with permissions to deploy SAM templates in your AWS account.

You should be aware that this tutorial may incur costs if you go beyond the usage allowed by the AWS free tier.

## Step 1: Minimal viable function

(Full source code: [step1 directory](step1))

The simplest function we can deploy says Hello World when you issue a GET request to '/helloworld', similar to what is described in QuantumMaid's [Getting Started](https://quantummaid.de/docs/01_gettingstarted.html) page.

### File structure

```bash
├── pom.xml
└── src
    └── main
        └── java
            └── de
                └── quantummaid
                    └── tutorials
                        └── Main.java
```

### pom.xml

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>de.quantummaid.tutorials</groupId>
    <artifactId>aws-lambda</artifactId>
    <version>1.0.0</version>
    <properties>
        <java.version>11</java.version>
        <maven.compiler.parameters>true</maven.compiler.parameters>
        <maven.compiler.target>${java.version}</maven.compiler.target>
        <maven.compiler.source>${java.version}</maven.compiler.source>
    </properties>
    <dependencies>
        <dependency>
            <groupId>de.quantummaid.quantummaid.packagings</groupId>
            <artifactId>quantummaid-essentials</artifactId>
            <version>1.0.50</version>
        </dependency>
    </dependencies>
</project>
```

### Main.java

```java
package de.quantummaid.tutorials;

import de.quantummaid.httpmaid.HttpMaid;
import de.quantummaid.quantummaid.QuantumMaid;

public final class Main {
  public static void main(String[] args) {
    final int port = 8080;
    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
        .get("/helloworld", (request, response) -> response.setBody("Hello World!"))
        .build();
    final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
        .withHttpMaid(httpMaid)
        .withLocalHostEndpointOnPort(port);
    quantumMaid.runAsynchronously();
  }
}
```

### Running locally

As it stands, the minimum viable function can run using a local http endpoint:

```shell
$ mvn exec:java -Dexec.mainClass=de.quantummaid.tutorials.Main
...
[Thread-2] INFO de.quantummaid.quantummaid.QuantumMaid -
   ____                    _                   __  __       _     _
  / __ \                  | |                 |  \/  |     (_)   | |
 | |  | |_   _  __ _ _ __ | |_ _   _ _ __ ___ | \  / | __ _ _  __| |
 | |  | | | | |/ _` | '_ \| __| | | | '_ ` _ \| |\/| |/ _` | |/ _` |
 | |__| | |_| | (_| | | | | |_| |_| | | | | | | |  | | (_| | | (_| |
  \___\_\\__,_|\__,_|_| |_|\__|\__,_|_| |_| |_|_|  |_|\__,_|_|\__,_|

[Thread-2] INFO de.quantummaid.quantummaid.QuantumMaid - Startup took: 26ms (1ms initialization, 25ms endpoint startup)
[Thread-2] INFO de.quantummaid.quantummaid.QuantumMaid - Serving http://localhost:8080/
[Thread-2] INFO de.quantummaid.quantummaid.QuantumMaid - Ready.
```

We can convince ourselves that the function is deployed using the curl command:

```shell
$ echo $(curl http://localhost:8080/helloworld)
Hello World!
```

## Step 2: Adding AWS Lambda support

(Full source code: [step2 directory](step2))

### Extracting HttpMaid's initialization code

The HttpMaid initialization code will be exactly the same whether we run the code as a local http endpoint or as an AWS Lambda function.

In order for HttpMaid's initialization code to be shared between the local mode and the lambda mode, we first need to extract it to a new method in the `Main` class:

```java
public final class Main {
  //...
  private static HttpMaid httpMaidConfig() {
    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
        .get("/", (request, response) -> response.setBody("Hello World!"))
        .build();
    return httpMaid;
  }
}
```

### Adding the Lambda endpoint adapter

Lambda integration is provided through an additional HttpMaid dependency:

```xml
<dependency>
  <groupId>de.quantummaid.httpmaid.integrations</groupId>
  <artifactId>httpmaid-awslambda</artifactId>
  <version>0.9.67</version>
</dependency>
```

Once the httpmaid-lambda dependency is added, a new class is available to bridge the HttpMaid world and the AWS Lambda world: `AwsLambdaEndpoint`.

We should initialize an instance of AwsLambdaEndpoint in a static field of the Main class, so that:

- The time taken to initialize HttpMaid does not count towards the execution time of the lambda function.
- The intent to initialize HttpMaid once per VM lifetime is made clear.

```java
import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;
import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;

public final class Main {
  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(httpMaidConfig());
  //...
}
```

### Implementing the request handling method

The request handling method must forward all calls to the `AwsLambdaEndpoint` adapter we just added.

```java
public final class Main {
  //...
  public Map<String, Object> handleRequest(Map<String, Object> request) {
    return ADAPTER.delegate(request);
  }
}
```

While the method's parameter type and return type are fixed (both must be `Map<String, Object>`), the method can be named whatever we like.
Next, we will reference this method name in the SAM template.

### Adding the SAM template (template.yml)

Regular CloudFormation templates are rather verbose when deploying AWS Lambda functions, so we will use an AWS Serverless Application Model (SAM) template instead.

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Transform: AWS::Serverless-2016-10-31
Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: de.quantummaid.tutorials.Main::handleRequest # ➊
      Runtime: java11
      MemorySize: 512
      Events:
        HelloWorldHttpApi:
          Type: HttpApi # ➋
          Properties:
            Path: /{proxy+} # ➌
            Method: ANY # ➍
```

➊ The `Handler` property is _[fully qualified Main class name]_`::`_[request handling method name]_.

➋ Use `Type: Api` if you want to use REST API instead of HTTP API. We use HTTP API because it's [_faster, lower cost and simpler to use_](https://aws.amazon.com/blogs/compute/building-better-apis-http-apis-now-generally-available/).

➌➍ This means that requests to ➌ any path depth (`/`, `/helloworld`, `/hello/...`), using ➍ any method (GET, HEAD, PUT, POST,...), will be handled by our HttpMaid function. These parameters are fixed and required for a so-called [Lambda proxy integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html).

## Step 3: Deploying to AWS Lambda

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

## Step 4: Changing our function

(Full source code: [step4 directory](step4))

A function that returns "Hello World!" is not very useful.
We'll make the returned `Hello message [vary based on the url path](https://quantummaid.de/docs/2_httpmaid/04_handlingrequests.html#request-route-and-path-parameters).

```java
public final class Main {
  //...
  private static HttpMaid httpMaidConfig() {
    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
        .get("/hello/<who>", (request, response) -> response.setBody(
            String.format("Hello, %s!",
                request.pathParameters().getPathParameter("who"))))
        .build();
    return httpMaid;
  }
}
```

To deploy the change, use the same command pair as in step 3.
This time however, we don't need to answer any question, because previous answers are saved to `samconfig.toml`

```shell
$ sam build
$ sam deploy
...
Successfully created/updated stack - hello-app in us-east-1
```

Before we invoke the url, let's tail the logs, which will give us some interesting details on our function execution(s):

```shell
$ sam logs --tail --region us-east-1 --stack-name hello-app --name HelloWorldFunction
```

After invoking the function with the dynamic path part...

```shell
$ time echo $(curl -s $apiUrl/hello/{me,you,everyone})
Hello me!Hello you!Hello everyone!

real	0m2.990s
user	0m0.077s
sys	0m0.005s
```

The logs display something similar to the following simplified output:

```text
... 2020-06-21T09:22:07.659000 START RequestId: ... Version: $LATEST
... 2020-06-21T09:22:07.677000 {version=2.0, routeKey=ANY /{proxy+}, rawPath=/hello/me,...
... 2020-06-21T09:22:08.058000 END RequestId: ...
... 2020-06-21T09:22:08.058000 REPORT RequestId: ...	Duration: 398.08 ms	Billed Duration: 400 ms	Memory Size: 512 MB	Max Memory Used: 101 MB	Init Duration: 870.58 ms
... 2020-06-21T09:22:08.242000 START RequestId: ... Version: $LATEST
... 2020-06-21T09:22:08.246000 {version=2.0, routeKey=ANY /{proxy+}, rawPath=/hello/you,...
... 2020-06-21T09:22:08.248000 END RequestId: ...
... 2020-06-21T09:22:08.248000 REPORT RequestId: ...	Duration: 3.32 ms	Billed Duration: 100 ms	Memory Size: 512 MB	Max Memory Used: 101 MB
... 2020-06-21T09:22:08.442000 START RequestId: ... Version: $LATEST
... 2020-06-21T09:22:08.446000 {version=2.0, routeKey=ANY /{proxy+}, rawPath=/hello/everyone,...
... 2020-06-21T09:22:08.448000 END RequestId: ...
... 2020-06-21T09:22:08.448000 REPORT RequestId: ...	Duration: 3.32 ms	Billed Duration: 100 ms	Memory Size: 512 MB	Max Memory Used: 101 MB
```

Important statistics:

- Time spent in lambda = Init Duration: 870.58 ms + Duration: 398.08 ms + Duration: 3.32 ms + Duration: 3.32 ms = 1275.3ms
- Time spent overall = 2.990s = 2990ms
- Unaccounted time = 2990ms - 1275.3ms = 1714,7ms, of which
  - approx. 600ms is probably due to network latency (100ms each way x 3 requests)
  - approx. 1100ms is as yet unexplained

Having this log output at hand allows us to immediately draw a few conclusions:

- The HttpMaid overhead is flat beyond the first invocation (<5ms)
- The network latency is quite high here (200ms per request). Maybe we can switch to an edge-optimized api.
- If performance is important, 1100ms is still unaccounted for and needs investigation. It could be TLS negotiation, or something else.
- The memory configuration of our function could be lowered from 512mb to something much closer to the memory used (101mb), 128mb for example.

You now have the necessary building blocks to make your HttpMaid code Lambda capable, and to dig deeper into its runtime characteristics in AWS Lambda.
