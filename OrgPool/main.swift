//
//  main.swift
//  orgpool
//
//  Created by hiroakit on 2022/05/29.
//

import Foundation
import ArgumentParser
import SwiftOrg

struct OrgPool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "orgpool",
        abstract: "A utility for org mode files.",
        version: "0.0.1",
        subcommands: [HtmlMeta.self, ImportWordPressCSV.self],
        defaultSubcommand: HtmlMeta.self)
}

struct ImportWordPressCSV: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import org by WordPress CSV")
    
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
        
        let file = FileHandle(forReadingAtPath: expandedUrl.path)
        let data = (file?.readDataToEndOfFile())!
        let dataString = String(data: data, encoding: .utf8)!
        let csv = dataString.csvRows()
        for (index, value) in csv.enumerated() {
            // Skip header
            if index == 0 {
                continue;
            }
      
            print("#+title: \(value[4])")
            print("#+data: \(value[7])")
            print("#+description: \(value[6])")
            
            try value[5].write(to: URL(fileURLWithPath: "/Users/hiroakit/Desktop/hoge.html"), atomically: true, encoding: .utf8)
            
            let inputFile = FileHandle(forReadingAtPath: "/Users/hiroakit/Desktop/hoge.html")
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/local/bin/pandoc")
//            proc.arguments = ["-f", "html", "-t", "org", "/Users/hiroakit/Desktop/hoge.html", "-o", "/Users/hiroakit/Desktop/hoge.org"]
//            proc.arguments = ["-f", "html", "-t", "org", "/Users/hiroakit/Desktop/hoge.html"]
            proc.arguments = ["-f", "html", "-t", "org"]
            proc.standardInput = inputFile
            proc.standardOutput = outputPipe
            proc.standardError = errorPipe
            try proc.run()
            proc.waitUntilExit()
            if !proc.isRunning {
                let status = proc.terminationStatus
                if status == 0 {
                    print("Task succeeded.\n")
                } else {
                    print("Task failed.\n")
                    continue;
                }
            }

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            //let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: outputData, as: UTF8.self)
            // let error = String(decoding: errorData, as: UTF8.self)
            
            // Create org-mode text
            var orgString = ""
            orgString.append(contentsOf: "#+title: \(value[4])\n")
            orgString.append(contentsOf: "#+data: \(value[7])\n")
            orgString.append(contentsOf: "#+description: \(value[6])\n\n")
            orgString.append(contentsOf: "\(output)\n")
            
            // Export org-mode format
            let format = DateFormatter()
            format.dateFormat = "yyyy_MM_dd-HH_mm_ss_SSS"
            let hogename = format.string(from: Date.now)
            try? orgString.write(toFile: "/Users/hiroakit/Desktop/file_\(hogename).org", atomically: true, encoding: .utf8)
        }
    }
}

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

struct ApplicationError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}

OrgPool.main()
