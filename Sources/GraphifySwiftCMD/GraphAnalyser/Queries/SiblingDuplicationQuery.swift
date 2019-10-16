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
        return "MATCH (firstClass:Class)-[:EXTENDS*]->(parent:Class)<-[:EXTENDS*]-(secondClass:Class), (firstClass:Class)-[:DUPLICATES]->(secondClass:Class) return firstClass.app_key as app_key, firstClass.name as first_class, secondClass.name as second_class, parent.name as parent_class"
    }

    var notes: String {
        return "Queries classes that have a common ancestor and include duplicated code."
    }
}
