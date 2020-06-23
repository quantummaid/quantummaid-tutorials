package de.quantummaid.tutorials.itests;

import de.quantummaid.httpmaid.HttpMaid;
import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;

import java.util.Map;

import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;

public class Handler {
  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(httpMaidConfig());

  public Map<String, Object> handleRequest(Map<String, Object> request) {
    return ADAPTER.delegate(request);
  }

  private static HttpMaid httpMaidConfig() {
    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
        .get("/helloworld", (request, response) -> response.setBody("Hello world!"))
        .get("/hello/<whoever-you-are>", (request, response) -> response.setBody(
            String.format("Hello %s!",
                request.pathParameters().getPathParameter("whoever-you-are"))))
        .build();
    return httpMaid;
  }
}
