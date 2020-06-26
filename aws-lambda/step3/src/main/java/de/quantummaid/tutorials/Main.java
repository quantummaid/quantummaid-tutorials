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

import de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint;
import de.quantummaid.quantummaid.QuantumMaid;

import java.util.Map;

import static de.quantummaid.httpmaid.awslambda.AwsLambdaEndpoint.awsLambdaEndpointFor;

public final class Main {
  private static final AwsLambdaEndpoint ADAPTER = awsLambdaEndpointFor(quantumMaidConfig().httpMaid());

  public Main() {}

  public Map<String, Object> handleRequest(final Map<String, Object> request) {
    System.err.println(request.toString());
    return ADAPTER.delegate(request);
  }

  private static QuantumMaid quantumMaidConfig() {
    final QuantumMaid quantumMaid = QuantumMaid.quantumMaid()
        .get("/hello/<whoever-you-are>", (request, response) -> response.setBody(
            String.format("Hello %s!",
                request.pathParameters().getPathParameter("whoever-you-are"))));
    return quantumMaid;
  }

  public static void main(final String[] args) {
    final int port = 8080;
    quantumMaidConfig().withLocalHostEndpointOnPort(port).runAsynchronously();
  }
}
