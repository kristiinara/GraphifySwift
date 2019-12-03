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
        return "MATCH (firstClass:Class)-[r:DUPLICATES]->(secondClass:Class), (module:Module)-[:MODULE_OWNS_CLASS]->(firstClass), (module:Module)-[:MODULE_OWNS_CLASS]->(secondClass) where firstClass.data_string contains r.fragment or secondClass.data_string contains r.fragment return firstClass.app_key as app_key, firstClass.name as class_name, secondClass.name as second_class_name, module.name as module_name, r.fragment as text_fragment, firstClass.data_string as main_text, r.fragment as affected_text"
    }
    
    var appString: String {
        return """
        MATCH
        (firstClass:Class)-[r:DUPLICATES]->(secondClass:Class),
        (module:Module)-[:MODULE_OWNS_CLASS]->(firstClass),
        (module:Module)-[:MODULE_OWNS_CLASS]->(secondClass)
        where firstClass.data_string contains r.fragment or secondClass.data_string contains r.fragment return distinct(firstClass.app_key) as app_key, count(distinct r) as number_of_smells
        """
    }
    
    var notes: String {
        return "Queries classes that duplicate each-other and belong to the same module."
    }
}
