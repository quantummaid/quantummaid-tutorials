package de.quantummaid.tutorials;

import de.quantummaid.httpmaid.HttpMaid;

public final class WebService {

    private WebService() {
    }

    public static void main(final String[] args) {
        HttpMaid.anHttpMaid()
                .get("/hello", GreetingUseCase.class)
                .build();
    }
}
