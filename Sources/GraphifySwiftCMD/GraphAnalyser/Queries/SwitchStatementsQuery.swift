//
//  SwitchStatements.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class SwitchStatementsQuery: Query {
    var name = "SwitchStatements"
    let highNumberOfSwitchStatments = Metrics.veryHighNumberOfSwitchStatements
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (c:Class)-[r:CLASS_OWNS_METHOD]->(m:Method) where m.number_of_switch_statements > \(self.highNumberOfSwitchStatments) return m.app_key as app_key, c.name as class_name, m.name as method_name, m.number_of_switch_statements as number_of_switch_statements, c.data_string as main_text, m.data_string as affected_text"
    }
    
    var appString: String {
        return "MATCH (c:Class)-[r:CLASS_OWNS_METHOD]->(m:Method) where m.number_of_switch_statements > \(self.highNumberOfSwitchStatments)  return distinct(m.app_key) as app_key, count(distinct m) as number_of_smells"
    }
    
    var notes: String {
        return "Switch Statements code smell looks at methods, where number of switch statements is high. Currently set to 1. High number of switch statements needs to be defined statistically."
    }
}
