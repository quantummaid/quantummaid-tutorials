# Step 4: Updating our function

(Full source code: [step4 directory](step4))

A function that returns "Hello World!" is not very useful.
We'll make the returned `Hello message [vary based on the url path](https://quantummaid.de/docs/2_httpmaid/04_handlingrequests.html#request-route-and-path-parameters).

```java
public final class Main {
  //...
  private static HttpMaid httpMaidConfig() {
    final HttpMaid httpMaid = HttpMaid.anHttpMaid()
        .get("/hello/<who>", (request, response) -> response.setBody(
            String.format("Hello, %s!",
                request.pathParameters().getPathParameter("who"))))
        .build();
    return httpMaid;
  }
}
```

To deploy the change, use the same command pair as in step 3.
This time however, we don't need to answer any questions, because previous answers are saved to `samconfig.toml`

```shell
$ sam build
$ sam deploy
...
Successfully created/updated stack - hello-app in us-east-1
```

Before we invoke the url, let's tail the logs, which will give us some interesting details on our function execution(s).
In a separate terminal, run:

```shell
$ sam logs --tail --region us-east-1 --stack-name hello-app --name HelloWorldFunction
```

Back in the terminal where you ran `sam deploy`, run:

```shell
$ time echo $(curl -s $apiUrl/hello/{me,you,everyone})
Hello me!Hello you!Hello everyone!

real	0m2.990s
user	0m0.077s
sys	0m0.005s
```

The logs display something similar to the following simplified output:

```text
... 2020-06-21T09:22:07.659000 START RequestId: ... Version: $LATEST
... 2020-06-21T09:22:07.677000 {version=2.0, routeKey=ANY /{proxy+}, rawPath=/hello/me,...
... 2020-06-21T09:22:08.058000 END RequestId: ...
... 2020-06-21T09:22:08.058000 REPORT RequestId: ...	Duration: 398.08 ms	Billed Duration: 400 ms	Memory Size: 512 MB	Max Memory Used: 101 MB	Init Duration: 870.58 ms
... 2020-06-21T09:22:08.242000 START RequestId: ... Version: $LATEST
... 2020-06-21T09:22:08.246000 {version=2.0, routeKey=ANY /{proxy+}, rawPath=/hello/you,...
... 2020-06-21T09:22:08.248000 END RequestId: ...
... 2020-06-21T09:22:08.248000 REPORT RequestId: ...	Duration: 3.32 ms	Billed Duration: 100 ms	Memory Size: 512 MB	Max Memory Used: 101 MB
... 2020-06-21T09:22:08.442000 START RequestId: ... Version: $LATEST
... 2020-06-21T09:22:08.446000 {version=2.0, routeKey=ANY /{proxy+}, rawPath=/hello/everyone,...
... 2020-06-21T09:22:08.448000 END RequestId: ...
... 2020-06-21T09:22:08.448000 REPORT RequestId: ...	Duration: 3.32 ms	Billed Duration: 100 ms	Memory Size: 512 MB	Max Memory Used: 101 MB
```

Important statistics:

- Time spent in lambda = Init Duration: 870.58 ms + Duration: 398.08 ms + Duration: 3.32 ms + Duration: 3.32 ms = 1275.3ms
- Time spent overall = 2.990s = 2990ms
- Unaccounted time = 2990ms - 1275.3ms = 1714,7ms, of which
  - approx. 600ms is probably due to network latency (100ms each way x 3 requests)
  - approx. 1100ms is as yet unexplained

Having this log output at hand allows us to immediately draw a few conclusions:

- The HttpMaid overhead is flat beyond the first invocation (<5ms)
- The network latency is quite high here (200ms per request). Maybe we can switch to an edge-optimized api.
- If performance is important, 1100ms is still unaccounted for and needs investigation. It could be TLS negotiation, or something else.
- The memory configuration of our function could be lowered from 512mb to something much closer to the memory used (101mb), 128mb for example.

You now have the necessary building blocks to make your HttpMaid code Lambda capable, and to dig deeper into its runtime characteristics in AWS Lambda.
