//
//  LongParameterListQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 19/10/2019.
//

import Foundation

class LongParameterListQuery: Query {
    var name = "LongParameterList"
    let veryHighNumberOfParameters = Metrics.veryHighNumberOfParameters
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class)-[:CLASS_OWNS_METHOD]->(m:Method)-[r:METHOD_OWNS_ARGUMENT]->(a:Argument) with c, m, count(a) as argument_count where argument_count > \(self.veryHighNumberOfParameters) return m.app_key as app_key, c.name as class_name, m.name as method_name, argument_count as argument_count, c.data_string as main_text, m.data_string as affected_text"
    }
    
    var appString: String {
        return "match (c:Class)-[:CLASS_OWNS_METHOD]->(m:Method)-[r:METHOD_OWNS_ARGUMENT]->(a:Argument) with c, m, count(a) as argument_count where argument_count > \(self.veryHighNumberOfParameters) return distinct(m.app_key) as app_key, count(distinct m) as number_of_smells"
    }
    
    var notes: String {
        return ""
    }
    
    
}
