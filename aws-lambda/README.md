# AWS Lambda with QuantumMaid

This tutorial shows how to deploy your QuantumMaid application to AWS Lambda.

You'll need [An AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account) to be able to complete this tutorial. You should be aware that this may incur costs if you go beyond the usage allowed by the free tier.

## Step 1: Creating a minimal viable function

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


This site is under construction. Contributions are greatly appreciated.

<img src="../construction.png" align="right"/>
