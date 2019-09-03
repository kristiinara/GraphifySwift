//
//  LM.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class LongMethodQuery : Query {
    let name = "LongMethod"
    var veryHighNumberOfInstructions = 26
    
    var string: String {
        return "MATCH (m:Method) WHERE m.number_of_instructions > \(self.veryHighNumberOfInstructions) RETURN m.name as name, m.app_key as app_key, m.number_of_instructions as number_of_instructions"
    }
    
    var result: String?
    var json: [String : Any]?
}
