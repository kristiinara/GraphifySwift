//
//  Custom.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class CustomQuery: Query {
    var string: String
    var result: String?
    
    init(queryString: String) {
        self.string = queryString
    }
}
