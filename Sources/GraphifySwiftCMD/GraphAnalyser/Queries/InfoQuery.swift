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
    
    var classString: String {
        return """
        match (class:Class)
        return
        class.app_key as app_key,
        class.name as class_name,
        class.number_of_methods as number_of_methods,
        class.number_of_attributes as number_of_attributes,
        class.class_complexity as class_complexity,
        exists(class.is_init) as is_init,
        class.number_of_instructions as number_of_instructions,
        class.depth_of_inheritance as depth_of_inheritance,
        class.coupling_between_object_classes as coupling_between_object_classes,
        class.lack_of_cohesion_in_methods as lack_of_cohesion_in_methods, class.number_of_implemented_interfaces as number_of_implemented_interfaces
    """
    }
    
    var notes: String {
        return "Not a code smell. Returns basic info about a class for statistics purposes."
    }
    
    
}
