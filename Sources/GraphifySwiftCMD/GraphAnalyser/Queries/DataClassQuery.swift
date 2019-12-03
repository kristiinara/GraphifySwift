//
//  DataClass.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class DataClassQuery: Query {
    var name = "DataClass"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class) where c.number_of_methods = 0 return c.app_key as app_key, c.name as class_name, c.number_of_attributes as number_of_attributes, c.data_string as main_text"
    }
    
    var appString: String {
        return "match (c:Class) where c.number_of_methods = 0 return distinct(c.app_key) as app_key, count(distinct c) as number_of_smells"
    }
    
    var notes: String {
        return "Data Class code smell checks for classes that have no methods."
    }
}
