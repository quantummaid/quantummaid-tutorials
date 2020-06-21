package de.quantummaid.tutorials;

import de.quantummaid.httpmaid.HttpMaid;
//Showcase start step2AdapterDeclaration1
import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;
import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;
//Showcase end step2AdapterDeclaration1
import de.quantummaid.quantummaid.QuantumMaid;

import java.util.Map;

//Showcase start step2AdapterDeclaration2
public final class Main {
  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(httpMaidConfig());
  //...
  //Showcase end step2AdapterDeclaration2

  //Showcase start step2RequestHandlingMethod
  public Map<String, Object> handleRequest(Map<String, Object> request) {
    return ADAPTER.delegate(request);
  }
  //Showcase end step2RequestHandlingMethod

  //Showcase start step2HttpMaidConfig
  private static HttpMaid httpMaidConfig() {
    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
        .get("/helloworld", (request, response) -> response.setBody("Hello World!"))
        .build();
    return httpMaid;
  }
  //Showcase end step2HttpMaidConfig

  public static void main(String[] args) {
    final int port = 8080;
    final HttpMaid httpMaid = httpMaidConfig();
    final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
        .withHttpMaid(httpMaid)
        .withLocalHostEndpointOnPort(port);
    quantumMaid.runAsynchronously();
  }
}
