//
//  ExternalDuplicationQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/10/2019.
//

import Foundation

class ExternalDuplicationQuery: Query {
    let name = "ExternalDuplicationQuery"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (firstClass:Class)-[:DUPLICATES]->(secondClass:Class), (module:Module)-[:MODULE_OWNS_CLASS]->(firstClass), (secondModule:Module)-[:MODULE_OWNS_CLASS]->(secondClass) where id(module) <> id(secondModule) return firstClass.app_key as app_key, firstClass.name as first_class, secondClass.name as second_class, module.name as module_name, secondModule.name as second_module_name"
    }
    
    var notes: String {
        return "Queries classes that duplicate each-other and belong to different modules."
    }
}
