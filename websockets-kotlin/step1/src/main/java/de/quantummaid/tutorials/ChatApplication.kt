package de.quantummaid.tutorials

//Showcase start protocol
sealed class ClientToServerMessage

data class ConnectCommand(val username: String, val id: String) : ClientToServerMessage()
data class NewMessageCommand(val content: String, val id: String) : ClientToServerMessage()

sealed class ServerToClientMessage

data class UserJoined(val username: String, val id: String) : ServerToClientMessage()
data class NewMessage(val content: String, val id: String) : ServerToClientMessage()
//Showcase end protocol

//Showcase start backchannelinterface
interface Announcer {
    fun announce(message: ServerToClientMessage)
}
//Showcase end backchannelinterface

//Showcase start websocketsusecase
class ChatUseCase {

    fun handleCommand(command: ClientToServerMessage, announcer: Announcer) {
        val announcement = when (command) {
            is ConnectCommand -> UserJoined(command.username, "foo")
            is NewMessageCommand -> NewMessage(command.content, "foo")
        }
        announcer.announce(announcement)
    }
}
//Showcase end websocketsusecase
