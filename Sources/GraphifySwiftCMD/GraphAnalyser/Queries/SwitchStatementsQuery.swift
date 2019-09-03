//
//  SwitchStatements.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class SwitchStatementsQuery: Query {
    var name = "SwitchStatements"
    let highNumberOfSwitchStatments = 1
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (c:Class)-[r:CLASS_OWNS_METHOD]->(m:Method) where m.number_of_switch_statements >= \(self.highNumberOfSwitchStatments) return m.name as name, c.name as class_name, m.app_key as app_key, m.number_of_switch_statements as number_of_switch_statements"
    }
}
