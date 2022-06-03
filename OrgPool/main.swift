//
//  main.swift
//  orgpool
//
//  Created by hiroakit on 2022/05/29.
//

import Foundation
import ArgumentParser
import SwiftOrg
import CodableCSV

struct OrgPool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "orgpool",
        abstract: "A utility for org mode files.",
        version: "0.0.1",
        subcommands: [HtmlMeta.self, ConvertWordPressCSV.self],
        defaultSubcommand: HtmlMeta.self)
}

OrgPool.main()
