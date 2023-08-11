//
//  JamfProtectAPI.swift
//  Jamf Protect ULF Uploader
//
//  Created by Richard Mallion on 10/08/2023.
//

import Foundation
import os.log

// MARK: - Jamf Protect Auth Model
struct JamfAuth: Decodable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}


struct JamfProtectAPI {
    
    func createFilter(protectURL: String, access_token: String, ulfilter: ULFilter) async -> Int? {
        Logger.protect.info("About to upload filter \(ulfilter.name, privacy: .public).")
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            Logger.protect.error("Protect URL seems invalid.")
            return nil
        }
        jamfAuthEndpoint.path="/graphql"

        guard let url = jamfAuthEndpoint.url else {
            Logger.protect.error("Protect URL seems invalid.")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(access_token)", forHTTPHeaderField: "Authorization")
        
        var predicate = ulfilter.predicate
        predicate = predicate.replacingOccurrences(of: "'", with: "\\\"")
        print(predicate)
        
        var enabled = "false"
        if ulfilter.enabled {
            enabled = "true"
        }
        
        var tags = ""
        for tag in ulfilter.tags {
            tags = tags + "\"\(tag)\","
        }
        
        let createFilter = """
mutation createFilter {
  createUnifiedLoggingFilter(
    input: {
      name: "\(ulfilter.name)"
      filter: "\(predicate)"
      enabled: \(enabled)
      tags: [\(tags)]
    }
  ) {
    uuid
    name
    created
    updated
    filter
    tags
    enabled
  }
}
"""
        let json: [String: Any] = ["query": createFilter ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        if let jsonData = jsonData {
            request.httpBody = jsonData
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: request)
        else {
            Logger.protect.error("Could not initiate connection to \(url, privacy: .public).")
            return nil
        }

        let httpResponse = response as? HTTPURLResponse
        print(httpResponse?.statusCode)
        return httpResponse?.statusCode

        
        
    }

    func getToken(protectURL: String , clientID: String, password: String) async  -> (JamfAuth?,Int?) {
        Logger.protect.info("Fetching authentication token.")
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            Logger.protect.error("Protect URL seems invalid.")
            return (nil, nil)
        }
        
        jamfAuthEndpoint.path="/token"
        
        guard let url = jamfAuthEndpoint.url else {
            Logger.protect.error("Protect URL seems invalid.")
            return (nil, nil)
        }

        var authRequest = URLRequest(url: url)
        authRequest.httpMethod = "POST"
        
        let json: [String: Any] = ["client_id": clientID,
                                   "password": password]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        if let jsonData = jsonData {
            authRequest.httpBody = jsonData
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: authRequest)
        else {
            Logger.protect.error("Could not initiate connection to \(url, privacy: .public).")
            return (nil, nil)
        }
        
        let httpResponse = response as? HTTPURLResponse

        
        let str = String(decoding: data, as: UTF8.self)

        print(str)
        do {
            let protectToken = try JSONDecoder().decode(JamfAuth.self, from: data)
            Logger.protect.info("Authentication token decoded.")
            return (protectToken, httpResponse?.statusCode)
        } catch _ {
            Logger.protect.error("Could not decode authentication token.")
            return (nil, httpResponse?.statusCode)
        }
    }
    

    
    
    
    
}
