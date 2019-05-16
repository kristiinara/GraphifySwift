//
//  Query.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

protocol Query {
    var string: String {get}
    var result: String? {get set}
}

extension Query {
    var finished: Bool {
        return self.result != nil
    }
}
