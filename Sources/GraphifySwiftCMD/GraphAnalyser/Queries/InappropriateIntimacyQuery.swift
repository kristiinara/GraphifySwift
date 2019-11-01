//
//  InappropriateIntimacyQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 01/11/2019.
//

import Foundation

class InappropriateIntimacyQuery: Query {
    var name = "InappropriateIntimacy"
    let highNumberOfCallsBetweenClasses = 4
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
        match (other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
        match path = (method)-[r:CALLS]-(other_method)
        where  class <> other_class
        with count(distinct r) as number_of_calls, collect(distinct method.name) as method_names, collect(distinct other_method.name) as other_method_names, class, other_class
        where number_of_calls > \(highNumberOfCallsBetweenClasses)
        return class.app_key as app_key, class.name as class_name, other_class.name as other_class_name, method_names, other_method_names, number_of_calls
        """
    }
    
    var notes: String {
        return ""
    }
    
    
}
