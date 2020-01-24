//
//  MiddleManQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 24/10/2019.
//

import Foundation

class MiddleManQuery: Query {
    var name = "MiddleMan"
    let smallNumberOfLines = Metrics.lowNumberOfInstructionsMethod
    let delegationToAllMethodsRatioHalf = 0.5
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:USES|CALLS]->(ref)<-[:CLASS_OWNS_VARIABLE|CLASS_OWNS_METHOD]-(other_class:Class) where class <> other_class and method.number_of_instructions < \(self.smallNumberOfLines) with class, method, collect(ref.name) as referenced_names, collect(other_class.name) as class_names with collect(method.name) as method_names, collect(referenced_names) as references, collect(class_names) as classes, collect(method.number_of_instructions) as numbers_of_instructions, class , count(method) as method_count, count(method)*1.0/class.number_of_methods as method_ratio where method_ratio > \(self.delegationToAllMethodsRatioHalf)  return class.app_key as app_key, class.name as class_name, method_names, classes, numbers_of_instructions, method_ratio, class.data_string as main_text"
    }
    
    var appString: String {
        return "match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:USES|CALLS]->(ref)<-[:CLASS_OWNS_VARIABLE|CLASS_OWNS_METHOD]-(other_class:Class) where class <> other_class and method.number_of_instructions < \(self.smallNumberOfLines) with class, method, collect(ref.name) as referenced_names, collect(other_class.name) as class_names with collect(method.name) as method_names, collect(referenced_names) as references, collect(class_names) as classes, collect(method.number_of_instructions) as numbers_of_instructions, class , count(method) as method_count, count(method)*1.0/class.number_of_methods as method_ratio where method_ratio > \(self.delegationToAllMethodsRatioHalf) return distinct(class.app_key) as app_key, count(class) as number_of_smells"
    }
    
    var notes: String {
        return "Querying all classes where more than half of the methods are delegation methods.  Delegation methods are methods that have at least one reference (uses/calles) to another class but have less than a small number of lines."
    }
}
