# Making WebSockets manageable with Kotlin & Sealed Classes

This tutorial will walk you through the steps to create an interactive web application based on WebSockets in Kotlin.
The application will implement a simple multi-user chat and will be based on the QuantumMaid application framework.

## Prerequisites

To complete this guide, you need:

- less than 15 minutes
- an IDE
- JDK 1.8+ installed with JAVA_HOME configured appropriately
- Apache Maven 3.6.2+

## Architecture

In this guide, we create a straightforward chat application using WebSockets to receive and send messages to the other connected users.


## Handling web sockets

Our application contains a single class that handles the web sockets. Create the `org.acme.websockets.ChatSocket` class in the
`src/main/java` directory. Copy the following content into the created file:


## The protocol
We start by defining a simple protocol for the communication between the clients and the server.
We will use Kotlin sealed classes for this:
<!---[CodeSnippet](protocol)-->
```kotlin
sealed class ClientToServerMessage

data class ConnectCommand(val username: String, val id: String) : ClientToServerMessage()
data class NewMessageCommand(val content: String, val id: String) : ClientToServerMessage()

sealed class ServerToClientMessage

data class UserJoined(val username: String, val id: String) : ServerToClientMessage()
data class NewMessage(val content: String, val id: String) : ServerToClientMessage()
```

Next we will define a class that can handle incoming WebSocket message of type `ClientToServerMessage`:
<!---[CodeSnippet](websocketsusecase)-->
```kotlin
class ChatUseCase {

    fun handleCommand(command: ClientToServerMessage, announcer: Announcer) {
        val announcement = when (command) {
            is ConnectCommand -> UserJoined(command.username, "foo")
            is NewMessageCommand -> NewMessage(command.content, "foo")
        }
        announcer.announce(announcement)
    }
}
```
As you can see, the server will send a `UserJoined` message whenever a new client connects
and `NewMessage` message whenever a client publishes a new chat message.
To send outgoing WebSocket messages back to the clients, the `ChatUseCase` uses an `Announcer`.
We need to create it as an interface:

<!---[CodeSnippet](backchannelinterface)-->
```kotlin
interface Announcer {
    fun announce(message: ServerToClientMessage)
}
```

Finally, we can bind all these components to actual WebSockets technology using
QuantumMaid:

<!---[CodeSnippet](websocketsinfra)-->
```kotlin
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
```

➊ Serving the web frontend on `/`.

➋ Delegating incoming websocket messages to the `ChatUseCase` class.

➌ Telling QuantumMaid that `Announcer` is supposed to send outgoing messages of type `ServerToClientMessage`.

➍ Telling QuantumMaid how to instantiate the `Announcer` interface. It will be created on as an anonymous object.

➎ Each outgoing messaging will be sent to all open websocket connections.

➏ We are using [Undertow](http://undertow.io/) to serve the application. 

## Adding a web frontend
To fully experience the chat application, we need a web frontend.
Download the ... file and copy it to `/.../index.html`

## Run the application
You can run the application now by executing the `main()` method.

<!---[CodeSnippet](websocketsmain)-->
```kotlin
fun main() {
    setUpInfrastructure(8080)
}
```

Then open your 2 browser windows to http://localhost:8080/:

- Enter a name in the top text area (use 2 different names).
- Click on connect
- Send and receive messages

## Application

As usual, the application can be packaged using ./mvnw clean package and executed using the -runner.jar file. You can also build the native executable using ./mvnw package -Pnative.

You can also test your web socket applications using the approach detailed here.
