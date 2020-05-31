package todomaid.api;

import de.quantummaid.httpmaid.handler.http.HttpHandler;
import de.quantummaid.quantummaid.QuantumMaid;
import org.jetbrains.annotations.NotNull;

import static de.quantummaid.httpmaid.HttpMaid.anHttpMaid;
import static de.quantummaid.quantummaid.QuantumMaid.quantumMaid;

public final class Server {
  public static void main(String[] args) {
    serverInstance(8080).run();
  }

  @NotNull
  private static QuantumMaid serverInstance(int port) {
    QuantumMaid quantumMaid = quantumMaid()
        .withHttpMaid(anHttpMaid()
            .get("/*", dumpRequest())
            //.options("/*", dumpRequest())
            //.patch("/*", dumpRequest())
            .post("/*", dumpRequest())
            .put("/*", dumpRequest())
            .delete("/*", dumpRequest()).build())
        .withLocalHostEndpointOnPort(port);
    return quantumMaid;
  }

  private static HttpHandler dumpRequest() {
    return (request, response) -> System.err.printf("%s %s %n", request.method(), request.path());
  }
}

