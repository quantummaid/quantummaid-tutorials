# Step 4: Updating our function
*(Full source code: [`step4`](step4) directory)*

## /hello/`<whoever-you-are>`

A function that returns `"Hello World!"` is not very useful.
We'll make the returned *Hello* message [vary based on the URL path](https://quantummaid.de/docs/2_httpmaid/04_handlingrequests.html#request-route-and-path-parameters).

<!---[CodeSnippet](step4HttpMaidConfig)-->
```java
private static QuantumMaid quantumMaidConfig() {
  return QuantumMaid.quantumMaid()
      .get("/hello/<whoever-you-are>", (request, response) -> response.setBody(
          String.format("Hello %s!",
              request.pathParameters().getPathParameter("whoever-you-are"))));
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

## Calling the new function

We can now check that the updated function uses the path parameter for salutation:

```shell
$ time echo $(curl -s $apiUrl/hello/{me,you,everyone})
Hello me!Hello you!Hello everyone!

real	0m3.136s
user	0m0.050s
sys	0m0.013s
```

## Going deeper with sam logs

SAM CLI can show function execution logs, which provide additional timing information. In a **separate** terminal, run:

```shell
$ sam logs --region us-east-1 --stack-name hello-app --name HelloWorldFunction
```

The logs display – possibly after a few seconds - something similar to the following simplified output:

```text
... 2020-06-30T15:27:57.463000 START RequestId: ... Version: $LATEST
... 2020-06-30T15:27:58.161000 END RequestId: ...
... 2020-06-30T15:27:58.161000 REPORT RequestId: ...	Duration: 697.81 ms	Billed Duration: 700 ms	Memory Size: 256 MB	Max Memory Used: 102 MB	Init Duration: 925.10 ms	
... 2020-06-30T15:27:58.347000 START RequestId: ... Version: $LATEST
... 2020-06-30T15:27:58.362000 END RequestId: ...
... 2020-06-30T15:27:58.362000 REPORT RequestId: ...	Duration: 11.47 ms	Billed Duration: 100 ms	Memory Size: 256 MB	Max Memory Used: 102 MB	
... 2020-06-30T15:27:58.560000 START RequestId: ... Version: $LATEST
... 2020-06-30T15:27:58.566000 END RequestId: ...
... 2020-06-30T15:27:58.566000 REPORT RequestId: ...	Duration: 3.04 ms	Billed Duration: 100 ms	Memory Size: 256 MB	Max Memory Used: 102 MB	
```

Important statistics:

- Time spent in Lambda = Init Duration: 925.10 ms + Duration: 697.81 ms + Duration: 11.47 ms + Duration: 3.04 ms = 1637.42 ms
- Time spent overall = 3.136s s = 3136 ms
- Unaccounted time = 3136 ms - 1637.42 ms = 1498.58 ms, of which
  - approx. 600 ms is probably due to network latency (100 ms each way x 3 requests)
  - approx. 900 ms is as yet unexplained

Having this log output at hand allows us to draw a few conclusions:

- The QuantumMaid overhead is highest upon first invocation, and stabilizes to a low value from the second request onwards.
- The network latency is quite high (200 ms per request). Maybe we can switch to an edge-optimized API.
- If performance is important, 900 ms is still unaccounted for and needs investigation. It could be TLS negotiation, or something else.
- We can save money by reducing `MemorySize` in `template.yml` from 256 MB to something closer to the maximum reported memory usage (102 MB).

You now have the necessary building blocks to make your QuantumMaid code AWS Lambda capable,
and to get information about its runtime characteristics, for further tweaking.

Next, we are going to clean up the resources we created for this tutorial, so as not to incur any additional (unwanted) costs.

<!---[Nav]-->

[&larr;](04_DeployingOurFunction.md)&nbsp;&nbsp;&nbsp;[Overview](README.md)&nbsp;&nbsp;&nbsp;[&rarr;](06_CleaningUp.md)
