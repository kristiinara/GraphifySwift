//
//  InternalDuplicationQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/10/2019.
//

import Foundation

class InternalDuplicationQuery: Query {
    let name = "InternalDuplication"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (firstClass:Class)-[:DUPLICATES]->(secondClass:Class), (module:Module)-[:MODULE_OWNS_CLASS]->(firstClass), (module:Module)-[:MODULE_OWNS_CLASS]->(secondClass) return firstClass.app_key as app_key, firstClass.name as first_class, secondClass.name as second_class, module.name as module_name"
    }
    
    var notes: String {
        return "Queries classes that duplicate each-other and belong to the same module."
    }
}
