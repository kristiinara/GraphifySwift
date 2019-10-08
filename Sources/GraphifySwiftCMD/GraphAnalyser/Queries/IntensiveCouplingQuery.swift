//
//  IntensiveCouplingQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class IntensiveCouplingQuery: Query {
    var name = "IntensiveCoupling"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class)-[r:CLASS_OWNS_METHOD]->(m1:Method)-[s:CALLS]->(m2:Method), (c2:Class)-[r2:CLASS_OWNS_METHOD]->(m2) where id(c) <> id(c2) with c,m1, count(distinct m2) as method_count, collect(distinct m2.name) as names, collect(distinct c2.name) as class_names, count(distinct c2) as class_count  where ((method_count >= 7 and class_count/method_count <= 0.5) or (method_count >= 2 and class_count/method_count <= 0.25)) and m1.max_nesting_depth >= 1 return m1.app_key as app_key, m1.name as method_name, c.name as class_name"
    }
    
    var detailedResultString: String {
        return "match (c:Class)-[r:CLASS_OWNS_METHOD]->(m1:Method)-[s:CALLS]->(m2:Method), (c2:Class)-[r2:CLASS_OWNS_METHOD]->(m2) where id(c) <> id(c2) with c,m1, count(distinct m2) as method_count, collect(distinct m2.name) as names, collect(distinct c2.name) as class_names, count(distinct c2) as class_count  where ((method_count >= 7 and class_count/method_count <= 0.5) or (method_count >= 2 and class_count/method_count <= 0.25)) and m1.max_nesting_depth >= 1 return m1.app_key as app_key, m1.name as method_name, c.name as class_name, method_count as method_count, class_count as class_count"
    }
    
    var notes: String {
        return ""
    }
    
    
}
