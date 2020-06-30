# Step 2: Adding AWS Lambda support
*(Full source code: [`step2`](step2) directory)*

## Extracting the QuantumMaid initialization code

The QuantumMaid initialization code will be exactly the same whether we run the code as a local HTTP endpoint or as an AWS Lambda function.
To share code between the local mode and the Lambda mode, we extract it to a new method in the `Main` class:

<!---[CodeSnippet](step2HttpMaidConfig)-->
```java
private static QuantumMaid quantumMaidConfig() {
  final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
      .get("/helloworld", (request, response) -> response.setBody("Hello World!"));
  return quantumMaid;
}
```

## Adding the Lambda endpoint adapter

Lambda integration is provided through an additional HttpMaid dependency:

<!---[CodeSnippet](step2HttpMaidDependency)-->
```xml
<dependency>
    <groupId>de.quantummaid.httpmaid.integrations</groupId>
    <artifactId>httpmaid-awslambda</artifactId>
    <version>0.9.75</version>
</dependency>
```

Once the `httpmaid-lambda` dependency is added, a new class is available to bridge the QuantumMaid world and the AWS Lambda world: `AwsLambdaEndpoint`.

We should initialize an instance of `AwsLambdaEndpoint` in a static field of the `Main` class, so that:

- The time taken to initialize QuantumMaid does not count towards the execution time of the Lambda function. In plain English, it will not be billed by AWS.
- The QuantumMaid initialization delay is experienced only once per Lambda instance. For our purpose, a Lambda instance is a Java Virtual Machine (JVM) process, [with some notable differences](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html).

Here are the imports required:

<!---[CodeSnippet](step2AdapterDeclaration1)-->
```java
import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;
import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;
```

And the `AwsLambdaEndpoint` static initialization code:

<!---[CodeSnippet](step2AdapterDeclaration2)-->
```java
public final class Main {
  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(quantumMaidConfig().httpMaid());
  //...
```

## Implementing the request handling method

The request handling method is the method that will be invoked by the AWS Lambda Java runtime, and must forward all calls to the `AwsLambdaEndpoint` adapter we just added.

<!---[CodeSnippet](step2RequestHandlingMethod)-->
```java
public Map<String, Object> handleRequest(final Map<String, Object> request) {
  return ADAPTER.delegate(request);
}
```

While the method's parameter type and return type are fixed (both must be `Map<String, Object>`), the method can be named whatever we like. We will reference this method name in the SAM template (➊).

## Adding the SAM template (template.yml)

Regular CloudFormation templates are rather verbose when deploying AWS Lambda functions, so we will use an AWS Serverless Application Model (SAM) template instead.

<!---[CodeSnippet](file=step3/template.yml)-->
```
AWSTemplateFormatVersion: 2010-09-09
Description: quantummaid tutorials lambda function
Transform: AWS::Serverless-2016-10-31

Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: de.quantummaid.tutorials.Main::handleRequest # ➊
      Runtime: java11
      MemorySize: 256
      Events:
        HelloWorldHttpApi:
          Type: HttpApi     # ➋
          Properties:
            Path: /{proxy+} # ➌
            Method: ANY     # ➍

```

➊ The `Handler` property is _[fully qualified request handler class name]_`::`_[request handler method name]_.

➋ Use `Type: Api` if you want to use REST API instead of HTTP API. We use HTTP API because it's [_faster, lower cost and simpler to use_](https://aws.amazon.com/blogs/compute/building-better-apis-http-apis-now-generally-available/).

➌➍ This means that requests to ➌ any path depth (`/`, `/helloworld`, `/hello/...`), using ➍ any method (`GET`, `HEAD`, `PUT`, `POST`, etc.), will be handled by our HttpMaid function. These parameters are fixed and required for a so-called [Lambda proxy integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html).

Are we there yet? Almost.

## Adding a public zero-argument constructor

The AWS Lambda Java runtime instantiates the request handler class (`Main`) by calling its default constructor,
which must be public and take no arguments:

<!---[CodeSnippet](step2PublicNoArgsConstructor)-->
```java
public Main() {}
```

If you don't, the AWS Lambda Java runtime will fail while looking up the constructor:

```
java.lang.Exception: Class de.quantummaid.tutorials.Main has no public zero-argument constructor
Caused by: java.lang.NoSuchMethodException: de.quantummaid.tutorials.Main.<init>()
```

Next, we are going to deploy our function to AWS Lambda.

<!---[Nav]-->
[&larr;](02_MinimumViableFunction.md)&nbsp;&nbsp;&nbsp;[Overview](README.md)&nbsp;&nbsp;&nbsp;[&rarr;](04_DeployingOurFunction.md)