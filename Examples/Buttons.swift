import Sword

let bot = Sword(token: "Super secret token here")

bot.setIntents(intents: .guilds)

// Create our button(s)
bot.on(.messageCreate) { data in
    let msg = data as! Message
                        
    if msg.content == "+button" {
      let buttonBuilder = ButtonBuilder(message: "testing buttons with Sword!")
                // Emojis are optional. 
                .addComponent(component: ActionRow(components: Button(customId: "test", style: .green, label: "Button with Emoji", emoji: Emoji("🎟️"))))
                // To add another action row, call add component. Remember that Discord allows up to 5 action rows in 1 message
                // You can have multiple buttons in 1 action row by making a `Button` struct as many times as needed.
                .addComponent(component: ActionRow(components: 
                                                   Button(
                                                     customId: "test_2",
                                                     style: .blurple,
                                                     label: "Blurple Button"
                                                   ),
                                                   Button(
                                                     customId: "test_3",
                                                     style: .red,
                                                     lable: "Danger!"
                                                  )))
      
      msg.reply(with: buttonBuilder)
                                                   
    }
}

// Now listen for the button clicks
bot.on(.buttonEvent) { data in
    var button = data as! ButtonEvent
                      
      // If the command may take a while to complete, we can make the bot display the `is thinking...` text
      // It returns a ResponseError in the closure which should never really be needed
      event.deferReply { _ in }
                            
      // If we would like to only allow the user who invoked the command to see the output, we can set ephemeral
      event.setEphemeral(isEphermeral: true)
                      
      if button.selectedButton.customId == "test" {
          button.reply(message: "Test button was clicked!")
      }
      else if button.selectedButton.customId == "test_2" {
          button.reply(message: "Blurple button was clicked!")
      }        
      else if button.selectedButton.customId == "test_3" {
          button.reply(message: "Stranger Danger!")
      }         
}

bot.connect()
