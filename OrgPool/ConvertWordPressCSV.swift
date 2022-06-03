//
//  ConvertWordPressCSV.swift
//  OrgPool
//
//  Created by hiroakit on 2022/06/03.
//

import Foundation
import ArgumentParser
import SwiftOrg
import CodableCSV

struct ConvertWordPressCSV: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert WordPress CSV to org mode files.")
    
    @Argument(
        help: "TBD.",
        completion: .file(), transform: URL.init(fileURLWithPath:))
    var inputFileUrl: URL?

    @Argument(
        help: "Destination directory",
        completion: .directory, transform: URL.init(fileURLWithPath:))
    var destDir: URL?
    
    mutating func run() throws {
        guard let url = inputFileUrl else {
            throw ApplicationError("Require input file url")
        }

        guard let destDirUrl = destDir else {
            throw ApplicationError("Require destination directory")
        }
        
        // Setup
        let expandedUrl = URL(fileURLWithPath: NSString(string: url.relativePath).expandingTildeInPath)
        let expandedDestDirUrl = URL(fileURLWithPath: NSString(string: destDirUrl.relativePath).expandingTildeInPath, isDirectory: true)
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: expandedUrl.path) else {
            throw ApplicationError("File doesn't exsist - '\(url.relativePath)'")
        }
        
        var isDir : ObjCBool = false
        if !fileManager.fileExists(atPath: expandedDestDirUrl.path, isDirectory: &isDir) {
            // Nothing (file & directory) on path
            try fileManager.createDirectory(at: expandedDestDirUrl, withIntermediateDirectories: true)
        } else {
            if !isDir.boolValue {
                // Nothing directory on path, but file exists.
                throw ApplicationError("Found file on path. Require directory path.  - '\(destDirUrl.relativePath)'")
            } else {
                // Directory exists on path.
            }
        }
        
        // Read org file
        let file = FileHandle(forReadingAtPath: expandedUrl.path)
        let data = (file?.readDataToEndOfFile())!
        let csv = try CSVReader(input: data)
        for (index, value) in csv.enumerated() {
            // Skip header
            if index == 0 {
                continue;
            }
      
            print("#+title: \(value[4])")
            print("#+data: \(value[7])")
            print("#+description: \(value[6])")
            
            try value[5].write(to: URL(fileURLWithPath: "/tmp/orgpool-tmp.html"), atomically: true, encoding: .utf8)
            
            let inputFile = FileHandle(forReadingAtPath: "/tmp/orgpool-tmp.html")
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/local/bin/pandoc")
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
            let dateName = format.string(from: Date.now)
            let fileName = "file_\(dateName).org"
            let destPath = URL(fileURLWithPath: fileName, relativeTo: expandedDestDirUrl)
            try? orgString.write(toFile: destPath.standardizedFileURL.path, atomically: true, encoding: .utf8)
        }
    }
}
