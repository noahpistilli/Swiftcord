import Swiftcord

class MessageListener: ListenerAdapter {
    override func onMessageCreate(event: Message) async {
        if event.content == "+test" {
            _ = try! await event.reply(with: "Testing Swiftcord!")
        }
    }
}

let bot = Swiftcord(token: "token")
bot.setIntents(intents: .guildMessages)

let activity = Activities(name: "with Swiftcord", type: .playing)
bot.editStatus(status: .online, activity: activity)

bot.addListeners(MessageListener())

bot.connect()
