# Sword - A Discord Library for Swift

[![Swift Version](https://img.shields.io/badge/Swift-5.3-orange.svg?style=flat-square)](https://swift.org) [![Tag](https://img.shields.io/github/tag/Azoy/Sword.svg?style=flat-square&label=release&colorB=)](https://github.com/Azoy/Sword/releases)

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
        .package(url: "https://github.com/SketchMaster2001/Sword", .branch("master"))
    ],
    targets: [
      .target(
        name: "yourswiftexecutablehere",
        dependencies: ["Sword"]
      )
    ]
)
```

After that, open Sources/main.swift and remove everything and replace it with the example below.

```swift
import Sword

let bot = Sword(token: "Your bot token here")

// Set activity if wanted
let activity = Activities(name: "with Sword!", type: .playing)
bot.editStatus(status: .online, activity: activity)

// Set intents which are required
bot.setIntents(intents: .guildMessages)

bot.on(.messageCreate) { data in
  let msg = data as! Message

  if msg.content == "!ping" {
    msg.reply(with: "Pong!")
  }
}

bot.connect()
```
For more examples, look in the examples folder or in the Wiki.


## Running the bot (SPM)
First make sure you are in the directory with the `Package.swift` file. To build the executable, run `swift build`. To build the executable and run it immediately, run `swift run`

## Running the bot in Xcode (SPM)
To run the bot in Xcode, all you need to do is open the directory the `Package.swift` file is located in Xcode. Click the play button at the top left corner and it will run!

Then click the play button!

## Links
The documentation for this repo is out of date due to jazzy not working on my computer. You can still use Azoy's site below to access documentation for pretty much everything except for interactions and message components.

[Pre-v9 Documentation](https://azoy.github.io/Sword/) - (created with [Jazzy](https://github.com/Realm/Jazzy))
