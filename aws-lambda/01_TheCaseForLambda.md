# The case for QuantumMaid + AWS Lambda

## Why AWS Lambda?

AWS Lambda has been a big deal since it was introduced back in 2014. With Lamba, there is no need to provision stateful
servers such as Docker containers or virtual machine instances. These incur hourly
charges whether they serve requests or not.

Lambda only incurs charges when requests are served, if at all.

The AWS Free Tier is relatively generous:
- The first **monthly** 1.000.000 requests and 400.000 GB-seconds in AWS Lambda are **free forever**.
- The first 5 GB of storage in AWS S3 are free for the first 12 months following your AWS account creation.

So this tutorial will most likely cost you nothing if you're a new or casual AWS user. Be sure, however, to not skip the <!---[Link](06_CleaningUp.md "final cleanup section")-->
[final cleanup section](06_CleaningUp.md) when you're done with this tutorial.

## Why QuantumMaid + AWS Lambda?

The Lambda function created in this tutorial contains <!---[Link](step4/src/main/java/de/quantummaid/tutorials/Main.java "very little user code")-->
[very little user code](step4/src/main/java/de/quantummaid/tutorials/Main.java).
Its execution mostly gauges QuantumMaid libraries' initialization and invocation overhead.

This, in turn, allows the QuantumMaid team to run [automated tests](itests/src/test/scripts) on it whenever new versions are released.
Regressions on size and performance characteristics are therefore caught and remediated early.

This means that QuantumMaid users can rely on those characteristics, knowing that they will hold true, or even improve, but not regress, in future. At present, the following holds true for the Lambda function we'll create in this tutorial:

- It has a code size of less than 1.4 M (<!---[Link](itests/src/test/scripts/jar-tests.sh "source")-->
[source](itests/src/test/scripts/jar-tests.sh))
- Its first (cold) invocation duration is less than 1.55 s (<!---[Link](itests/src/test/scripts/restapi-tests.sh  "source")-->
[source](itests/src/test/scripts/restapi-tests.sh))
- From the second invocation onwards, the invocation duration is less than 14 ms (<!---[Link](itests/src/test/scripts/restapi-tests.sh  "source")-->
[source](itests/src/test/scripts/restapi-tests.sh))
Next, we'll create the basic function.

<!---[Nav]-->
[Overview](README.md)&nbsp;&nbsp;&nbsp;[&rarr;](02_MinimumViableFunction.md)