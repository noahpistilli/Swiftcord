//
//  GroupChannel.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

/// GroupDM Type
public struct GroupDM: TextChannel {

  // MARK: Properties

  /// Parent class
  public internal(set) weak var swiftcord: Swiftcord?

  /// ID of DM
  public let id: Snowflake

  /// The recipient of this DM
  public internal(set) var recipients = [User]()

  /// The last message's ID
  public let lastMessageId: Snowflake?

  /// Indicates what kind of channel this is
  public let type = ChannelType.groupDM

  // MARK: Initializer

  /**
   Creates a GroupChannel struct

   - parameter swiftcord: Parent class
   - parameter json: JSON representable as a dictionary
   */
  init(_ swiftcord: Swiftcord, _ json: [String: Any]) {
    self.swiftcord = swiftcord

    self.id = Snowflake(json["id"])!

    let recipients = json["recipients"] as! [[String: Any]]
    for recipient in recipients {
      self.recipients.append(User(swiftcord, recipient))
    }

    self.lastMessageId = Snowflake(json["last_message_id"])

    swiftcord.groups[self.id] = self
  }

}
