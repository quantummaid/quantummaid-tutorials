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

package de.quantummaid.tutorials.basic.step4;

import javax.inject.Inject;

//Showcase start usecase3
public final class GreetingUseCase {
    private final GreetingLogger greetingLogger;

    @Inject
    public GreetingUseCase(final GreetingLogger greetingLogger) {
        this.greetingLogger = greetingLogger;
    }

    public String hello(final String name) {
        greetingLogger.logGreeting(name);
        return "hello " + name;
    }
}
//Showcase end usecase3
