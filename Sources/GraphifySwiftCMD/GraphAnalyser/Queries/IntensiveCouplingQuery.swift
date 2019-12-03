//
//  IntensiveCouplingQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class IntensiveCouplingQuery: Query {
    var name = "IntensiveCoupling"
    
    let maxNumberOfShortMemoryCap = Metrics.shorTermMemoryCap
    let fewCouplingIntensity = 2
    let halfCouplingDispersion = 0.5
    let quarterCouplingDispersion = 0.25
    let shallowMaximumNestingDepth = 1
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class)-[r:CLASS_OWNS_METHOD]->(m1:Method)-[s:CALLS]->(m2:Method), (c2:Class)-[r2:CLASS_OWNS_METHOD]->(m2) where id(c) <> id(c2) with c,m1, count(distinct m2) as method_count, collect(distinct m2.name) as names, collect(distinct c2.name) as class_names, count(distinct c2) as class_count  where ((method_count >= \(self.maxNumberOfShortMemoryCap) and class_count/method_count <= \(self.halfCouplingDispersion)) or (method_count >= \(self.fewCouplingIntensity) and class_count/method_count <= \(self.quarterCouplingDispersion))) and m1.max_nesting_depth >= \(self.shallowMaximumNestingDepth) return m1.app_key as app_key, c.name as class_name, m1.name as method_name, c.data_string as main_text, m1.data_string as affected_text"
    }
    
    var appString: String {
        return "match (c:Class)-[r:CLASS_OWNS_METHOD]->(m1:Method)-[s:CALLS]->(m2:Method), (c2:Class)-[r2:CLASS_OWNS_METHOD]->(m2) where id(c) <> id(c2) with c,m1, count(distinct m2) as method_count, collect(distinct m2.name) as names, collect(distinct c2.name) as class_names, count(distinct c2) as class_count  where ((method_count >= \(self.maxNumberOfShortMemoryCap) and class_count/method_count <= \(self.halfCouplingDispersion)) or (method_count >= \(self.fewCouplingIntensity) and class_count/method_count <= \(self.quarterCouplingDispersion))) and m1.max_nesting_depth >= \(self.shallowMaximumNestingDepth) return distinct(m1.app_key) as app_key, count(m1) as number_of_smells"
    }
    
    var detailedResultString: String {
        return "match (c:Class)-[r:CLASS_OWNS_METHOD]->(m1:Method)-[s:CALLS]->(m2:Method), (c2:Class)-[r2:CLASS_OWNS_METHOD]->(m2) where id(c) <> id(c2) with c,m1, count(distinct m2) as method_count, collect(distinct m2.name) as names, collect(distinct c2.name) as class_names, count(distinct c2) as class_count  where ((method_count >= 7 and class_count/method_count <= 0.5) or (method_count >= 2 and class_count/method_count <= 0.25)) and m1.max_nesting_depth >= 1 return m1.app_key as app_key, m1.name as method_name, c.name as class_name, method_count as method_count, class_count as class_count"
    }
    
    var notes: String {
        return ""
    }
    
    
}
