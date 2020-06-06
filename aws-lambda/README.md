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

The signature

Handler

The convention with AWS Lambda is to add a `Handler` class that contains a method whose signature is expected by the AWS Lambda Runtime.

As it currently stands, we can run the function as a local http server, which greatly helps with local debugging. We want to maintain that ability. So let's split the HttpMaid

---

This site is under construction. Contributions are greatly appreciated.

<img src="../construction.png" align="right"/>
