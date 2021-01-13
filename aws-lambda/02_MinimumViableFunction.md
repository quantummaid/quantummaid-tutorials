# Step 1: Minimal viable function
*(Full source code: [`step1`](step1) directory)*

The simplest function we can deploy says `"Hello World"` when you issue a `GET` request to `/helloworld`, similar to what is described in QuantumMaid's [Getting Started](https://quantummaid.de/docs/01_gettingstarted.html) page.

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

## [`pom.xml`](step1/pom.xml)

The most important `pom.xml` part is

<!---[CodeSnippet](step1PomXml)-->
```xml
    <maven.compiler.parameters>true</maven.compiler.parameters><!-- ➊ -->
</properties>

<dependencies>
    <!--➋-->
    <dependency>
        <groupId>de.quantummaid.quantummaid.packagings</groupId>
        <artifactId>quantummaid-essentials</artifactId>
        <version>1.0.85</version>
    </dependency>
    <!--➋-->
</dependencies>
```

➊ This is required to provide QuantumMaid with method parameter name information through reflection. It's not enabled by default, so this must be explicitly enabled here.

➋ This contains QuantumMaid reasonable defaults for dependencies, including minimal footprint alternatives to Jackson (minimal-json) and Logback (slf4j-simple). Because size matters.

## [`Main.java`](step1/src/main/java/de/quantummaid/tutorials/Main.java)

Our starting point is the proverbial *Hello World* from the [_"Getting Started"_ guide](https://quantummaid.de/docs/01_gettingstarted.html)

<!---[CodeSnippet](step1MainClass)-->
```java
package de.quantummaid.tutorials;

import de.quantummaid.quantummaid.QuantumMaid;

public final class Main {
  public static void main(final String[] args) {
    final int port = 8080;
    final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
        .get("/helloworld", (request, response) -> response.setBody("Hello World!"))
        .withLocalHostEndpointOnPort(port);
    quantumMaid.runAsynchronously();
  }
}
```

## Running locally

The minimum viable function can run as a local HTTP server endpoint:

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

We can convince ourselves that the function is deployed using the `curl` command:

```shell
$ echo $(curl http://localhost:8080/helloworld)
Hello World!
```

Next, we'll add AWS Lambda support to our function.

<!---[Nav]-->
[&larr;](01_TheCaseForLambda.md)&nbsp;&nbsp;&nbsp;[Overview](README.md)&nbsp;&nbsp;&nbsp;[&rarr;](03_AddingLambdaSupport.md)
