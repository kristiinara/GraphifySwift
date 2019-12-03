//
//  InfoQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 21/10/2019.
//

import Foundation

class InfoQuery: Query {
    var name = "Info"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (a:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(c:Class) optional match (c)-[:CLASS_OWNS_METHOD]->(m:Method) optional match (c)-[:CLASS_OWNS_VARIABLE]->(v:Variable) with a, count(distinct c) as number, count(distinct m) as methods, count(distinct v) as variables, count(distinct module) as modules return a.app_key as app_key, a.name as name, modules as number_of_modules, a.number_of_classes as number_of_classes, a.number_of_interfaces as number_of_interfaces, number as number_of_types, methods as number_of_methods, variables as number_of_variables, a.date_download as date_download, a.developer as developer, a.number_of_tests as number_of_tests, a.number_of_ui_tests as number_of_ui_tests, a.in_app_store as in_app_store"
    }
    
    var appString: String {
        return "match (a:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(c:Class) optional match (c)-[:CLASS_OWNS_METHOD]->(m:Method) optional match (c)-[:CLASS_OWNS_VARIABLE]->(v:Variable) with a, count(distinct c) as number, count(distinct m) as methods, count(distinct v) as variables, count(distinct module) as modules return a.app_key as app_key, a.name as name, modules as number_of_modules, a.number_of_classes as number_of_classes, a.number_of_interfaces as number_of_interfaces, number as number_of_types, methods as number_of_methods, variables as number_of_variables, a.date_download as date_download, a.developer as developer, a.number_of_tests as number_of_tests, a.number_of_ui_tests as number_of_ui_tests, a.in_app_store as in_app_store"
    }
    
    var notes: String {
        return "Not a code smell. Returns basic info about a class for statistics purposes."
    }
    
    
}
