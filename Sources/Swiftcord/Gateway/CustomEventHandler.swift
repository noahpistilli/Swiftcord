//
//  CustomEventHandler.swift
//  
//
//  Created by Noah Pistilli on 2022-06-30.
//

import Foundation

/// Allows for the manipulation of the payload recieved on Gateway events.
/// This can be used to access fields in the payload JSON that Swiftcord may not handle,
/// or to change the way an event is handled. An example is Swiftlink, which requires the
/// 
open class CustomGatewayEventHandler {
    open func onChannelCreate(_ swiftcord: Swiftcord, _ payload: [String : Any]) async {
        for listener in swiftcord.listenerAdaptors {
            switch payload["type"] as! Int {
            case 0:
                let channel = GuildText(swiftcord, payload)
                await listener.onChannelCreate(event: channel)

            case 1:
                let dm = DM(swiftcord, payload)
                await listener.onChannelCreate(event: dm)

            case 2:
                let channel = GuildVoice(swiftcord, payload)
                await listener.onVoiceChannelCreate(event: channel)

            case 3:
                let group = GroupDM(swiftcord, payload)
                await listener.onChannelCreate(event: group)

            case 4:
                let category = GuildCategory(swiftcord, payload)
                await listener.onCategoryCreate(event: category)

            default: return
            }
        }
    }
    
    open func onChannelDelete(_ swiftcord: Swiftcord, _ payload: [String : Any]) async {
        let type = payload["type"] as! Int
        
        for listener in swiftcord.listenerAdaptors {
            switch type {
            case 0, 2, 4:
                let guildId = Snowflake(payload["guild_id"])!
                guard let guild = swiftcord.guilds[guildId] else {
                    return
                }

                let channelId = Snowflake(payload["id"])!
                guard guild.channels.removeValue(forKey: channelId) != nil else {
                    return
                }

                // We made the case this broad so we can remove from our cache. We must now pass the proper type to the ListenerAdapter
                if type == 0 {
                    // Text
                    await listener.onChannelDelete(event: GuildText(swiftcord, payload))
                } else if type == 2 {
                    // Voice
                    await listener.onVoiceChannelDelete(event: GuildVoice(swiftcord, payload))
                } else {
                    // Category
                    await listener.onCategoryDelete(event: GuildCategory(swiftcord, payload))
                }

            case 1:
                let recipient = (payload["recipients"] as! [[String: Any]])[0]
                let userId = Snowflake(recipient["id"])!
                guard let dm = swiftcord.dms.removeValue(forKey: userId) else {
                    return
                }
                await listener.onChannelDelete(event: dm)

            case 3:
                let channelId = Snowflake(payload["id"])!
                guard let group = swiftcord.groups.removeValue(forKey: channelId) else {
                    return
                }
                await listener.onChannelDelete(event: group)

            default: return
            }
        }
    }
    
    open func onChannelPinsUpdate(_ swiftcord: Swiftcord, _ payload: [String : Any]) async {
        let channelId = Snowflake(payload["channel_id"])!
        let timestamp = payload["last_pin_timestamp"] as? String
        guard let channel = swiftcord.getChannel(for: channelId) else {
            return
        }

        for listener in swiftcord.listenerAdaptors {
            await listener.onChannelPinUpdate(event: channel, lastPin: timestamp?.date)
        }
    }
    
    open func onMessageCreate(_ swiftcord: Swiftcord, _ payload: [String : Any]) async {
        let msg = Message(swiftcord, payload)

        if let channel = msg.channel as? GuildText {
            channel.lastMessageId = msg.id
        }
        
        for listener in swiftcord.listenerAdaptors {
            await listener.onMessageCreate(event: msg)
        }
    }
    
    open func onVoiceStateUpdate(_ swiftcord: Swiftcord, _ payload: [String : Any]) async {
        let guildId = Snowflake(payload["guild_id"])!
        guard let guild = swiftcord.guilds[guildId] else {
            return
        }
        let channelId = Snowflake(payload["channel_id"])
        let userId = Snowflake(payload["user_id"])!

        for listener in swiftcord.listenerAdaptors {
            if channelId != nil {
                let voiceState = VoiceState(payload)

                guild.voiceStates[userId] = voiceState
                guild.members[userId]?.voiceState = voiceState

                await listener.onVoiceChannelJoin(userId: userId, state: voiceState)
            } else {
                guild.voiceStates.removeValue(forKey: userId)
                guild.members[userId]?.voiceState = nil

                await listener.onVoiceChannelLeave(userId: userId)
            }
        }
    }
    
    open func onVoiceServerUpdate(_ swiftcord: Swiftcord, _ payload: [String : Any]) async {
        var sessionId = ""
        var shard: Shard!
        
        for guildShard in swiftcord.shardManager.shards where shard.id == swiftcord.getShard(for: Snowflake(payload["guild_id"])!) {
            shard = guildShard
            sessionId = guildShard.sessionId!
        }
        
        do {
            let voiceClient = try VoiceClient(
                swiftcord,
                gatewayUrl: "wss://\(payload["endpoint"] as! String)",
                token: payload["token"] as! String,
                guildId: Snowflake(payload["guild_id"])!,
                sessionId: sessionId,
                eventLoopGroup: shard.eventLoopGroup
            )
            
            // Start the voice client.
            await voiceClient.start()
        } catch {
            swiftcord.error("No suitable networking interface found. Swiftcord cannot start the voice client without one.")
        }
    
        // We cannot dispatch the VoiceClient to the user quite yet.
    }
}

public class DefaultGatewayEventHandler: CustomGatewayEventHandler { public override init() {}}
