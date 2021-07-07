# Step 1 - First failing test(s)

## Initial pom.xml

The `pom.xml` we'll start from is

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>todomaid</groupId>
  <artifactId>todomaid-api</artifactId>
  <version>1.0.0</version>

  <properties>
    <java.version>11</java.version>
    <maven.compiler.parameters>true<!--⓵--></maven.compiler.parameters>
    <maven.compiler.target>${java.version}</maven.compiler.target>
    <maven.compiler.source>${java.version}</maven.compiler.source>
    <quantummaid.version>1.0.48</quantummaid.version>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>de.quantummaid.quantummaid</groupId>
        <artifactId>quantummaid-bom<!--⓶--></artifactId>
        <version>${quantummaid.version}</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <dependencies>
    <dependency>
      <groupId>de.quantummaid.quantummaid.packagings</groupId>
      <artifactId>quantummaid-essentials<!--⓷--></artifactId>
    </dependency>
  </dependencies>
</project>
```

- ⓵ QuantumMaid requires reflection metadata for method parameters (ie the compiler `-parameters` command-line argument). This enables it.

- ⓶ In order to ensure that the various quantummaid libraries work together, we import their versions from the `quantummaid-bom` dependency, which tracks the latest good known versions.

- ⓷ Grouping of dependencies that enables serving use case classes without having to hunt down artifact IDs.

---

## Initial main class

We need a main class that will serve as the entrypoint for QuantumMaid.
It must be located where maven expects production classes (src/main).

```bash
$ tree src/main
src/main
└── java
    └── todomaid
        └── api
            └── Server.java
```

An initial version of the Server class will dump all requests to System.err:

```java
package todomaid.api;
...
public final class Server {
  public static void main(String[] args) {
    serverInstance(8080).run();
  }

  @NotNull
  private static QuantumMaid serverInstance(int port) {
    QuantumMaid quantumMaid = quantumMaid()
        .withHttpMaid(anHttpMaid()
            .get("/*", dumpRequest())
            //.options("/*", dumpRequest())   ⓵
            //.patch("/*", dumpRequest())     ⓶
            .post("/*", dumpRequest())
            .put("/*", dumpRequest())
            .delete("/*", dumpRequest()).build())
        .withLocalHostEndpointOnPort(port);
    return quantumMaid;
  }

  private static HttpHandler dumpRequest() {
    return (req, res) ->
      System.err.printf("%s %s %n", req.method(), req.path());
  }
}
```

⓵ ⓶ [Additional support](https://github.com/quantummaid/httpmaid/issues/80) is needed to catch these request methods. An any() routing method will further reduce the method size.

---

## First start

Starting the server is a rather involved maven command, and I never remember how to do it, so here it is:

```shell
(in terminal 1)
$ mvn exec:java -Dexec.mainClass="todomaid.api.Server"
...
21:28:41.373 [todomaid.api.Server.main()] INFO de.quantummaid.quantummaid.QuantumMaid -
   ____                    _                   __  __       _     _
  / __ \                  | |                 |  \/  |     (_)   | |
 | |  | |_   _  __ _ _ __ | |_ _   _ _ __ ___ | \  / | __ _ _  __| |
 | |  | | | | |/ _` | '_ \| __| | | | '_ ` _ \| |\/| |/ _` | |/ _` |
 | |__| | |_| | (_| | | | | |_| |_| | | | | | | |  | | (_| | | (_| |
  \___\_\\__,_|\__,_|_| |_|\__|\__,_|_| |_| |_|_|  |_|\__,_|_|\__,_|

21:28:41.374 [todomaid.api.Server.main()] INFO de.quantummaid.quantummaid.QuantumMaid - Startup took: 341ms (317ms initialization, 24ms endpoint startup)
21:28:41.376 [todomaid.api.Server.main()] INFO de.quantummaid.quantummaid.QuantumMaid - Serving http://localhost:8080/
21:28:41.376 [todomaid.api.Server.main()] INFO de.quantummaid.quantummaid.QuantumMaid - Ready.
```

Run a curl command from another terminal to verify that the server is receiving requests

```shell
(in terminal 2)
$ curl localhost:8080
```

As expected, the server dumps the request to System.err

```shell
(in terminal 1)
HttpRequestMethod(value=GET) Path(path=/)
```

Let's see the extent of the endpoints we need to support by running the todobackend test suite:

```bash
$ cd /tmp
$ git clone https://github.com/TodoBackend/todo-backend-js-spec.git
$ cd todo-backend-js-spec
$ firefox index.html
(enter http://localhost:8080)
```

The server output STDERR output is rather verbose with internal server errors caused by unmapped OPTIONS request. This is tracked under issue https://github.com/quantummaid/httpmaid/issues/81

## To be continued...
