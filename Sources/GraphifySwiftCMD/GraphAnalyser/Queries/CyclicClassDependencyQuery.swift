//
//  CyclicClassDependencyQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 27/09/2019.
//

import Foundation

class CyclicClassDependenciesQuery: Query {
    var name = "CyclicClassDependency"
    
    var string: String {
        return "match (c:Class)-[:CLASS_OWNS_VARIABLE]->(v:Variable)-[:IS_OF_TYPE]->(c2:Class) where c <> c2 match cyclePath=shortestPath((c2)-[:CLASS_OWNS_VARIABLE|:IS_OF_TYPE*]->(c)) with c, v, [n in nodes(cyclePath) | n.name ] as names  return c.app_key as app_key, c.name as class_name, names"
    }
    
    var appString: String {
        return "match (c:Class)-[:CLASS_OWNS_VARIABLE]->(v:Variable)-[:IS_OF_TYPE]->(c2:Class) where c <> c2 match cyclePath=shortestPath((c2)-[:CLASS_OWNS_VARIABLE|:IS_OF_TYPE*]->(c)) with c, v, [n in nodes(cyclePath) | n.name ] as names  return distinct(c.app_key) as app_key, count(distinct c) as number_of_smells"
    }
    
    var detailedResultString: String {
        return "match (c:Class)-[:CLASS_OWNS_VARIABLE]->(v:Variable)-[:IS_OF_TYPE]->(c2:Class) where c <> c2 match cyclePath=shortestPath((c2)-[:CLASS_OWNS_VARIABLE|:IS_OF_TYPE*]->(c)) with c, v, [n in nodes(cyclePath) | n.name ] as names, filter(n in nodes(cyclePath) where not n:Variable) as classes unwind classes as node return c.app_key as app_key, v.name, names as names, max(id(node)), id(v)"
    }
    
    var result: String?
    
    var json: [String : Any]?
    
    var notes: String {
        return ""
    }
}
