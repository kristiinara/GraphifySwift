//
//  Module.swift
//  Basic
//
//  Created by Kristiina Rahkema on 30/09/2019.
//

import Foundation

class Module {
    let name: String
    weak var belongsToApp: App?
    
    init(name: String) {
        self.name = name
    }
}
