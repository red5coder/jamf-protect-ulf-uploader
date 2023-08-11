//
//  SettingsView.swift
//  Jamf Protect ULF Uploader
//
//  Created by Richard Mallion on 10/08/2023.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("protectURL") var protectURL: String = ""
    @AppStorage("clientID") var clientID: String = ""
//    @AppStorage("savePassword") var savePassword: Bool = false
//    @State private var key = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .trailing){
            HStack(alignment: .center) {
                
                VStack(alignment: .trailing, spacing: 12.0) {
                    Text("Jamf Protect URL:")
                    Text("Client ID:")
                    Text("Password:")
                }
                
                VStack(alignment: .leading, spacing: 7.0) {
                    TextField("https://your-jamf-protect-server.com" , text: $protectURL)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Your Jamf Protect Client ID" , text: $clientID)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Your Jamf Protect API Password" , text: $password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: password) { newValue in
                            savePasswordToKeychain()
                        }
                }
            }
            .padding()
            
//            Toggle(isOn: $savePassword) {
//                Text("Save Password")
//            }
//            .toggleStyle(CheckboxToggleStyle())
//            .offset(x: -260 , y: -10)
//            .onChange(of: savePassword) { newValue in
//                savePasswordToKeychain()
//            }
            
        }
        .onAppear {
            let defaults = UserDefaults.standard
            clientID = defaults.string(forKey: "clientID") ?? ""
            protectURL = defaults.string(forKey: "protectURL") ?? ""
//            savePassword = defaults.bool(forKey: "savePassword" )
//            if savePassword  {
                let credentialsArray = Keychain().retrieve(service: "com.jamf.Jamf-Protect-ULF-Uploader")
                if credentialsArray.count == 2 {
//                    key = credentialsArray[0]
                    password = credentialsArray[1]
                }
//            }
        }
    }
    
    func savePasswordToKeychain() {
        DispatchQueue.global(qos: .background).async {
            Keychain().save(service: "com.jamf.Jamf-Protect-ULF-Uploader", account: "apiclient", data: password)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
