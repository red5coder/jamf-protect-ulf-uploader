//
//  Logger.swift
//  Jamf Protect ULF Uploader
//
//  Created by Richard Mallion on 10/08/2023.
//

import Foundation
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    //Categories
    static let protect = Logger(subsystem: subsystem, category: "protect")
}
