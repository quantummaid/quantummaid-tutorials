# Step 2: Adding AWS Lambda support

(Full source code: [step2 directory](step2))

## Extracting HttpMaid's initialization code

The HttpMaid initialization code will be exactly the same whether we run the code as a local HTTP endpoint or as an AWS Lambda function.

In order for HttpMaid's initialization code to be shared between the local mode and the Lambda mode, we first need to extract it to a new method in the `Main` class:

<!---[CodeSnippet](step2HttpMaidConfig)-->
```java
private static HttpMaid httpMaidConfig() {
  final HttpMaid httpMaid = HttpMaid.anHttpMaid()
      .get("/helloworld", (request, response) -> response.setBody("Hello World!"))
      .build();
  return httpMaid;
}
```

## Adding the Lambda endpoint adapter

Lambda integration is provided through an additional HttpMaid dependency:

<!---[CodeSnippet](step2HttpMaidDependency)-->
```xml
<dependency>
    <groupId>de.quantummaid.httpmaid.integrations</groupId>
    <artifactId>httpmaid-awslambda</artifactId>
    <version>0.9.67</version>
</dependency>
```

Once the `httpmaid-lambda` dependency is added, a new class is available to bridge the HttpMaid world and the AWS Lambda world: `AwsLambdaEndpoint`.

We should initialize an instance of `AwsLambdaEndpoint` in a static field of the `Main` class, so that:

- The time taken to initialize HttpMaid does not count towards the execution time of the Lambda function.
- The intent to initialize HttpMaid once per VM lifetime is made clear.

<!---[CodeSnippet](step2AdapterDeclaration1)-->
```java
import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;
import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;
```

<!---[CodeSnippet](step2AdapterDeclaration2)-->
```java
public final class Main {
  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(httpMaidConfig());
  //...
```

## Implementing the request handling method

The request handling method is the method that will be invoked by the AWS Lambda Java runtime, and must forward all calls to the `AwsLambdaEndpoint` adapter we just added.

<!---[CodeSnippet](step2RequestHandlingMethod)-->
```java
public Map<String, Object> handleRequest(Map<String, Object> request) {
  return ADAPTER.delegate(request);
}
```

While the method's parameter type and return type are fixed (both must be `Map<String, Object>`), the method can be named whatever we like.
We will reference this method name in the SAM template.

## Adding the SAM template (template.yml)

Regular CloudFormation templates are rather verbose when deploying AWS Lambda functions, so we will use an AWS Serverless Application Model (SAM) template instead.

<!---[CodeSnippet](file=step3/template.yml)-->
```yaml
AWSTemplateFormatVersion: '2010-09-09'
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
          Type: HttpApi     # ➋
          Properties:
            Path: /{proxy+} # ➌
            Method: ANY     # ➍

```

➊ The `Handler` property is _[fully qualified Main class name]_`::`_[request handling method name]_.

➋ Use `Type: Api` if you want to use REST API instead of HTTP API. We use HTTP API because it's [_faster, lower cost and simpler to use_](https://aws.amazon.com/blogs/compute/building-better-apis-http-apis-now-generally-available/).

➌➍ This means that requests to ➌ any path depth (`/`, `/helloworld`, `/hello/...`), using ➍ any method (`GET`, `HEAD`, `PUT`, `POST`, etc.), will be handled by our HttpMaid function. These parameters are fixed and required for a so-called [Lambda proxy integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html).

Next, we are going to deploy our function to AWS Lambda.

<!---[Nav]-->
[&larr;](01_MinimumViableFunction.md)&nbsp;&nbsp;&nbsp;[Overview](README.md)&nbsp;&nbsp;&nbsp;[&rarr;](03_DeployingOurFunction.md)