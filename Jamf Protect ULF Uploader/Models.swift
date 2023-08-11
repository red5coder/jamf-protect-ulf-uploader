//
//  Models.swift
//  Jamf Protect ULF Uploader
//
//  Created by Richard Mallion on 09/08/2023.
//

import Foundation
// MARK: - Welcome6Element
struct GitBranch : Codable {
    let name: String
    let commit: Commit
    let protected: Bool
    // MARK: - Commit
    struct Commit : Codable {
        let sha: String
        let url: String
    }

    
}


typealias GitBranches = [GitBranch]



struct ULFilter : Codable, Identifiable {
    let id = UUID()
    var include = false
    let name: String
    let description: String
    let predicate: String
    let tags: [String]
    let enabled: Bool
    enum CodingKeys: String, CodingKey {
        case name,description,predicate
        case tags
        case enabled
    }

}



// MARK: - Welcome
struct UnifiedLoggingBranch: Codable {
    let files: [File]

    enum CodingKeys: String, CodingKey {
        case files
    }
}

// MARK: - WelcomeAuthor
// MARK: - File
struct File: Codable {
    let sha, filename: String
    let additions, deletions, changes: Int
    let blobURL, rawURL, contentsURL: String
    let patch: String

    enum CodingKeys: String, CodingKey {
        case sha, filename, additions, deletions, changes
        case blobURL = "blob_url"
        case rawURL = "raw_url"
        case contentsURL = "contents_url"
        case patch
    }
}
