//
//  ContentView.swift
//  Jamf Protect ULF Uploader
//
//  Created by Richard Mallion on 09/08/2023.
//

import SwiftUI
import Yams
import os.log

struct ContentView: View {
    @State private var protectURL = ""
    @State private var clientID = ""
    @State private var password = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    @State private var showActivity = false

    @State private var ulfilters = [ULFilter]()
    
    @State private var uploadButtonDisabled = true
    
    @State private var sortOrder = [KeyPathComparator(\ULFilter.name)]
    @State private var searchTerm = ""

    private var searchResults: [ULFilter] {
        if searchTerm.isEmpty {
            return ulfilters.filter { _ in true }
        } else {
            return ulfilters.filter {  $0.name.lowercased().contains(searchTerm.lowercased())  || $0.tagsDiplay.lowercased().contains(searchTerm.lowercased())     }
        }
    }
    
    var body: some View {
        VStack {
                Table(searchResults, sortOrder: $sortOrder) {
                    TableColumn("Include") { item in
                        Toggle("", isOn: Binding<Bool>(
                           get: { return item.include },
                           set: {
                               if let index = ulfilters.firstIndex(where: { $0.id == item.id }) {
                                   ulfilters[index].include = $0
                               }
                               var disableupload = true
                               ulfilters.forEach {
                                   if $0.include {
                                       disableupload = false
                                   }
                                   uploadButtonDisabled = disableupload
                               }
                           }
                        ))
                    }
                    .width(45)
                    TableColumn("Filter Name", value: \.name)
                    TableColumn("Tags" ,value: \.tagsDiplay)
                }
                .onChange(of: sortOrder) { newOrder in
                    ulfilters.sort(using: newOrder)
                }
                .searchable(text: $searchTerm, prompt: "Name or tag")
            HStack {
                Button("Fetch Filters") {
                    Task {
                        if let unifiedLogsURL = await getBranch(branchname: "unified_log_filters") {
                            var branchYamlFiles = await getBranchContent(branchURL: unifiedLogsURL, type: "blob")
                            let branchSubDirectories = await getBranchContent(branchURL: unifiedLogsURL, type: "tree")
                            if let branchSubDirectories = branchSubDirectories {
                                for directory in branchSubDirectories {
                                    let extraYAML = await getBranchContent(branchURL: directory, type: "blob")
                                    branchYamlFiles?.append(contentsOf: extraYAML ?? [])
                                }
                            }
                            if let branchYamlFiles = branchYamlFiles {
                                if let fetchedulfilters = try? await getYamlFiles(fileURLS: branchYamlFiles) {
                                    ulfilters = fetchedulfilters.sorted { $0.name < $1.name }
                                    Logger.github.info("Found \(fetchedulfilters.count, privacy: .public) filters")
                                }
                            } else {
                                Logger.github.error("No filters found")
                            }
                        }
                    }
                }
                .padding(.trailing)
                Button("Upload") {
                    Task {
                        await uploadFilters()
                    }
                }
                .disabled(uploadButtonDisabled)
                ProgressView()
                        .scaleEffect(0.5)
                        .opacity(showActivity ? 1 : 0)
            }
        }
        .padding()
        .alert(isPresented: self.$showAlert,
               content: {
            self.showCustomAlert()
        })
        .task {
            let defaults = UserDefaults.standard
            protectURL = defaults.string(forKey: "protectURL") ?? ""
            if protectURL.isEmpty {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
    

    // MARK: - UploadFilters
    func uploadFilters() async {
        Logger.protect.info("About to upload selected filters")
        showActivity = true
        var succesfullUploadCount = 0
        for filter in ulfilters {
            if filter.include {
                if let responseCode = await uploadFilter(filter: filter), responseCode == 200 {
                    succesfullUploadCount = succesfullUploadCount + 1
                }
            }
        }
        Logger.protect.info("\(succesfullUploadCount, privacy: .public) filters where selected for upload")
        showActivity = false
        alertMessage = "\(succesfullUploadCount) Unified Logging Filters Uploaded."
        alertTitle = "Upload Results"
        showAlert = true

    }
    
    func uploadFilter(filter: ULFilter) async -> Int? {
        Logger.protect.info("About to upload filter \(filter.name, privacy: .public)")
        let defaults = UserDefaults.standard
        clientID = defaults.string(forKey: "clientID") ?? ""
        protectURL = defaults.string(forKey: "protectURL") ?? ""
        let credentialsArray = Keychain().retrieve(service: "uk.co.mallion.jamf-protect-ulf-uploader")
        if credentialsArray.count == 2 {
            password = credentialsArray[1]
        }
        let jamfProtect = JamfProtectAPI()
        let (authToken, httpRespoonse) = await jamfProtect.getToken(protectURL: protectURL, clientID: clientID, password: password)
        if let httpResponse = httpRespoonse  {
            Logger.protect.info("HTTP Response \(httpResponse) to authenticating to \(protectURL , privacy: .public)")
        }
        guard let authToken else {
            Logger.protect.error("Could not authenticate to \(protectURL , privacy: .public)")
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            return nil
        }
        Logger.protect.info("Sucessfully authenticated to \(protectURL , privacy: .public)")
        let responseCode = await jamfProtect.createFilter(protectURL: protectURL, access_token: authToken.access_token, ulfilter: filter)
        return responseCode
    }
    
    // MARK: - Github
    func getBranch(branchname: String) async -> String? {
        Logger.github.info("About to get the contents of the main branch")
        guard var branchesEndPoint = URLComponents(string: "https://api.github.com") else {
            return nil
        }
        branchesEndPoint.path="/repos/jamf/jamfprotect/contents"
        let queryItems = [URLQueryItem(name: "ref", value: "main")]
        branchesEndPoint.queryItems = queryItems
        guard let url = branchesEndPoint.url else { return nil }
        var branchRequest = URLRequest(url: url)
        branchRequest.httpMethod = "GET"
        branchRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: branchRequest) else {
            Logger.github.error("Failed to connect to main branch")
            return  nil
        }

        if let httpResponse = response as? HTTPURLResponse {
            Logger.github.info("HTTP Response \(httpResponse.statusCode) to connecting to https://api.github.com/repos/jamf/jamfprotect/contents?ref=main: \(httpResponse.statusCode , privacy: .public)")
        }
        do {
            let contents = try JSONDecoder().decode(GitMainBranchContents.self, from: data)
            for content in contents {
                if content.name.lowercased() == "unified_log_filters" && content.type.lowercased() == "dir" {
                    Logger.github.info("Found unified_log_filters \(content.git_url , privacy: .public)")
                    return content.git_url
                }
            }
            Logger.github.error("No content was retrieved from the main branch")
            return nil
            
        } catch  {
            Logger.github.error("Could not decode contents from the main brnch, \(error.localizedDescription)")
            return nil
        }
    }

    func getBranchContent(branchURL: String , type: String) async -> [String]? {
        guard let url = URL(string: branchURL) else { return nil}
        var branchRequest = URLRequest(url: url)
        branchRequest.httpMethod = "GET"
        guard let (data, response) = try? await URLSession.shared.data(for: branchRequest)
        else {
            Logger.github.error("Failed to retrieve branch dertails for \(branchURL , privacy: .public)")
            return nil
        }
        do {
            let unifiedLoggingBranch = try JSONDecoder().decode(UnifiedLoggingBranch.self, from: data)
            var files = [String]()
            for file in unifiedLoggingBranch.tree {
                if file.path.lowercased().hasSuffix(".yaml") && file.type.lowercased() == type {
                    files.append(file.url)
                } else if file.type.lowercased() == type && type == "tree"{
                    files.append(file.url)
                }
            }
            if files.count > 0 {
                return files
            }
            return nil
        } catch _ {
            Logger.github.error("Could not decode content for \(branchURL, privacy: .public)")
            return nil
        }
    }

    func getYamlFiles (fileURLS: [String]) async throws-> [ULFilter] {
        Logger.github.info("About to retrive the unified log filters")
        var ulfilters = [ULFilter]()
        try await withThrowingTaskGroup(of: (ULFilter?).self) { group in
          for file in fileURLS {
            group.addTask {
              return (try await getYamlFile(fileURL: file))
            }
          }
          for try await (ulfilter) in group {
              if let ulfilter = ulfilter {
                  ulfilters.append(ulfilter)
              }
          }
        }
        return ulfilters
    }
    
    func getYamlFile (fileURL: String) async throws -> ULFilter? {
        Logger.github.info("Fetching filter \(fileURL , privacy: .public)")
        guard let url = URL(string: fileURL) else { throw ThumbnailError.invalidURL }
        let result: (data: Data, response: URLResponse) = try await URLSession.shared.data(from: url)
        if let httpResponse = result.response as? HTTPURLResponse {
            Logger.github.info("HTTP Response \(httpResponse.statusCode , privacy: .public) to connecting to \(fileURL , privacy: .public)")
        }
        let decoder = YAMLDecoder()
        let encodedString = String(decoding: result.data, as: UTF8.self)
        do {
            let encodedulfilter = try decoder.decode(EncodedULFilter.self, from: encodedString, userInfo: [:])
            let decodedContents = try Data.decodeUrlSafeBase64(encodedulfilter.content)
            let decodedContentsString = String(decoding: decodedContents, as: UTF8.self)
            let decodedContentsStringQuotes = handleQuotes(string: decodedContentsString)
            do {
                let ulfilter = try decoder.decode(ULFilter.self, from: decodedContentsStringQuotes, userInfo: [:])
                Logger.github.info("Successfully retrieved filter \(ulfilter.name,privacy: .public)")
                return ulfilter
            } catch {
                Logger.github.error("Failed to decode \(fileURL,privacy: .public) , \(error.localizedDescription, privacy: .public)")
            }
            return nil
        }  catch  {
            Logger.github.error("Failed to decode \(error.localizedDescription, privacy: .public)")
        }
        return nil
    }

    
    func handleQuotes(string: String) -> String {
        let array = string.components(separatedBy: "predicate:")
        let subsection = array[1].components(separatedBy: "tags:")
        var predicate = subsection[0]
        predicate = predicate.replacingOccurrences(of: "\"", with: "'")
        if let range = predicate.range(of: String("'")) {
            predicate.replaceSubrange(range, with: String("\""))
        }
        if let range = predicate.range(of: String("'"), options: .backwards) {
            predicate.replaceSubrange(range, with: String("\""))
        }
        var finalString = array[0]
        finalString = finalString + "predicate:"
        finalString = finalString + predicate
        finalString = finalString + "tags:"
        finalString = finalString + subsection[1]
        return finalString
    }



    enum ThumbnailError: Error {
        case invalidURL
        case missingData
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



