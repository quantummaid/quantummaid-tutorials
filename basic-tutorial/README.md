# QuantumMaid - Creating Your First Application

This tutorial will teach you how to create a basic QuantumMaid app. It covers:
- Implementing an usecase
- Exporting the implemented usecase via HTTP
- Dependency injection
- Writing an integration test
- Packaging of the application

To follow this tutorial, you need:
- JDK 11+ installed
- Apache Maven >3.5.3

Make sure that Maven uses the correct Java version:
```bash
$ mvn -version
```

## What we are going to do

In the next 15 minutes, we will create a simple application.
It should offer the trivial usecase of greeting the user with a simple `"Hello"` message.
The usecase will be implemented as a plain Java class by the name `GreetingUseCase`.
In order to serve the `GreetingUseCase` via the HTTP protocol we will create a `WebService` class.
Furthermore, we will write an integration test.
Finally, the application is packaged as an executable `.jar` file.

## Skipping the tutorial

The tutorial is intended to be developed gradually. However, if you don't feel like following every step,
you can jump to the full source code.
Download an [archive](https://github.com/quantummaid/quantummaid-tutorials/archive/master.zip) or clone the git repository:

```bash
$ git clone https://github.com/quantummaid/quantummaid-tutorials.git
cd ./quantummaid-tutorials
```

The full step-by-step source code is located in the `./basic-tutorial` directory.


## Bootstrapping the project
QuantumMaid does not require your project to follow a specific format.
To start the tutorial, just run the following command:

```bash
mvn archetype:generate \
    --batch-mode \
    -DarchetypeGroupId=de.quantummaid.tutorials.archetypes \
    -DarchetypeArtifactId=basic-archetype \
    -DarchetypeVersion=1.0.13 \
    -DgroupId=de.quantummaid.tutorials \
    -DartifactId=basic-tutorial \
    -Dversion=1.0.0 \
    -Dpackaging=java
cd ./basic-tutorial
```

It generates the following in `./basic-tutorial`:
- the Maven structure
- an empty class `de.quantummaid.tutorials.GreetingUseCase`
- an empty class `de.quantummaid.tutorials.WebService`
- an empty test class `de.quantummaid.tutorials.GreetingTest` (under `/src/main/test`)

Once generated, look at the `pom.xml` file.
In order to use QuantumMaid for creating web services, you need to add a dependency to it:

<!---[CodeSnippet](quantummaiddependency)-->
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>de.quantummaid.quantummaid</groupId>
            <artifactId>quantummaid-bom</artifactId>
            <version>1.0.17</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
<dependencies>
    <dependency>
        <groupId>de.quantummaid.quantummaid.packagings</groupId>
        <artifactId>quantummaid-essentials</artifactId>
    </dependency>
</dependencies>
```
We also added a [BOM](https://medium.com/java-user-group-malta/maven-s-bill-of-materials-bom-b430ede60599) so we do not have to specify version numbers.

## The first usecase
 
To start the project, modify the `GreetingUseCase` class to contain the following content:

<!---[CodeSnippet](usecase1)-->
```java
package de.quantummaid.tutorials;

public final class GreetingUseCase {

    public String hello() {
        return "hello";
    }
}
```
 
It’s a very simple usecase, returning `"hello"` to all invocations of `hello()`. Note that it doesn't contain
any references or imports to actual web technology like JXR-RS annotations. It is completely infrastructure agnostic.

## Exporting the usecase
Since the `GreetingUseCase` class does specify how the usecase should be served using HTTP, that particular aspect needs to be configured outside of the class.
To achieve this, we will use QuantumMaid's **HttpMaid** sub-project specialized on everything related to the web.
It can be configured like this (do not add it to the project yet):
<!---[CodeSnippet](httpmaid)-->
```java
HttpMaid.anHttpMaid()
        .get("/hello", GreetingUseCase.class)
        .build();
```
It’s a very simple configuration, binding the `GreetingUseCase` to `GET` requests to `/hello`, which will then be answered with `"hello"`.

**Differences to other frameworks**:
With QuantumMaid, there is no need to add framework-specific annotations (JAX-RS, Spring WebMVC, etc.) to your classes. Their usage drastically decreases application start-up time and
promotes less-than-optimal architecture. When done architecturally sane, they tend to come along with significant amounts of boilerplate code.
You can find an in-depth analysis of the problem [here](../annotation-whitepaper/README.md).

In order to run our application, we need to bind HttpMaid to a port.
This can be done by modifying the `WebService` class like this:

<!---[CodeSnippet](webservice2)-->
```java
package de.quantummaid.tutorials;

import de.quantummaid.httpmaid.HttpMaid;
import de.quantummaid.quantummaid.QuantumMaid;

public final class WebService {
    private static final int PORT = 8080;

    public static QuantumMaid createQuantumMaid(final int port) {
        final HttpMaid httpMaid = HttpMaid.anHttpMaid()
                .get("/hello", GreetingUseCase.class)
                .build();
        return QuantumMaid.quantumMaid()
                .withHttpMaid(httpMaid)
                .withLocalHostEndpointOnPort(port);
    }

    public static void main(final String[] args) {
        createQuantumMaid(PORT).run();
    }
}
```

Now we can run the application. Just start it normally by executing the `main()`-method.
Once started, you can verify that it works as intended like this:
```
$ curl http://localhost:8080/hello
"hello"
```

**Note**: Skip to the bottom of this tutorial for real-world deployments like **Docker** and **AWS Lambda**.

## Mapping request data

**Note:** The following step requires your application to be compiled with the `-parameters` compile option.
Doing so gives the QuantumMaid [runtime access to parameter names](http://openjdk.java.net/jeps/118) and
enables it to map parameters automatically.
If you bootstrapped the tutorial from the provided archetype, this option is already set. 
Take a look [here](https://www.logicbig.com/how-to/java-command/java-compile-with-method-parameter-names.html) to learn
how to configure this on your own.
Also make sure that your IDE correctly adopted the `-parameters` option.
If you need to set it manually, look [here](https://www.jetbrains.com/help/idea/specifying-compilation-settings.html#configure_compiler_settings)
for IntelliJ IDEA and [here](https://stackoverflow.com/questions/9483315/where-do-you-configure-eclipse-java-compiler-javac-flags) for Eclipse.
 

Let's make the `GreetingUseCase` slightly more complex by adding a parameter to its `hello()` method:

<!---[CodeSnippet](usecase2)-->
```java
package de.quantummaid.tutorials;

public final class GreetingUseCase {

    public String hello(final String name) {
        return "hello " + name;
    }
}
```
Our goal is to map a so-called HTTP path parameter to the `name` parameter.
Requests to `/hello/quantummaid` should result in the method being called as `hello("quantummaid")`,
requests to `/hello/frodo` as `hello("frodo)`, etc.
In traditional application frameworks, we achieve this by annotating the `name` parameter with something like the
JAX-RS `@PathParam` annotation. Since QuantumMaid guarantees to keep your business logic 100% infrastructure agnostic under
all circumstances, this not an option. Instead, we will modify the `WebService` class accordingly to tell HttpMaid
to look into the request's path parameters in order to resolve the `name` parameter of the usecase method:

<!---[CodeSnippet](webservice3)-->
```java
package de.quantummaid.tutorials;

import de.quantummaid.httpmaid.HttpMaid;
import de.quantummaid.quantummaid.QuantumMaid;

public final class WebService {
    private static final int PORT = 8080;

    public static QuantumMaid createQuantumMaid(final int port) {
        final HttpMaid httpMaid = HttpMaid.anHttpMaid()
                .get("/hello/<name>", GreetingUseCase.class)
                .build();
        return QuantumMaid.quantumMaid()
                .withHttpMaid(httpMaid)
                .withLocalHostEndpointOnPort(port);
    }

    public static void main(final String[] args) {
        createQuantumMaid(PORT).run();
    }
}
```

Stop the old running application and start it again with the new functionality:
```
$ curl http://localhost:8080/hello/quantummaid
"hello quantummaid"
```


## Dependency Injection

QuantumMaid supports dependency injection, but does not implement it.
Out of the box, it is only able to instantiate classes that have a public constructor without any parameters
(like our `GreetingUseCase`).
It is recommended to use any existing dependency of choice. Look [here](https://github.com/quantummaid/httpmaid/blob/master/docs/12_UseCases/5_DependencyInjection.md)
for detailed instructions on
integrating popular dependency injection frameworks like [Guice](https://github.com/google/guice) and [Dagger](https://dagger.dev/).    

## Testing

Tests are an integral component of every application. QuantumMaid supports you in writing them.
In the generated pom.xml file, you can see two test dependencies:
<!---[CodeSnippet](testdependency)-->
```xml
<dependency>
    <groupId>de.quantummaid.quantummaid.packagings</groupId>
    <artifactId>quantummaid-test-essentials</artifactId>
    <scope>test</scope>
</dependency>
```

**Warning:** This tutorial uses the `REST Assured` library because it is well-known and
allows for very readable test definitions. Despite its widespread use, `REST Assured`
introduces the vulnerabilities [CVE-2016-6497](https://nvd.nist.gov/vuln/detail/CVE-2016-6497), [CVE-2016-5394](https://nvd.nist.gov/vuln/detail/CVE-2016-5394)
and [CVE-2016-6798](https://nvd.nist.gov/vuln/detail/CVE-2016-6798) to your project.
Please check for your project whether these vulnerabilities pose an actual threat.

The generated project contains the `de.quantummaid.tutorials.GreetingTest` test class.
Implement the test like this:
<!---[CodeSnippet](initializedtest)-->
```java
package de.quantummaid.tutorials;

import de.quantummaid.quantummaid.QuantumMaid;
import de.quantummaid.quantummaid.integrations.junit5.QuantumMaidTest;
import de.quantummaid.quantummaid.integrations.testsupport.QuantumMaidProvider;
import org.junit.jupiter.api.Test;

import static de.quantummaid.tutorials.WebService.createQuantumMaid;
import static io.restassured.RestAssured.given;
import static org.hamcrest.core.Is.is;

@QuantumMaidTest
public final class GreetingTest implements QuantumMaidProvider {

    @Override
    public QuantumMaid provide(final int port) {
        return createQuantumMaid(port);
    }

    @Test
    public void testGreeting() {
        given()
                .when().get("/hello/quantummaid")
                .then()
                .statusCode(200)
                .body(is("\"hello quantummaid\""));
    }
}
```
Now you can run the test and verify that the application indeed behaves correctly.


## Packaging the application
QuantumMaid applications can be packaged in exactly the same way as every other normal Java
application. A common way to achieve this would be to use the [maven-assembly-plugin](https://maven.apache.org/plugins/maven-assembly-plugin/usage.html).
All you need to do is add the following code to your `pom.xml` and replace `de.quantummaid.tutorials.basic.step4.WebService` with the fully
qualified domain name of your `WebService` class:

<!---[CodeSnippet](mavenassemblyplugin)-->
```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-assembly-plugin</artifactId>
            <version>3.2.0</version>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>single</goal>
                    </goals>
                    <configuration>
                        <finalName>my-app</finalName>
                        <archive>
                            <manifest>
                                <mainClass>
                                    de.quantummaid.tutorials.WebService
                                </mainClass>
                            </manifest>
                        </archive>
                        <descriptorRefs>
                            <descriptorRef>jar-with-dependencies</descriptorRef>
                        </descriptorRefs>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

You can now run `mvn clean package` and then find a fully packaged executable `.jar` file under `target/my-app-jar-with-dependencies.jar`.
To start it, just run:
```bash
$ java -jar target/my-app-jar-with-dependencies.jar
```

## What's next?

If you are interested in packaging a QuantumMaid application for specific targets, simply follow
one of our advanced tutorials:

[Packaging for AWS Lambda](../aws-lambda/README.md)

[Packaging for Docker/Kubernetes](../docker/README.md)

[Packaging for Tomcat/JBoss/Glassfish](../war/README.md)

