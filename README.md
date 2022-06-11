[![Swift Version](https://img.shields.io/badge/Swift-5.3-orange.svg?style=flat-square)](https://swift.org) 
[![Tag](https://img.shields.io/github/tag/Azoy/Sword.svg?style=flat-square&label=release&colorB=)](https://github.com/Azoy/Sword/releases)

<img align="right" src="https://cdn.discordapp.com/attachments/750623609810190348/934989484561403925/swiftcord3.png" height="200" width="200">

# Swiftcord - A Discord Library for Swift

## Requirements
1. macOS, Linux, iOS, watchOS, tvOS (no voice for iOS, watchOS, or tvOS)
2. At least Swift 5.3

## Adding Sword
### Swift Package Manager
In order to add Sword as a dependency, you must first create a Swift executable in a designated folder, like so `swift package init --type executable`. Then in the newly created Package.swift, open it and add Sword as a dependency

```swift
// swift-tools-version: 5.3

import PackageDescription

let package = Package(
    name: "yourswiftexecutablehere",
    dependencies: [
        .package(url: "https://github.com/SketchMaster2001/Swiftcord", .branch("master"))
    ],
    targets: [
      .target(
        name: "yourswiftexecutablehere",
        dependencies: ["Swiftcord"]
      )
    ]
)
```

After that, open Sources/main.swift and remove everything and replace it with the example below.

```swift
import Swiftcord

let bot = Swiftcord(token: "Your bot token here")

// Set activity if wanted
let activity = Activities(name: "with Swiftcord!", type: .playing)
bot.editStatus(status: .online, activity: activity)

// Set intents which are required
bot.setIntents(intents: .guildMessages)

class MyBot: ListenerAdapter {
  override func onMessageCreate(event: Message) async {
    if msg.content == "!ping" {
      try! await msg.reply(with: "Pong!")
    }
  }
}

bot.addListeners(MyBot())
bot.connect()
```
For more examples, look in the examples folder or in the Wiki.


## Running the bot (SPM)
First make sure you are in the directory with the `Package.swift` file. To build the executable, run `swift build`. To build the executable and run it immediately, run `swift run`

## Running the bot in Xcode (SPM)
To run the bot in Xcode, all you need to do is open the directory the `Package.swift` file is located in Xcode. Click the play button at the top left corner and it will run!

Then click the play button!

## Links
[Documentation](https://sketchmaster2001.github.io/Swiftcord) - Created using Apple [docc](https://github.com/apple/swift-docc) and converted to HTML with [docc2html](https://github.com/DoccZz/docc2html)

[Swiftcord Discord server](https://discord.gg/cE2Cpn4r9X)
