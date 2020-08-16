This file's only purpose is to cause `mvn package` to create the target/classes.

Otherwise the 'sam build' step of `mvn verify` will fail with the error:

```text
[INFO]      [exec] Error: JavaMavenWorkflow:MavenCopyArtifacts - Required target/classes directory was not produced from 'mvn package'
```
