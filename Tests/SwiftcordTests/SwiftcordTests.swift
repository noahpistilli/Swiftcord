@testable import Swiftcord
import XCTest

final class SwiftCordTests: XCTestCase {
    class TestMessageSend: ListenerAdapter {
        override func onMessageCreate(event: Message) async {
            if event.content == "+test" {
                let msg = try! await event.reply(with: "Testing Swiftcord!")
                // Do whatever you want with the message object
                sleep(2)
                try! await msg!.delete()
            }
        }
    }
    
    class TestEmbedSend: ListenerAdapter {
        override func onMessageCreate(event: Message) async {
            if event.content == "+embed" {
                let embed = EmbedBuilder()
                    .setTitle(title: "Swiftcord Embed")
                    .setDescription(description: "This embed shows off the embed")
                    .addField("Field", value: "A field")
                    .setFooter(text: "Created in Swiftcord")
                    .setTimestamp()
                
                let _ = try! await event.reply(with: embed)
                // Again, do whatever you want with the message object
            }
        }
    }
    
    /// Sets up the `Swiftcord` object needed across functions
    func setUpBot() -> Swiftcord {
        let bot = Swiftcord(token: "")
        bot.setIntents(intents: .guildMessages)
        
        let activity = Activities(name: "WiiLink Championships", type: .competing)

        bot.editStatus(status: .online, activity: activity)
        return bot
    }
    
    func testStartBot() {
        let bot = self.setUpBot()
        
        bot.connect()
    }
    
    func testMessageCommand() {
        let bot = self.setUpBot()
        bot.addListeners(TestMessageSend())
        
        bot.connect()
    }
    
    func testSendEmbed() {
        let bot = self.setUpBot()
        bot.addListeners(TestEmbedSend())
                
        bot.connect()
    }
}
