//
//  Log.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Logging

extension Swiftcord {

    /**
     Logs the given message

     - parameter message: Info to output
     */
    func log(_ message: Logger.Message) {
        self.logger.info(message)
    }

    /**
     Logs the given warning message

     - parameter message: Warning to output
     */
    func warn(_ message: Logger.Message) {
        self.logger.warning(message)
    }

    /**
     Logs the given error message

     - parameter message: Error to output
     */
    func error(_ message: Logger.Message) {
        self.logger.error(message)
    }
    
    func debug(_ message: Logger.Message) {
        self.logger.debug(message)
    }
    
    func trace(_ message: Logger.Message) {
        self.logger.trace(message)
    }

}
