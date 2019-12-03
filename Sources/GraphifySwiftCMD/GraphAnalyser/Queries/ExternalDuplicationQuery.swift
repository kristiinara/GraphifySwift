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
        return "MATCH (firstClass:Class)-[d:DUPLICATES]->(secondClass:Class), (module:Module)-[:MODULE_OWNS_CLASS]->(firstClass), (secondModule:Module)-[:MODULE_OWNS_CLASS]->(secondClass) where id(module) <> id(secondModule) and firstClass.data_string contains d.fragment or secondClass.data_string contains d.fragment return firstClass.app_key as app_key, firstClass.name as class_name, secondClass.name as second_class_name, module.name as module_name, secondModule.name as second_module_name, d.fragment as text_fragment, firstClass.data_string as main_text, d.fragment as affected_text"
    }
    
    var appString: String {
        return " MATCH (firstClass:Class)-[d:DUPLICATES]->(secondClass:Class), (module:Module)-[:MODULE_OWNS_CLASS]->(firstClass), (secondModule:Module)-[:MODULE_OWNS_CLASS]->(secondClass) where id(module) <> id(secondModule) and firstClass.data_string contains d.fragment or secondClass.data_string contains d.fragment return distinct(firstClass.app_key) as app_key, count(distinct d) as number_of_smells"
    }
    
    var notes: String {
        return "Queries classes that duplicate each-other and belong to different modules."
    }
}
