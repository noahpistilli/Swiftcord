@testable import Swiftcord
import XCTest

final class SwiftCordTests: XCTestCase {
    /// Sets up the `Swiftcord` object needed across functions
    func setUpBot() -> Swiftcord {
        let bot = Swiftcord(token: "")
        bot.setIntents(intents: .guilds, .guildMessages)
        
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
        
        bot.on(.messageCreate) { data in
            let msg = data as! Message
            
            if msg.content == "+test" {
                msg.reply(with: "Testing Swiftcord!")
            }
        }
        
        bot.connect()
    }
    
    func testSendEmbed() {
        let bot = self.setUpBot()
        
        bot.on(.messageCreate) { data in
            let msg = data as! Message
            
            if msg.content == "+test" {
                let embed = EmbedBuilder()
                    .setTitle(title: "Swiftcord Embed")
                    .setDescription(description: "This embed shows off the embed")
                    .addField("Field", value: "A field")
                    .setFooter(text: "Created in Swiftcord")
                    .setTimestamp()
                
                msg.reply(with: embed)
            }
        }
        
        bot.connect()
    }
}
