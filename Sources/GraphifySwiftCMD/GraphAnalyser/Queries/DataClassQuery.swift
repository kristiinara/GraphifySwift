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
        return "match (c:Class) where c.number_of_methods = 0 return c.name as name, c.app_key as app_key, c.number_of_attributes as number_of_attributes"
    }
    
    var notes: String {
        return "Data Class code smell checks for classes that have no methods."
    }
}
