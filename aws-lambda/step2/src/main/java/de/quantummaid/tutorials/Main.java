/*
 * Copyright (c) 2020 Richard Hauswald - https://quantummaid.de/.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package de.quantummaid.tutorials;

//Showcase start step2AdapterDeclaration1
import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;
import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;
//Showcase end step2AdapterDeclaration1
import de.quantummaid.quantummaid.QuantumMaid;

import java.util.Map;

//Showcase start step2AdapterDeclaration2
public final class Main {
  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(quantumMaidConfig().httpMaid());
  //...
  //Showcase end step2AdapterDeclaration2

  private Main() {}

  //Showcase start step2RequestHandlingMethod
  public Map<String, Object> handleRequest(final Map<String, Object> request) {
    return ADAPTER.delegate(request);
  }
  //Showcase end step2RequestHandlingMethod

  //Showcase start step2HttpMaidConfig
  private static QuantumMaid quantumMaidConfig() {
    final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
        .get("/helloworld", (request, response) -> response.setBody("Hello World!"));
    return quantumMaid;
  }
  //Showcase end step2HttpMaidConfig

  public static void main(final String[] args) {
    final int port = 8080;
    quantumMaidConfig().withLocalHostEndpointOnPort(port).runAsynchronously();
  }
}
