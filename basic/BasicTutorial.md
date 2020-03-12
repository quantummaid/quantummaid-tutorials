# QuantumMaid - Creating Your First Application

Learn how to create a *Hello World* QuantumMaid app. This guide covers:
- Bootstrapping an application
- Creating an use case
- Exporting the use case via HTTP
- Dependency injection
- Packaging of the application

## Prerequisites
To complete this guide, you need:
- less than 15 minutes
- an IDE
- JDK 11+ installed with JAVA_HOME configured appropriately
- Apache Maven 3.5.3+

Make sure that Maven uses the correct Java version:
```bash
$ mvn -version
```

## What we are going to do

In this guide, we create a straightforward application serving an *hello*-endpoint.
The endpoint is bound to a so-called **use case** - a simple Java class that provides
the greeting functionality without caring about how it is displayed on the web.
To demonstrate dependency injection, the endpoint uses a greeting logger.

## Skipping the tutorial

We recommend that you follow the instructions from this point onwards to create the application step by step.
However, you can go right to the complete source code.
Download an [archive](https://github.com/quantummaid/quantummaid-tutorials/archive/master.zip) or clone the git repository:

```bash
$ git clone https://github.com/quantummaid/quantummaid-tutorials.git
cd ./quantummaid-tutorials
```

The full step-by-step source code is located in the ./basic directory.


## Bootstrapping the project
QuantumMaid does not require your project to follow a specific format.
The easiest way to create a new project is to open a terminal and run the following command:

```bash
mvn archetype:generate \
    --batch-mode \
    -DarchetypeGroupId=de.quantummaid.tutorials.archetypes \
    -DarchetypeArtifactId=basic-archetype \
    -DarchetypeVersion=1.0.0 \
    -DgroupId=de.quantummaid.tutorials \
    -DartifactId=basic-tutorial \
    -Dversion=1.0.0 \
    -Dpackaging=java
cd ./basic-tutorial
```

It generates the following in ./basic-tutorial:
- the Maven structure
- an `de.quantummaid.tutorials.basic-tutorial.GreetingUseCase` bound to `/hello`
- an associated integration test

Once generated, look at the `pom.xml` file.
In order to use QuantumMaid for creating web services, you need to add a dependency to `HttpMaid`:

<!---[CodeSnippet](httpmaiddependency)-->
```xml
<dependency>
    <groupId>de.quantummaid.httpmaid.integrations</groupId>
    <artifactId>httpmaid-all</artifactId>
    <version>0.9.20</version>
</dependency>
```
**Explanation**: QuantumMaid consists of several sub-projects. HttpMaid is the sub-project concerned
with everything related to the web.

## The first use case
 
To start the project, create a `src/main/java/com/mycompany/app/GreetingUseCase.java` class with the following content:

<!---[CodeSnippet](usecase1)-->
```java
public final class GreetingUseCase {

    public String hello() {
        return "hello";
    }
}
```
 
It’s a very simple use case, returning `"hello"` to all invocations of `hello()`. Note that it doesn't contain
any references or imports to actual web technology like JXR-RS annotations. It's completely infrastructure agnostic.

## Exporting the use case
We can now use HttpMaid to export the use case via HTTP. To do this, create a `WebService` class like this:

<!---[CodeSnippet](webservice1)-->
```java
import de.quantummaid.httpmaid.HttpMaid;

public final class WebService {

    private WebService() {
    }

    public static void main(final String[] args) {
        HttpMaid.anHttpMaid()
                .get("/hello", GreetingUseCase.class)
                .build();
    }
}
```
It’s a very simple configuration, binding the `GreetingUseCase` to requests to `/hello`, which will then be answered with `"hello"`.

**Differences to other frameworks**:
With QuantumMaid, there is no need to add JAX-RS annotations to your classes. Their usage drastically decreases application start-up time and
promotes less-than-optimal architecture. When done architecturally sane, they tend to come along with significant amounts of boilerplate code.
You can find an in-depth analysis of this problem [here](todo).


## Running the application
In order to run our application, we need to tell HttpMaid how to serve the endpoint.
For the sake of simplicity, the HttpServer shipped with normal Java is sufficient.
You can use it by modifying the `WebService` like this:

<!---[CodeSnippet](webservice2)-->
```java
import de.quantummaid.httpmaid.HttpMaid;
import de.quantummaid.quantummaid.QuantumMaid;
import de.quantummaid.tutorials.basic.step1.GreetingUseCase;

public final class WebService {
    private static final int PORT = 8080;

    private WebService() {
    }

    public static void main(final String[] args) {
        final HttpMaid httpMaid = HttpMaid.anHttpMaid()
                .get("/hello", GreetingUseCase.class)
                .build();
        QuantumMaid.quantumMaid()
                .withHttpMaid(httpMaid)
                .withLocalHostEndpointOnPort(PORT)
                .run();
    }
}
```

Now we are ready to run the application. Just start it normally by running the `main()`-method.
Once started, you can request the provided endpoint:
```
$ curl http://localhost:8080/hello
hello
```

**Note**: Skip to the bottom of this tutorial for real-world deployments like **Docker** and **AWS Lambda**.

## Mapping request data

Let's make the greeting use case slightly more complex by adding a parameter to its `hello()` method:

<!---[CodeSnippet](usecase2)-->
```java
public final class GreetingUseCase {

    public String hello(final String name) {
        return "hello " + name;
    }
}
```
Our goal is to map a so-called path parameter to the `name` parameter.
Requests to `/hello/quantummaid` should result in the method being called as `hello("quantummaid")`,
requests to `/hello/frodo` as `hello("frodo)`, etc.
In traditional application frameworks, we achieve this by annotating the `name` parameter with the
`@PathParam` JAX-RS annotation. Since QuantumMaid guarantees to keep your business logic 100% infrastructure agnostic under
all circumstances, this not an option. Instead, we will modify the `WebService` class accordingly to tell HttpMaid
to look into the request's path parameters in order to resolve the `name` parameter of the use case method:

<!---[CodeSnippet](webservice3)-->
```java
import de.quantummaid.httpmaid.HttpMaid;
import de.quantummaid.quantummaid.QuantumMaid;

import static de.quantummaid.httpmaid.events.EventConfigurators.toEnrichTheIntermediateMapWithAllPathParameters;

public final class WebService {
    private static final int PORT = 8080;

    private WebService() {
    }

    public static void main(final String[] args) {
        final HttpMaid httpMaid = HttpMaid.anHttpMaid()
                .get("/hello/<name>", GreetingUseCase.class)
                .configured(toEnrichTheIntermediateMapWithAllPathParameters())
                .build();
        QuantumMaid.quantumMaid()
                .withHttpMaid(httpMaid)
                .withLocalHostEndpointOnPort(PORT)
                .run();
    }
}
```

You can now run the application again and try out the new functionality:
```
$ curl http://localhost:8080/hello/quantummaid
hello quantummaid
```


## Using dependency injection

QuantumMaid supports dependency injection, but does not implement it. Nonetheless, it is very easy to use any dependency injection framework you desire.
We recommend to use [Guice](https://github.com/google/guice) and will demonstrate its integration in this section.
First, you need to add the following dependency to your `pom.xml`:

<!---[CodeSnippet](guicedependency)-->
```xml
<dependency>
    <groupId>com.google.inject</groupId>
    <artifactId>guice</artifactId>
    <version>4.2.2</version>
</dependency>
```


Let’s modify the application and add a `GreetingLogger` to be injected into our `GreetingUseCase`.
Create the `src/main/java/com/mycompany/app/GreetingLogger.java` class with the following content:

<!---[CodeSnippet](logger)-->
```java
public final class GreetingLogger {

    public void logGreeting(final String name) {
        System.out.println("New greeting for " + name);
    }
}
```


Edit the `GreetingUseCase` class to inject the `GreetingLogger`:

<!---[CodeSnippet](usecase3)-->
```java
public final class GreetingUseCase {
    private final GreetingLogger greetingLogger;

    public GreetingUseCase(final GreetingLogger greetingLogger) {
        this.greetingLogger = greetingLogger;
    }

    public String hello(final String name) {
        greetingLogger.logGreeting(name);
        return "hello " + name;
    }
}
```

The only thing left to do is to modify our HttpMaid configuration to perform dependency injection using
Guice:

<!---[CodeSnippet](webservice4)-->
```java
import com.google.inject.Guice;
import com.google.inject.Injector;
import de.quantummaid.httpmaid.HttpMaid;
import de.quantummaid.quantummaid.QuantumMaid;

import static de.quantummaid.httpmaid.events.EventConfigurators.toEnrichTheIntermediateMapWithAllPathParameters;
import static de.quantummaid.httpmaid.usecases.UseCaseConfigurators.toCreateUseCaseInstancesUsing;
import static de.quantummaid.quantummaid.integrations.guice.QuantumMaidGuiceBindings.bindToSinglePublicConstructor;

public final class WebService {
    private static final int PORT = 8080;

    private WebService() {
    }

    public static QuantumMaid createQuantumMaid(final int port) {
        final Injector injector = Guice.createInjector(
                bindToSinglePublicConstructor(GreetingUseCase.class)
        );
        final HttpMaid httpMaid = HttpMaid.anHttpMaid()
                .get("/hello/<name>", GreetingUseCase.class)
                .configured(toEnrichTheIntermediateMapWithAllPathParameters())
                .configured(toCreateUseCaseInstancesUsing(injector::getInstance))
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


Restart the application and check that the endpoint returns the expected output:
```
$ curl http://localhost:8080/hello/quantummaid
hello quantummaid
```

## Testing

Tests are an integral component of every application. QuantumMaid supports you in writing them.
In the generated pom.xml file, you can see one test dependency:
<!---[CodeSnippet](testdependency)-->
```xml
<dependency>
    <groupId>de.quantummaid.quantummaid.integrations</groupId>
    <artifactId>quantummaid-junit5</artifactId>
    <version>1.0.1</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>4.2.0</version>
    <scope>test</scope>
</dependency>
```

The generated project contains the `de.quantummaid.tutorials.GreetingTest` test class.
In order to run the test, we need to implement the `provide()` method:
<!---[CodeSnippet](initializedtest)-->
```java
import de.quantummaid.quantummaid.QuantumMaid;
import de.quantummaid.quantummaid.integrations.junit5.QuantumMaidProvider;
import de.quantummaid.quantummaid.integrations.junit5.QuantumMaidTest;
import org.junit.jupiter.api.Test;

import static de.quantummaid.tutorials.basic.step4.WebService.createQuantumMaid;
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
                                    de.quantummaid.tutorials.basic.step2.WebService
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

You can now run `mvn clean package` and then find a fully packaged executable jar under `target/my-app-jar-with-dependencies.jar`.
To start it, just run:
```bash
$ java -jar target/my-app-jar-with-dependencies.jar
```

If you are interested in packaging a QuantumMaid application for specific targets, simply follow
one of our advanced tutorials:

[Packaging for AWS Lambda](todo)

[Packaging for Docker/Kubernetes](todo)

[Packaging for Tomcat/JBoss/Glassfish](todo)

