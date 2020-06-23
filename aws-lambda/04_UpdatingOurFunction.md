# Step 4: Updating our function

(Full source code: [step4 directory](step4))

## /hello/<whoever-you-are>

A function that returns `"Hello World!"` is not very useful.
We'll make the returned Hello message [vary based on the URL path](https://quantummaid.de/docs/2_httpmaid/04_handlingrequests.html#request-route-and-path-parameters).

<!---[CodeSnippet](step4HttpMaidConfig)-->
```java
private static HttpMaid httpMaidConfig() {
  final HttpMaid httpMaid = HttpMaid.anHttpMaid()
      .get("/hello/<whoever-you-are>", (request, response) -> response.setBody(
          String.format("Hello %s!",
              request.pathParameters().getPathParameter("whoever-you-are"))))
      .build();
  return httpMaid;
}
```

## Updating the function using SAM CLI

To deploy the change, use the same command pair as in step 3.
This time however, we don't need to answer any questions, because previous answers are saved to `samconfig.toml`

```shell
$ sam build
$ sam deploy
...
Successfully created/updated stack - hello-app in us-east-1
```

## Viewing logs using SAM CLI

Before we invoke the URL, let's tail the logs, which will give us some interesting details on our function execution(s).
In a separate terminal, run:

```shell
$ sam logs --tail --region us-east-1 --stack-name hello-app --name HelloWorldFunction
```

## Getting runtime statistics

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

- Time spent in Lambda = Init Duration: 870.58 ms + Duration: 398.08 ms + Duration: 3.32 ms + Duration: 3.32 ms = 1275.3 ms
- Time spent overall = 2.990 s = 2990 ms
- Unaccounted time = 2990 ms - 1275.3 ms = 1714,7 ms, of which
  - approx. 600 ms is probably due to network latency (100 ms each way x 3 requests)
  - approx. 1100 ms is as yet unexplained

Having this log output at hand allows us to immediately draw a few conclusions:

- The HttpMaid overhead is flat beyond the first invocation (<5 ms)
- The network latency is quite high here (200 ms per request). Maybe we can switch to an edge-optimized API.
- If performance is important, 1100 ms is still unaccounted for and needs investigation. It could be TLS negotiation, or something else.
- We can save money by reducing `MemorySize` in `template.yml` from 512 MB to something much closer to the maximum reported memory usage (101 MB), say, 128 MB.

You now have the necessary building blocks to make your HttpMaid code AWS Lambda capable,
and to get information about its runtime characteristics, for further tweaking.

Next, we are going to clean up the resources we created for this tutorial, so as not to incur any unwanted costs.

<!---[Nav]-->
[&larr;](03_DeployingOurFunction.md)&nbsp;&nbsp;&nbsp;[Overview](README.md)&nbsp;&nbsp;&nbsp;[&rarr;](05_CleaningUp.md)
