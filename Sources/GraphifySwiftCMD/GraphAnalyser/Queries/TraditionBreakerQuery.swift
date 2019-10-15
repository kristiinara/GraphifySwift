//
//  TraditionBreakerQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class TraditionBreakerQuery: Query {
    var name = "TraditionBreaker"
    let highNumberOfMethodsAndAttributes = 20
    let lowNumberOfmethodsAndAttributes = 5
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class)-[r:EXTENDS]->(parent:Class) where not ()-[:EXTENDS]->(c) and c.number_of_methods+c.number_of_attributes < \(self.lowNumberOfmethodsAndAttributes) and parent.number_of_methods + parent.number_of_attributes >= \(self.highNumberOfMethodsAndAttributes) return c.app_key as app_key, c.name as child_name, parent.name as parent_name"
    }
    
    var notes: String {
        return "Queries for classes that: 'A class that inherits from a large parent class but that provides little behaviour and without subclasses.' Different sources have different definitions. Figure out if this makes sense. Low number of methods and attributes and high number of methods and attributes need to be determined statistically with the boxplot technique."
    }
    
    
}
