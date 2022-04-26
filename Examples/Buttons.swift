import Swiftcord

class Buttons: ListenerAdapter {
    override func onMessageCreate(event: Message) async {
        if event.content == "+button" {
            let buttonBuilder = ButtonBuilder(message: "testing buttons with Swiftcord!")
                      // Emojis are optional.
                      .addComponent(component: ActionRow(components: Button(customId: "test", style: .green, label: "Button with Emoji", emoji: Emoji("🎟️"))))
                      // To add another action row, call add component. Remember that Discord allows up to 5 action rows in 1 message
                      // You can have multiple buttons in 1 action row by making a `Button` struct as many times as needed.
                      .addComponent(component: ActionRow(components: Button(
                                                           customId: "test_2",
                                                           style: .blurple,
                                                           label: "Blurple Button"
                                                         ),
                                                         Button(
                                                           customId: "test_3",
                                                           style: .red,
                                                           lable: "Danger!"
                                                        )))

            event.reply(with: buttonBuilder)
        }
    }
    
    override func onButtonClickEvent(event: ButtonEvent) async {
        // If the command may take a while to complete, we can make the bot display the `is thinking...` text
        event.deferReply()

        // If we would like to only allow the user who invoked the command to see the output, we can set ephemeral
        event.setEphemeral(true)

        if button.selectedButton.customId == "test" {
            try! await event.reply(message: "Test button was clicked!")
        } else if button.selectedButton.customId == "test_2" {
            try! await event.reply(message: "Blurple button was clicked!")
        } else if button.selectedButton.customId == "test_3" {
            try! await event.reply(message: "Stranger Danger!")
        }
    }
}

let bot = Swiftcord(token: "token")

bot.setIntents(intents: .guildMessages)
bot.addListeners(Buttons())

bot.connect()
