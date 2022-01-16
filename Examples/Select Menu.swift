import Sword

let bot = Sword(token: "Super secret token here")

bot.setIntents(intents: .guilds, .guildMessages)

bot.on(.messageCreate) { data in
  let msg = data as! Message
                        
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
}

// Now we listen for the event
bot.on(.selectBoxEvent) { data in
    var box = data as! SelectMenuEvent
                         
    // If the command may take a while to complete, we can make the bot display the `is thinking...` text
    // It returns a ResponseError in the closure which should never really be needed
    event.deferReply { _ in }
                            
    // If we would like to only allow the user who invoked the command to see the output, we can set ephemeral
    event.setEphemeral(isEphermeral: true)
    
    // First we check if the selected option is in the SelectMenu we would like to respond to
    if box.selectedValue.customId == "test" {
        // Now we check for the actual selected option
        if box.selectedValue.value == "test_section" {
            box.reply(message: "We interacted with a select menu!")
        }
    }
}

bot.connect()
