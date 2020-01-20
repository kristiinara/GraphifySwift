//
//  InappropriateIntimacyQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 01/11/2019.
//

import Foundation

class InappropriateIntimacyQuery: Query {
    var name = "InappropriateIntimacy"
    let highNumberOfCallsBetweenClasses = Metrics.highNumberOfCallsBetweenClasses
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
        match (app:App)-[:APP_OWNS_MODULE]->(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
        where  class <> other_class
        match path = (method)-[r:CALLS]-(other_method)
        with count(distinct r) as number_of_calls, collect(distinct method.name) as method_names, collect(distinct other_method.name) as other_method_names, class, other_class
        where number_of_calls > \(highNumberOfCallsBetweenClasses)
        return class.app_key as app_key, class.name as class_name, other_class.name as other_class_name, method_names, other_method_names, number_of_calls
        """
    }
    
    var appString: String {
        return """
        match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
        match (app:App)-[:APP_OWNS_MODULE]->(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
        where  class <> other_class
        match path = (method)-[r:CALLS]-(other_method)
        with count(distinct r) as number_of_calls, collect(distinct method.name) as method_names, collect(distinct other_method.name) as other_method_names, class, other_class
        where number_of_calls > \(highNumberOfCallsBetweenClasses)
        return distinct(class.app_key) as app_key, count(class)/2 as number_of_smells
        """
    }
    
    var notes: String {
        return ""
    }
    
    
}
