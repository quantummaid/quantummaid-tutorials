# QuantumMaid - Create your first application

This tutorial will teach you how to create a basic QuantumMaid application. It covers:
- Implementing a usecase
- Exporting the implemented usecase via HTTP
- Dependency injection
- Writing an integration test
- Packaging the application

To follow the tutorial, you need:
- JDK 11+
- Apache Maven >3.5.3

Make sure that Maven uses the correct Java version:
```bash
$ mvn -version
```

## 1. What we are going to do

In the next 15 minutes, we will create a simple application.
It should offer the trivial usecase of greeting the user with a simple `"Hello"` message.
The usecase will be implemented as a plain Java class by the name `GreetingUseCase`.
In order to serve the `GreetingUseCase` via the HTTP protocol we will create a `WebService` class.
Furthermore, we will write an integration test.
Finally, the application is packaged as an executable `.jar` file.

## 2. Bootstrapping the project
QuantumMaid does not require your project to follow a specific format.
To start the tutorial, just run the following command:

```bash
mvn archetype:generate \
    --batch-mode \
    -DarchetypeGroupId=de.quantummaid.tutorials.archetypes \
    -DarchetypeArtifactId=basic-archetype \
    -DarchetypeVersion=1.0.31 \
    -DgroupId=de.quantummaid.tutorials \
    -DartifactId=basic-tutorial \
    -Dversion=1.0.0 \
    -Dpackaging=java
cd ./basic-tutorial
```

If you are following the tutorial on a Windows computer, you can alternatively use this command:

```bash
mvn archetype:generate ^
    --batch-mode ^
    -DarchetypeGroupId=de.quantummaid.tutorials.archetypes ^
    -DarchetypeArtifactId=basic-archetype ^
    -DarchetypeVersion=1.0.31 ^
    -DgroupId=de.quantummaid.tutorials ^
    -DartifactId=basic-tutorial ^
    -Dversion=1.0.0 ^
    -Dpackaging=java
cd ./basic-tutorial
```

It generates the following in `./basic-tutorial`:
- The Maven structure
- An empty class `de.quantummaid.tutorials.GreetingUseCase`
- An empty class `de.quantummaid.tutorials.WebService`
- An empty test class `de.quantummaid.tutorials.GreetingTest` (under `/src/main/test`)

Once generated, look at the `pom.xml` file.
In order to use QuantumMaid for creating web services, you need to add a dependency:

