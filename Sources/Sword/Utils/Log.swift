//
//  Log.swift
//  Sword
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Rainbow

extension Sword {

  /**
   Logs the given message

   - parameter message: Info to output
  */
  func log(_ message: String) {
    print("[Sword] " + message.applyingCodes(Color.yellow))
  }

  /**
   Logs the given warning message

   - parameter message: Warning to output
  */
  func warn(_ message: String) {
    let prefix = "Warning: "
      self.log(prefix + message + "\n".applyingCodes(Color.yellow))
  }

  /**
   Logs the given error message

   - parameter message: Error to output
  */
  func error(_ message: String) {
    let prefix = "Error: "
      self.log(prefix + message + "\n".applyingCodes(Color.red))
  }

}
