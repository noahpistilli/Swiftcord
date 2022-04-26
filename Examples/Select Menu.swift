import Swiftcord

class SelectMenuListener: ListenerAdapter {
    override func onMessageCreate(event: Message) async {
        if event.content == "+menu" {
            // You can send multiple Select Menu's by calling .addComponent again.
            // customID is the ID for the entire SelectMenu object, while value is the customID for that selection.
            let menu = SelectMenuBuilder(message: "Testing Select Menu's in Sword!")
                      .addComponent(component: ActionRow(components:
                                                          SelectMenu(
                                                              customId: "test",
                                                              placeholder: "Test 1",
                                                              options: SelectMenuOptions(
                                                                  label: "Testing with Sword",
                                                                  value: "test_section",
                                                                  description: "We are testing a select menu with Sword"))
                                                        )
                      )
            
            try! await event.reply(with: menu)
        }
    }
    
    override func onSelectMenuEvent(event: SelectMenuEvent) {
        // If the command may take a while to complete, we can make the bot display the `is thinking...` text
        // It returns a ResponseError in the closure which should never really be needed
        event.deferReply()

        // If we would like to only allow the user who invoked the command to see the output, we can set ephemeral
        event.setEphemeral(true)

        // First we check if the selected option is in the SelectMenu we would like to respond to
        if event.selectedValue.customId == "test" {
            // Now we check for the actual selected option
            if event.selectedValue.value == "test_section" {
                try! await event.reply(message: "We interacted with a select menu!")
            }
        }
    }
}

let bot = Swiftcord(token: "token")

bot.setIntents(intents: .guildMessages)
bot.addListeners(SelectMenuListener())

bot.connect()
