//
//  SiblingDuplicationQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/10/2019.
//

import Foundation

class SiblingDuplicationQuery: Query {
    let name = "SiblingDuplication"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (firstClass:Class)-[:EXTENDS*]->(parent:Class)<-[:EXTENDS*]-(secondClass:Class), (firstClass:Class)-[d:DUPLICATES]->(secondClass:Class) where firstClass.data_string contains d.fragment or secondClass.data_string contains d.fragment return firstClass.app_key as app_key, firstClass.name as class_name, secondClass.name as second_class_name, parent.name as parent_class_name, firstClass.data_string as main_text, d.fragment as affected_text"
    }
    
    var appString: String {
        return "MATCH (firstClass:Class)-[:EXTENDS*]->(parent:Class)<-[:EXTENDS*]-(secondClass:Class), (firstClass:Class)-[d:DUPLICATES]->(secondClass:Class) where firstClass.data_string contains d.fragment or secondClass.data_string contains d.fragment return distinct(firstClass.app_key) as app_key, count(distinct d) as number_of_smells"
    }

    var notes: String {
        return "Queries classes that have a common ancestor and include duplicated code."
    }
}
