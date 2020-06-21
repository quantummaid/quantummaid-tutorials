# Step 1: Minimal viable function

(Full source code: [step1 directory](step1))

The simplest function we can deploy says Hello World when you issue a GET request to '/helloworld', similar to what is described in QuantumMaid's [Getting Started](https://quantummaid.de/docs/01_gettingstarted.html) page.

## File structure

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

## pom.xml

<!---[CodeSnippet](file=step1/pom.xml)-->
```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>de.quantummaid.tutorials.aws-lambda</groupId>
    <artifactId>aws-lambda-step1</artifactId>
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

## Main.java

<!---[CodeSnippet](file=step1/src/main/java/de/quantummaid/tutorials/Main.java)-->
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

## Running locally

As it stands, the minimum viable function can run as a local http server endpoint:

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