<!---[CodeSnippet](quantummaiddependency)-->
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>de.quantummaid.quantummaid</groupId>
            <artifactId>quantummaid-bom</artifactId>
            <version>1.0.70</version>
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
We also added a [BOM](https://medium.com/java-user-group-malta/maven-s-bill-of-materials-bom-b430ede60599) so you do not have to specify version numbers.

## 3. The first usecase
 
To start the project, modify the `GreetingUseCase` class to contain the following content:

<!---[CodeSnippet](usecase1)-->
```java
package de.quantummaid.tutorials;

public final class GreetingUseCase {

    public String hello() {
        return "hello world";
    }
}
```
 
It’s a very simple usecase, returning `"hello world"` to all invocations of `hello()`.
 
**Note:** The usecase class does not contain any references or imports to actual web technology like JXR-RS annotations. It is completely infrastructure agnostic.

## 4. Exporting the usecase
Since the `GreetingUseCase` class does specify how the usecase should be served using HTTP, that particular aspect needs to be configured outside of the class.
Since the `GreetingUseCase` class does not specify how the usecase should be served using HTTP,
that particular aspect needs to be configured outside of the class (do not add it to the project yet):
<!---[CodeSnippet](httpmaid)-->
```java
QuantumMaid.quantumMaid()
        .get("/helloworld", GreetingUseCase.class);
```
The configuration binds the `GreetingUseCase` to `GET` requests to `/helloworld`, which will then be answered with `"hello world"`.

In order to run our application, we need to bind QuantumMaid to a port.
This can be done by modifying the `WebService` class like this:

<!---[CodeSnippet](webservice2)-->
```java
package de.quantummaid.tutorials;

import de.quantummaid.quantummaid.QuantumMaid;

public final class WebService {
    private static final int PORT = 8080;

    public static void main(final String[] args) {
        createQuantumMaid(PORT).run();
    }

    public static QuantumMaid createQuantumMaid(final int port) {
        return QuantumMaid.quantumMaid()
                .get("/helloworld", GreetingUseCase.class)
                .withLocalHostEndpointOnPort(port);
    }
}
```

Now we can run the application. Just start it normally by executing the `main()`-method.
Once started, you can verify that it works as intended like this:
```
$ curl http://localhost:8080/helloworld
"hello world"
```

**Note:** With QuantumMaid, there is no need to add framework-specific annotations (JAX-RS, Spring WebMVC, etc.) to your classes. Their usage drastically decreases application start-up time and
promotes less-than-optimal architecture. When done architecturally sane, they tend to come along with significant amounts of boilerplate code.
Please refer to our [in-depth analysis of the problem](../annotation-whitepaper/README.md) for details.

**Note**: Skip to the bottom of this tutorial for real-world deployments like **Docker** and **AWS Lambda**.

## 5. Mapping request data

**Prerequisite (only necessary if you did not use the provided archetype):** The following step requires your application to be compiled with the `-parameters` compile option.
Doing so gives QuantumMaid [runtime access to parameter names](http://openjdk.java.net/jeps/118) and
enables it to map parameters automatically.
If you bootstrapped the tutorial from the provided archetype, this option is already set.
Otherwise, you need to [configure it on your own](https://www.logicbig.com/how-to/java-command/java-compile-with-method-parameter-names.html).
Also make sure that your IDE correctly adopted the `-parameters` option.
There are straightforward guides for [IntelliJ IDEA](https://www.jetbrains.com/help/idea/specifying-compilation-settings.html#configure_compiler_settings)
and [Eclipse](https://stackoverflow.com/questions/9483315/where-do-you-configure-eclipse-java-compiler-javac-flag) in case you need to set it manually
(note that it is a compiler option - not a VM option).

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

Modify the `WebService` class to resolve the `name` parameter:

<!---[CodeSnippet](webservice3)-->
```java
package de.quantummaid.tutorials;

import de.quantummaid.quantummaid.QuantumMaid;

public final class WebService {
    private static final int PORT = 8080;

    public static void main(final String[] args) {
        createQuantumMaid(PORT).run();
    }

    public static QuantumMaid createQuantumMaid(final int port) {
        return QuantumMaid.quantumMaid()
                .get("/hello/<name>", GreetingUseCase.class)
                .withLocalHostEndpointOnPort(port);
    }
}
```

Stop the old running application and start it again with the new functionality:
```
$ curl http://localhost:8080/hello/quantummaid
"hello quantummaid"
```

**Explanation:** We configured QuantumMaid to map a so-called HTTP path parameter to the `name` parameter.
Requests to `/hello/quantummaid` should result in the method being called as `hello("quantummaid")`,
requests to `/hello/frodo` as `hello("frodo)`, etc.
In traditional application frameworks, we achieve this by annotating the `name` parameter with something like the
JAX-RS `@PathParam` annotation. Since QuantumMaid guarantees to keep your business logic 100% infrastructure agnostic under
all circumstances, this is not an option. 

## 6. Dependency injection

QuantumMaid supports dependency injection, but does not implement it.
Out of the box, it is only able to instantiate classes that have a public constructor without any parameters
(like our `GreetingUseCase`). QuantumMaid is not prescriptive regarding your choice of dependency injection framework,
and provides
[detailed instructions on integrating popular dependency injection frameworks like Guice and Dagger](https://github.com/quantummaid/httpmaid/blob/master/docs/12_UseCases/5_DependencyInjection.md).

## 7. Testing

Please add the following test dependency to your `pom.xml`:
<!---[CodeSnippet](testdependency)-->
```xml
<dependency>
    <groupId>de.quantummaid.quantummaid.packagings</groupId>
    <artifactId>quantummaid-test-essentials</artifactId>
    <scope>test</scope>
</dependency>
```

Implement the empty `de.quantummaid.tutorials.GreetingTest` test class like this:
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

**Explanation:** By declaring the `@QuantumMaidTest` annotation, QuantumMaid will automatically create an application instance
for every test and configure REST Assured accordingly. This way, you don't have to provide a URL in your tests or worry about port
allocation and cleanup.

**Warning:** This tutorial uses the **REST Assured** library because it is well known and
allows for very readable test definitions. Despite its widespread use, REST Assured
introduces the vulnerabilities [CVE-2016-6497](https://nvd.nist.gov/vuln/detail/CVE-2016-6497), [CVE-2016-5394](https://nvd.nist.gov/vuln/detail/CVE-2016-5394)
and [CVE-2016-6798](https://nvd.nist.gov/vuln/detail/CVE-2016-6798) to your project.
Please check for your project whether these vulnerabilities pose an actual threat.

## 8. Packaging the application
QuantumMaid applications can be packaged in exactly the same way as every other normal Java
application. A common way to achieve this would be to use the [maven-assembly-plugin](https://maven.apache.org/plugins/maven-assembly-plugin/usage.html).
All you need to do is to insert the following code into the `<plugins>...</plugins>` section of your `pom.xml`:

<!---[CodeSnippet](mavenassemblyplugin)-->
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-assembly-plugin</artifactId>
    <version>3.3.0</version>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>single</goal>
            </goals>
            <configuration>
                <finalName>quantummaid-app</finalName>
                <appendAssemblyId>false</appendAssemblyId>
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
```

You can now tell Maven to package your application:
```bash
$ mvn clean package
```
Afterwards, you will find a fully packaged executable `.jar` file under `target/quantummaid-app.jar`.
To start it, just run:
```bash
$ java -jar target/quantummaid-app.jar
```

## 9. What's next?
If you are interested in packaging a QuantumMaid application for specific targets, simply follow
one of our advanced tutorials:

Coming soon: [Packaging for AWS Lambda](../aws-lambda/README.md)

Coming soon: [Packaging for Docker/Kubernetes](../docker/README.md)

Coming soon: [Packaging for Tomcat/JBoss/Glassfish](../war/README.md)

## 10. Did you like what you just read?
Please do not hesitate to share your thoughts and criticism with us!
We are always and directly available on [Slack](https://quantummaid.de/community.html)
and [Gitter](https://gitter.im/quantum-maid-framework/community). Every single piece of feedback will be accepted gratefully
and receive undivided attention from our entire development team.
Additionally, anyone who gives feedback will be mentioned in our contributors' list (unless you prefer to stay anonymous, of course). 

Last but not least, please do not forget to follow us on [Twitter](https://twitter.com/quantummaid)!
