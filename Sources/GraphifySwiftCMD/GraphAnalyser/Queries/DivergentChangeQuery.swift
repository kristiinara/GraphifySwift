//
//  DivergentChangeQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 17/10/2019.
//

import Foundation

class DivergentChangeQuery: Query {
    let name = "DivergentChange"
    let veryHighNumberOfCalledMethods = Metrics.veryHighNumberOfCalledMethods
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (c:Class)-[:CLASS_OWNS_METHOD]-> (m:Method)-[r:CALLS]->(other_method:Method) with c, m, COUNT(r) as number_of_called_methods where number_of_called_methods > \(self.veryHighNumberOfCalledMethods) RETURN m.app_key as app_key, c.name as class_name, m.name as method_name, number_of_called_methods as number_of_called_methods, c.data_string as main_text, m.data_string as affected_text"
    }
    
    var appString: String {
        return "MATCH (c:Class)-[:CLASS_OWNS_METHOD]-> (m:Method)-[r:CALLS]->(other_method:Method) with c, m, COUNT(r) as number_of_called_methods where number_of_called_methods > \(self.veryHighNumberOfCalledMethods) RETURN distinct(m.app_key) as app_key, count(distinct m) as number_of_smells"
    }
    
    var notes: String {
        return "Queries all methods that call more than a very high number of methods. Very high number of methods currently set to 20."
    }
}
