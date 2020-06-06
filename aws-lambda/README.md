# AWS Lambda with QuantumMaid

This tutorial shows how to deploy your QuantumMaid application to AWS Lambda. You'll need:

- [An AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account) to deploy your AWS Lambda functions to a publicly accessible HTTP endpoint.
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) to run your function locally and deploy your function to your AWS account.

You should be aware that this tutorial may incur costs if you go beyond the usage allowed by the free tier.

## Step 1: Minimal viable function

The simplest function we can deploy says Hello World when you issue a GET request to '/', as described in QuantumMaid's [Getting Started](https://quantummaid.de/docs/01_gettingstarted.html)

### File structure

```bash
$ tree
.
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
        .get("/", (request, response) -> response.setBody("Hello World!"))
        .build();
    final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
        .withHttpMaid(httpMaid)
        .withLocalHostEndpointOnPort(port);
    quantumMaid.runAsynchronously();
  }
}
```

## Step 2: Adding the AWS Lambda capability

### Extracting HttpMaid's initialization

The HttpMaid initialization code will be exactly the same whether we run the code as a local http endpoint or as an AWS Lambda function.

In order for that initialization code to be shared, we first need to extract it to a new method.

```diff
 public final class Main {
   public static void main(String[] args) {
     final int port = 8080;
-    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
-        .get("/", (request, response) -> response.setBody("Hello World!"))
-        .build();
+    final HttpMaid httpMaid = httpMaidConfig();
     final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
         .withHttpMaid(httpMaid)
         .withLocalHostEndpointOnPort(port);
     quantumMaid.runAsynchronously();
   }
+
+  private static HttpMaid httpMaidConfig() {
+    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
+        .get("/", (request, response) -> response.setBody("Hello World!"))
+        .build();
+    return httpMaid;
+  }
 }

```

### Adding the Lambda dependency

Lambda integration is provided through an additional HttpMaid dependency.

```xml
<dependency>
  <groupId>de.quantummaid.httpmaid.integrations</groupId>
  <artifactId>httpmaid-awslambda</artifactId>
  <version>0.9.61</version>
</dependency>
```

### Adding the Lambda endpoint adapter

Once the httpmaid-lambda dependency is added, a new class is now available to bridge the HttpMaid world and the AWS Lambda World: `AwsLambdaEndpoint`.

We can initialize it in a static field of the Main class, so that the initialization time of HttpMaid does not count towards the execution time of the lambda function. Also, you only want to initialize HttpMaid once per VM lifetime.

```diff
+import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;
 import de.quantummaid.quantummaid.QuantumMaid;

+import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;
+
 public final class Main {
+  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(httpMaidConfig());
+
```

### Implementing the RequestHandler interface

The AWS Lambda Java runtime expects the entrypoint method to have [one of two possible signatures](https://docs.aws.amazon.com/lambda/latest/dg/java-handler.html#java-handler-interfaces):

- An I/O stream based RequestStreamHandler interface (not supported by HttpMaid)
- A generic RequestHandler interface where input (request) and output (response) types must be (de)serializable) by the java runtime. At the time of writing this tutorial, HttpMaid only supports:

  ```java
  public interface RequestHandler<
      APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {
    APIGatewayProxyResponseEvent handleRequest(
        APIGatewayProxyRequestEvent event, Context context);
  }
  ```

The method implementation should forward all calls to the adapter.

```diff
-public final class Main {
+public final class Main implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {
   private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(httpMaidConfig());

+  @Override
+  public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent request, Context ctx) {
+    return ADAPTER.delegate(request, ctx);
+  }
+
```

## Step 3: Running the AWS Lambda function locally

Before we're in a position to deploy the function to AWS Lambda, there are a few preliminary steps we need to go through.

### Running the function using SAM Local

It's easy to get lost in the details of java function packaging for local and remote deployment, as the landscape is constantly changing.

In order to cut down on the discovery time for best practices, we'll leverage the templates created by SAM CLI's `sam init` command.

```shell
$ sam init --name tmp --runtime java11 --dependency-manager maven --app-template hello-world ➊

Cloning app templates from https://github.com/awslabs/aws-sam-cli-app-templates.git
$ tree tmp
tmp/
├── events
│   └── event.json
├── HelloWorldFunction
│   ├── pom.xml
│   └── src
│       ├── main
│       │   └── java
│       │       └── helloworld
│       │           ├── App.java
│       │           └── GatewayResponse.java
│       └── test
│           └── java
│               └── helloworld
│                   └── AppTest.java
├── README.md
└── template.yaml ➋
```

➊ Since we'll only use the generated project for reference, the project name (`--name tmp`) does **NOT** matter.

➋ We'll need this, in order to run and deploy the function locally.

The other important fragment is in the generated template.yml (➌):

```yml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
...
Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: HelloWorldFunction
      Handler: helloworld.App::handleRequest
      Runtime: java11
      MemorySize: 512
      ...
      Events:
        HelloWorld:
          Type: Api
          Properties:
            Path: /hello
            Method: get
```

We need to make a couple modifications to the template.yml before SAM CLI can work with our function.

