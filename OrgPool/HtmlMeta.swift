//
//  HtmlMeta.swift
//  OrgPool
//
//  Created by hiroakit on 2022/06/03.
//

import Foundation
import ArgumentParser
import SwiftOrg

struct HtmlMeta: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Generate html meta tag from org mode file")

    @Argument(
        help: "TBD.",
        completion: .file(), transform: URL.init(fileURLWithPath:))
    var inputFileUrl: URL?
    
    mutating func run() throws {
        guard let url = inputFileUrl else {
            throw ApplicationError("Require input file url")
        }
        
        // Read org file
        let expandedUrl = URL(fileURLWithPath: NSString(string: url.relativePath).expandingTildeInPath)
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: expandedUrl.path) else {
            throw ApplicationError("File doesn't exsist - '\(url.relativePath)'")
        }
        let orgFile = FileHandle(forReadingAtPath: expandedUrl.path)
        let data = (orgFile?.readDataToEndOfFile())!
        let str = String(data: data, encoding: .utf8)!

        // Parse org file
        let parser = OrgParser()
        let doc = try parser.parse(content: str)

        // Print html meta
        print("<title>\(doc.settings["title"] ?? "")</title>" )
        print("<meta name=\"description\" content=\"\(doc.settings["description"] ?? "")\" />")
    }
}
