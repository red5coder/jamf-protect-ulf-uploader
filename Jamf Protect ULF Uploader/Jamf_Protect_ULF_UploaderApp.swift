//
//  Jamf_Protect_ULF_UploaderApp.swift
//  Jamf Protect ULF Uploader
//
//  Created by Richard Mallion on 09/08/2023.
//

import SwiftUI

@main
struct Jamf_Protect_ULF_UploaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Settings {
            SettingsView()
                .frame(
                    minWidth: 500, maxWidth: 500,
                    minHeight: 175, maxHeight: 175)
        }

    }
}
