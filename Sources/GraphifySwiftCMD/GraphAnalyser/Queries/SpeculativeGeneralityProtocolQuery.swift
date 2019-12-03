//
//  SpeculativeGeneralityProtocolQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 24/10/2019.
//

import Foundation

class SpeculativeGeneralityProtocolQuery: Query {
    var name = "SpeculativeGeneralityProtocol"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (class:Class) where not ()-[:IMPLEMENTS|EXTENDS]->(class) and  class.is_interface = true return class.app_key as app_key, class.name as class_name, class.data_string as main_text"
    }
    
    var appString: String {
        return "match (class:Class) where not ()-[:IMPLEMENTS|EXTENDS]->(class) and  class.is_interface = true return distinct(class.app_key) as app_key, count(distinct class) as number_of_smells"
    }
    
    var notes: String {
        return "Queries interfaces that are not extended or implemented."
    }
}
