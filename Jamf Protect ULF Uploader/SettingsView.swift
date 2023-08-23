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
    
    @State private var verifyButtonDisabled = true
    @State private var password = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

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
                        .onChange(of: protectURL) { newValue in
                            if protectURL.isEmpty {
                                verifyButtonDisabled = true
                            } else {
                                verifyButtonDisabled = false
                            }
                        }
                    TextField("Your Jamf Protect Client ID" , text: $clientID)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: clientID) { newValue in
                            if clientID.isEmpty {
                                verifyButtonDisabled = true
                            } else {
                                verifyButtonDisabled = false
                            }
                        }
                    SecureField("Your Jamf Protect API Password" , text: $password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: password) { newValue in
                            savePasswordToKeychain()
                            if password.isEmpty {
                                verifyButtonDisabled = true
                            } else {
                                verifyButtonDisabled = false
                            }
                        }
                }
            }
            .padding()
            HStack(alignment: .center) {
                Spacer()
                Button("Verify") {
                    Task {
                        await verifyCredentials()
                    }
                }
                .disabled(verifyButtonDisabled)
                Spacer()
            }
            .alert(isPresented: self.$showAlert,
                   content: {
                self.showCustomAlert()
            })
        }
        .onAppear {
            let defaults = UserDefaults.standard
            clientID = defaults.string(forKey: "clientID") ?? ""
            protectURL = defaults.string(forKey: "protectURL") ?? ""
                let credentialsArray = Keychain().retrieve(service: "uk.co.mallion.jamf-protect-ulf-uploader")
                if credentialsArray.count == 2 {
                    password = credentialsArray[1]
                }
            if clientID.isEmpty || protectURL.isEmpty || password.isEmpty {
                verifyButtonDisabled = true
            } else {
                verifyButtonDisabled = false
            }
        }
    }
    
    func showCustomAlert() -> Alert {
        return Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
                )
    }
    
    func verifyCredentials() async {
        let jamfProtect = JamfProtectAPI()
        let (authToken, httpRespoonse) = await jamfProtect.getToken(protectURL: protectURL, clientID: clientID, password: password)
        if let httpRespoonse = httpRespoonse, httpRespoonse == 200 {
            alertTitle = "Authentication"
            alertMessage = "Successfully Authenticated."
        } else {
            alertTitle = "Authentication"
            alertMessage = "Failed to Authenticate."
        }
        showAlert = true
    }
    
    func savePasswordToKeychain() {
        DispatchQueue.global(qos: .background).async {
            Keychain().save(service: "uk.co.mallion.jamf-protect-ulf-uploader", account: "apiclient", data: password)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
