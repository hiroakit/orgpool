//
//  ApplicationError.swift
//  OrgPool
//
//  Created by hiroakit on 2022/06/03.
//

import Foundation

struct ApplicationError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}
