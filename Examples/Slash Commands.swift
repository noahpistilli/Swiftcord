import Sword

let bot = Shield(token: "Super secret token here")

bot.setIntents(intents: .guilds)

// Create slash command
// NOTE: This creates a guild only slash command. When we do support global slash commands, you can call the Sword instance
let command = SlashCommandBuilder(name: "test", description: "Testing slash commands in Sword")
    .addOption(option: ApplicationCommandOptions(name: "user", description: "User to select", type: .user))

bot.guilds[guildId].uploadSlashCommand(commandData: slashBuilder)

// Listen for slash commands
bot.on(.slashCommandEvent) { data in
  var event = data as! SlashCommandEvent
                            
  if event.name == "test" {
      // If the command may take a while to complete, we can make the bot display the `is thinking...` text
      // It returns a ResponseError in the closure which should never really be needed
      event.deferReply { _ in }
                            
      // If we would like to only allow the user who invoked the command to see the output, we can set ephemeral
      event.setEphemeral(isEphermeral: true)
  
      // Retriving options is extremely simple! 
      // For Boolean: event.getOptionAsBool(optionName: "optionName") NOTE: You will need to cast the `Channel` type to the channel type you want.
      // For Channels: event.getOptionAsChannel(optionName: "optionName")
      // For Double: event.getOptionAsDouble(optionName: "optionName")
      // For Integer: event.getOptionAsInt(optionName: "optionName")
      // For Member: event.getOptionAsMember(optionName: "optionName")
      // For String: event.getOptionAsString(optionName: "optionName")
      // For Role: event.getOptionAsRole(optionName: "optionName")
      // For User: event.getOptionAsUser(optionName: "optionName")
      let selectedUser = event.getOptionAsUser(optionName: "user")!.username!
                            
      // Sending messages are simple as well!
      // All InteractionEvent types have the same functions for sending, editing and deleting messages.
      // For sending a normal message: event.reply(message: "message")
      // For sending an embed(s): event.replyEmbeds(embeds: embedBuilderVar, embedBuilderVar2). You can also pass an `[EmbedBuilder]` type
      // For sending a message with buttons: event.replyButtons(buttons: buttonBuilderVar)
      // For sending a message with a select menu: event.replySelectMenu(menu: selectMenuBuilderVar) 
      event.reply(message: "User \(invokedUser) was selected!")
  }
}
