//
//  Duplication.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/10/2019.
//

import Foundation

class Duplication {
    let firstClassPath: String
    let secondClassPath: String
    let firstFileStart: Int
    let secondFileStart: Int
    let firstFileEnd: Int
    let secondFileEnd: Int
    let fragment: String
    
    var firstClass: Class?
    var secondClass: Class?
    
    init(firstClassPath: String, secondClassPath: String, firstFileStart: Int, secondFileStart: Int, firstFileEnd: Int, secondFileEnd: Int, fragment: String) {
        self.firstClassPath = firstClassPath
        self.secondClassPath = secondClassPath
        self.firstFileStart = firstFileStart
        self.firstFileEnd = firstFileEnd
        self.secondFileStart = secondFileStart
        self.secondFileEnd = secondFileEnd
        self.fragment = fragment
    }
}


extension Duplication {
    var addDuplicationQuery: String? {
        if let firstClassId = self.firstClass?.id, let secondClassId = self.secondClass?.id {
            var fragment = self.fragment.replacingOccurrences(of: "\"", with: "'")
            fragment = fragment.replacingOccurrences(of: "\\", with: "\\\\")
            
            return "match (first:Class), (second:Class) where id(first) = \(firstClassId) and id(second) = \(secondClassId) create (first)-[r:DUPLICATES {fragment: \"\(fragment)\"} ]->(second) return id(r)"
        }
        return nil
    }
}
