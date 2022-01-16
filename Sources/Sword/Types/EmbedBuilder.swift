//
//  EmbedBuilder.swift
//  Sword
//
//  Created by Noah Pistilli on 2021-12-19.
//

import Foundation

public class EmbedBuilder: Encodable {
    /// Author dictionary from embed
    public var author: Author?
  
    /// Side panel color of embed
    public var color: Int?
  
    /// Description of the embed
    public var description: String?
  
    /// Fields for the embed
    public var fields: [Field]?
  
    /// Footer dictionary from embed
    public var footer: Footer?
  
    /// Image data from embed
    public var image: Image?
    
    /// Thumbnail data from embed
    public var thumbnail: Thumbnail?
  
    /// Title of the embed
    public var title: String?
  
    /// Type of embed | Discord says this should be considered deprecated. As such we set as rich
    public var type: String
  
    /// URL of the embed
    public var url: String?
  
    /// Video data from embed
    public var video: Video?
    
    // MARK: Initializers
    
    /// Creates an Embed Structure
    public init() {
      self.type = "rich"
      self.video = nil
    }
    
    // MARK: Functions
    
    /**
     Adds a field to the embed
     
     - parameter name: Name to give field
     - parameter value: Text that will be displayed underneath name
     - parameter inline: Whether or not to keep this field inline with others
    */
    public func addField(
      _ name: String,
      value: String,
      isInline: Bool = false
    ) -> Self {
      if self.fields == nil {
        self.fields = [Field]()
      }
      
      self.fields?.append(Field(name: name, value: value, isInline: isInline))
        
        return self
    }
    
    public func setTitle(title: String) -> Self {
        self.title = title
        return self
    }
    
    public func setDescription(description: String) -> Self {
        self.description = description
        return self
    }
    
    public func setColor(color: Int) -> Self {
        self.color = color
        return self
    }
    
    public func setFooter(text: String, url: String? = nil) -> Self {
        let footer = Footer(text: text, iconUrl: url)
        self.footer = footer
        
        return self
    }
    
    public func setImage(
        url: String,
        height: Int? = nil,
        width: Int? = nil
    ) -> Self {
        let image = Image(url: url, height: height, width: width)
        self.image = image
        
        return self
    }
    
    public func setThumbnail(
        url: String,
        height: Int? = nil,
        width: Int? = nil
    ) -> Self {
        let thumbnail = Thumbnail(url: url, height: height, width: width)
        self.thumbnail = thumbnail
        
        return self
    }
    
    public func setVideo(
        url: String,
        height: Int? = nil,
        width: Int? = nil
    ) -> Self {
        let video = Video(url: url, height: height, width: width)
        self.video = video
        
        return self
    }
    
    public func setAuthor(
        name: String,
        url: String? = nil,
        iconUrl: String? = nil
    ) -> Self {
        let author = Author(iconUrl: iconUrl, name: name, url: url)
        self.author = author
        
        return self
    }
}

extension EmbedBuilder {
    public struct Author: Encodable {
        public var iconUrl: String?
        public var name: String
        public var url: String?
        
        public init(iconUrl: String? = nil, name: String, url: String? = nil) {
          self.iconUrl = iconUrl
          self.name = name
          self.url = url
        }
    }
    
    public struct Field: Encodable {
        public var name: String
        public var value: String
        public var isInline: Bool
        
        public init(name: String = "", value: String = "", isInline: Bool = true) {
            self.name = name
            self.value = value
            self.isInline = isInline
        }
    }
    
    public struct Footer: Encodable {
        public var iconUrl: String?
        public var text: String
        
        public init(
          text: String,
          iconUrl: String? = nil
        ) {
          self.text = text
          self.iconUrl = iconUrl
        }
    }
    
    public struct Image: Encodable {
        public var height: Int?
        public var url: String
        public var width: Int?
        
        public init(url: String, height: Int?, width: Int?) {
          self.height = height
          self.url = url
          self.width = width
        }
    }
        
    public struct Thumbnail: Encodable {
        public var height: Int?
        public var url: String
        public var width: Int?
        
        public init(url: String, height: Int?, width: Int?) {
          self.height = height
          self.url = url
          self.width = width
        }
    }
    
    public struct Video: Encodable {
        public var height: Int?
        public var url: String
        public var width: Int?
        
        public init(url: String, height: Int?, width: Int?) {
            self.height = height
            self.url = url
            self.width = width
        }
    }
}
