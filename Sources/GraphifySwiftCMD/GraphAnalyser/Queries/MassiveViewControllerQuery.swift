//
//  MassiveViewControllerQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 30/11/2019.
//

import Foundation

class MassiveViewControllerQuery: Query {
    var name = "MassiveViewController"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (class:Class) where class.name contains 'ViewController' and class.number_of_methods > \(Metrics.veryHighNumberOfMethods) and class.number_of_attributes > \(Metrics.veryHighNumberOfAttributes) and class.number_of_instructions > \(Metrics.veryHighNumberOfInstructionsClass) return class.app_key as app_key, class.name as class_name"
    }
    
    var appString: String {
        return "match (class:Class) where class.name contains 'ViewController' and class.number_of_methods > \(Metrics.veryHighNumberOfMethods) and class.number_of_attributes > \(Metrics.veryHighNumberOfAttributes) and class.number_of_instructions > \(Metrics.veryHighNumberOfInstructionsClass) return distinct(class.app_key) as app_key, count(distinct class) as number_of_smells"
    }
    
    var notes: String {
        return "Def from paper 'Code smells in iOS apps: How do they compare to Android'"
    }
}
