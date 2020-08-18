package de.quantummaid.tutorials

import de.quantummaid.httpmaid.HttpMaid
import de.quantummaid.httpmaid.handler.http.HttpHandler
import de.quantummaid.httpmaid.undertow.UndertowEndpoint

//Showcase start websocketsinfra
fun setUpInfrastructure(port: Int) {
    val httpMaid = HttpMaid.anHttpMaid()
            .get("/", HttpHandler { _, response -> response.setJavaResourceAsBody("index.html") }) // ➊
            .websocket(ChatUseCase::class.java) // ➋
            .broadcastToWebsocketsUsing(Announcer::class.java, ServerToClientMessage::class.java) { // ➌
                object : Announcer { // ➍
                    override fun announce(message: ServerToClientMessage) {
                        it.sendToAll(message) // ➎
                    }
                }
            }
            .build()
    UndertowEndpoint.startUndertowEndpoint(httpMaid, port) // ➏
}
//Showcase end websocketsinfra

//Showcase start websocketsmain
fun main() {
    setUpInfrastructure(8080)
}
//Showcase end websocketsmain