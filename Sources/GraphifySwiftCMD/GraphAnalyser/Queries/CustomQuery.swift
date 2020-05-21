//
//  Custom.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class CustomQuery: Query {
    let name = "Custom"
    var string: String
    var appString: String
    var classString: String
    var result: String?
    var json: [String : Any]?
    
    init(queryString: String) {
        self.string = queryString
        self.appString = queryString
        self.classString = queryString
    }
    
    var notes: String {
        return "Running custom query defined by user."
    }
}