- First create a template.yml file in the same directory as _our_ pom.xml.
- Copy and paste the yml fragment above (without the `...` lines!) into the newly created `template.yml`, and make the following modifications:

  ```diff
  -      CodeUri: HelloWorldFunction
  -      Handler: helloworld.App::handleRequest
  +      CodeUri: . # ➍
  +      Handler: de.quantummaid.tutorials.Main::handleRequest # ➎
  ```

➍ Indicates to sam cli that the pom.xml is in the same directory as template.yml, not in a HelloWorldFunction subdirectory.

➎ Needs to point to our fully qualified class name and handler method.

We are finally able to try our function locally!

```
$ sam build
Building resource 'HelloWorldFunction'
Running JavaMavenWorkflow:CopySource
Running JavaMavenWorkflow:MavenBuild
Running JavaMavenWorkflow:MavenCopyDependency
Running JavaMavenWorkflow:MavenCopyArtifacts

Build Succeeded

Built Artifacts  : .aws-sam/build
Built Template   : .aws-sam/build/template.yaml

Commands you can use next
=========================
[*] Invoke Function: sam local invoke
[*] Deploy: sam deploy --guided
$ sam local invoke
$ sam local invoke
Invoking de.quantummaid.tutorials.Main::handleRequest (java11)

Fetching lambci/lambda:java11 Docker container image......
Mounting /home/lestephane/GitRepos/quantummaid-tutorials/aws-lambda/step3/.aws-sam/build/HelloWorldFunction as /var/task:ro,delegated inside runtime container
START RequestId: 94dc6c61-db46-10e3-a3a9-8c84352e2ed0 Version: $LATEST
09:29:53.293 [main] ERROR de.quantummaid.httpmaid.HttpMaid - Exception in endpoint request handling
java.lang.NullPointerException: null
	at de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.lambda$delegate$0(AwsLambdaEndpoint.java:59)
	at de.quantummaid.httpmaid.HttpMaid.handleRequest(HttpMaid.java:77)
	at de.quantummaid.httpmaid.HttpMaid.handleRequestSynchronously(HttpMaid.java:66)
	at de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.delegate(AwsLambdaEndpoint.java:54)
	at de.quantummaid.tutorials.Main.handleRequest(Main.java:18)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
	at java.base/java.lang.reflect.Method.invoke(Unknown Source)
	at lambdainternal.EventHandlerLoader$PojoMethodRequestHandler.handleRequest(EventHandlerLoader.java:280)
	at lambdainternal.EventHandlerLoader$PojoHandlerAsStreamHandler.handleRequest(EventHandlerLoader.java:197)
	at lambdainternal.EventHandlerLoader$2.call(EventHandlerLoader.java:897)
	at lambdainternal.AWSLambda.startRuntime(AWSLambda.java:228)
	at lambdainternal.AWSLambda.startRuntime(AWSLambda.java:162)
	at lambdainternal.AWSLambda.main(AWSLambda.java:157)
object must not be null: de.quantummaid.httpmaid.util.CustomTypeValidationException
de.quantummaid.httpmaid.util.CustomTypeValidationException: object must not be null
	at de.quantummaid.httpmaid.util.CustomTypeValidationException.customTypeValidationException(CustomTypeValidationException.java:32)
	at de.quantummaid.httpmaid.util.Validators.validateNotNull(Validators.java:33)
	at de.quantummaid.httpmaid.endpoint.SynchronizationWrapper.getObject(SynchronizationWrapper.java:42)
	at de.quantummaid.httpmaid.HttpMaid.handleRequestSynchronously(HttpMaid.java:70)
	at de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.delegate(AwsLambdaEndpoint.java:54)
	at de.quantummaid.tutorials.Main.handleRequest(Main.java:18)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
	at java.base/java.lang.reflect.Method.invoke(Unknown Source)

END RequestId: 94dc6c61-db46-10e3-a3a9-8c84352e2ed0
REPORT RequestId: 94dc6c61-db46-10e3-a3a9-8c84352e2ed0	Init Duration: 1297.73 ms	Duration: 50.08 ms	Billed Duration: 100 ms	Memory Size: 512 MB	Max Memory Used: 85 MB

{"errorType":"de.quantummaid.httpmaid.util.CustomTypeValidationException","errorMessage":"object must not be null","stackTrace":["de.quantummaid.httpmaid.util.CustomTypeValidationException.customTypeValidationException(CustomTypeValidationException.java:32)","de.quantummaid.httpmaid.util.Validators.validateNotNull(Validators.java:33)","de.quantummaid.httpmaid.endpoint.SynchronizationWrapper.getObject(SynchronizationWrapper.java:42)","de.quantummaid.httpmaid.HttpMaid.handleRequestSynchronously(HttpMaid.java:70)","de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.delegate(AwsLambdaEndpoint.java:54)","de.quantummaid.tutorials.Main.handleRequest(Main.java:18)","java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)","java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)","java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)","java.base/java.lang.reflect.Method.invoke(Unknown Source)"]}
```


---

This site is under construction. Contributions are greatly appreciated.

<img src="../construction.png" align="right"/>
