//
//  Models.swift
//  Jamf Protect ULF Uploader
//
//  Created by Richard Mallion on 09/08/2023.
//

import Foundation


// MARK: - GitBranch

struct GitBranch : Codable {
    let name: String
    let git_url: String
    let type: String
    
}

typealias GitBranches = [GitBranch]


// MARK: - RawULFilter
struct EncodedULFilter : Codable {
    let url: String
    let content: String
    let encoding: String
    enum CodingKeys: String, CodingKey {
        case url
        case content
        case encoding
    }
}


// MARK: - ULFilter

struct ULFilter : Codable, Identifiable {
    let id = UUID()
    var include = false
    let name: String
    let description: String
    let predicate: String
    let tags: [String]
    var tagsDiplay: String { return tags.joined(separator: ", ")}
    let enabled: Bool
    enum CodingKeys: String, CodingKey {
        case name,description,predicate
        case tags
        case enabled
    }

}







// MARK: - UnifiedLoggingBranch
struct UnifiedLoggingBranch: Codable {
    let tree: [File]

    enum CodingKeys: String, CodingKey {
        case tree
    }
}

// MARK: - File
struct File: Codable {
    let path, url: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case path, url
        case type
    }
    
}


extension Data {
    static func decodeUrlSafeBase64(_ value: String) throws -> Data {
        var stringtoDecode: String = value.replacingOccurrences(of: "-", with: "+")
        stringtoDecode = stringtoDecode.replacingOccurrences(of: "_", with: "/")
//        switch (stringtoDecode.utf8.count % 4) {
//            case 2:
//                stringtoDecode += "=="
//            case 3:
//                stringtoDecode += "="
//            default:
//                break
//        }
        guard let data = Data(base64Encoded: stringtoDecode, options: [.ignoreUnknownCharacters]) else {
            throw NSError(domain: "decodeUrlSafeBase64", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Can't decode base64 string"])
        }
        return data
    }
}
