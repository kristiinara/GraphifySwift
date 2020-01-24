//
//  SAPBreakerQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 01/11/2019.
//

import Foundation

class SAPBreakerQuery: Query {
    let name = "SAPBreaker"
    let allowedDistanceFromMain = 0.5
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)
        match (app:App)-[:APP_OWNS_MODULE]->(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
        where (other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and class <> other_class
        with count(distinct other_class) as number_of_dependant_classes, class, app
        with class, number_of_dependant_classes as efferent_coupling_number, app

        //match (class:Class)
        match (app)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
        where (class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and class <> other_class
        with count(distinct other_class) as afferent_coupling_number, class, efferent_coupling_number
        with efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, class, afferent_coupling_number, efferent_coupling_number

        optional match (class)-[:CLASS_OWNS_METHOD]->(method:Method)
        where method.is_abstract
        with count(distinct method)/class.number_of_methods as abstractness_number, instability_number, afferent_coupling_number, efferent_coupling_number, class
        with 1 - (abstractness_number + instability_number)^2 as difference_from_main, instability_number, abstractness_number, class

        where difference_from_main < -\(allowedDistanceFromMain) or difference_from_main > \(allowedDistanceFromMain)
        return class.app_key as app_key, class.name as class_name, instability_number, abstractness_number, difference_from_main

        """
    }
    
    var appString: String {
        return """
        match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)
        match (app:App)-[:APP_OWNS_MODULE]->(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
        where (other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and class <> other_class
        with count(distinct other_class) as number_of_dependant_classes, class, app
        with class, number_of_dependant_classes as efferent_coupling_number, app

        //match (class:Class)
        match (app)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
        where (class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and class <> other_class
        with count(distinct other_class) as afferent_coupling_number, class, efferent_coupling_number
        with efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, class, afferent_coupling_number, efferent_coupling_number

        optional match (class)-[:CLASS_OWNS_METHOD]->(method:Method)
        where method.is_abstract
        with count(distinct method)/class.number_of_methods as abstractness_number, instability_number, afferent_coupling_number, efferent_coupling_number, class
        with 1 - (abstractness_number + instability_number)^2 as difference_from_main, instability_number, abstractness_number, class

        where difference_from_main < -\(allowedDistanceFromMain) or difference_from_main > \(allowedDistanceFromMain)
        return distinct(class.app_key) as app_key, count(distinct class) as number_of_smells
        """
    }
    
    var notes: String {
        return ""
    }
}



/*
 match (class:Class)
 match (other_class:Class)
 where (other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class)
 with count(distinct other_class) as number_of_dependant_classes, class
 with class, number_of_dependant_classes as efferent_coupling_number

 match (class:Class)
 match (other_class:Class)
 where (class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class)
 with count(distinct other_class) as afferent_coupling_number, class, efferent_coupling_number
 with efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, class, afferent_coupling_number, efferent_coupling_number

 optional match (class)-[:CLASS_OWNS_METHOD]->(method:Method)
 where method.is_abstract
 with count(distinct method)/class.number_of_methods as abstractness_number, instability_number, afferent_coupling_number, efferent_coupling_number, class
 with 1 - (abstractness_number + instability_number)^2 as difference_from_main, instability_number, abstractness_number, class

 where difference_from_main < -0.5 or difference_from_main > 0.5
 return class.app_key, class.name, instability_number, abstractness_number, difference_from_main
 */
