//
//  LM.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class LongMethodQuery : Query {
    var veryHigh = 26
    
    var string: String {
        return "MATCH (m:Method) WHERE m.number_of_instructions > \(self.veryHigh) RETURN m.name as name, m.app_key as app_key"
    }
    
    var result: String?
}
