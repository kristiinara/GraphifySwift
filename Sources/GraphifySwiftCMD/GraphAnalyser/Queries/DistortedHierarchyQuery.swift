//
//  DistortedHierarchyQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class DistortedHierarchyQuery: Query {
    var name = "DistortedHierarchy"
    let shortTermMemoryCap = Metrics.shorTermMemoryCap
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class) where c.depth_of_inheritance > \(self.shortTermMemoryCap)  return c.app_key as app_key, c.name as class_name, c.depth_of_inheritance as dept_of_inheritance"
    }
    
    var appString: String {
        return "match (c:Class) where c.depth_of_inheritance > \(self.shortTermMemoryCap) return distinct(c.app_key) as app_key, count(distinct c) as number_of_smells"
    }
    
    var notes: String {
        return "Finds all classes where depthOfInheritance is larger than the short term memory cap, currently set to 6. Might make sense to figure out if this threshold is appropriate."
    }
    
    
}
