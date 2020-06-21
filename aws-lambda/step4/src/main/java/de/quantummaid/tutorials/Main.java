package de.quantummaid.tutorials;

import de.quantummaid.httpmaid.HttpMaid;
import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;
import de.quantummaid.quantummaid.QuantumMaid;

import java.util.Map;

import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;

public final class Main {
  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(httpMaidConfig());

  public Map<String, Object> handleRequest(Map<String, Object> request) {
    System.err.println(request.toString());
    return ADAPTER.delegate(request);
  }

  private static HttpMaid httpMaidConfig() {
    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
        .get("/hello/<who>", (request, response) -> response.setBody(
            String.format("Hello %s!",
                request.pathParameters().getPathParameter("who"))))
        .build();
    return httpMaid;
  }

  public static void main(String[] args) {
    final int port = 8080;
    final HttpMaid httpMaid = httpMaidConfig();
    final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
        .withHttpMaid(httpMaid)
        .withLocalHostEndpointOnPort(port);
    quantumMaid.runAsynchronously();
  }
}
