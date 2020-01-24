//
//  SwissArmyKnifeQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/11/2019.
//

import Foundation

class SwissArmyKnifeQuery: Query {
    let name = "SwissArmyKnife"
    let veryHighNumberOfMethods = Metrics.veryHighNumberOfMethodsInterface
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (cl:Class) WHERE cl.is_interface AND cl.number_of_methods > \(veryHighNumberOfMethods) RETURN cl.app_key as app_key, cl.name as class_name, cl.number_of_methods as number_of_methods"
    }
    
    var appString: String {
        return "MATCH (cl:Class) WHERE cl.is_interface AND cl.number_of_methods > \(veryHighNumberOfMethods) RETURN distinct(cl.app_key) as app_key, count(distinct cl) as number_of_smells"
    }
    
    var notes: String {
        return "Queries protocols with a very high number of methods. "
    }
}
