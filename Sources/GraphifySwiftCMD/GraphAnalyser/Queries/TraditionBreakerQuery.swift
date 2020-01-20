//
//  TraditionBreakerQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class TraditionBreakerQuery: Query {
    var name = "TraditionBreaker"
    let veryHighNumberOfMethodsAndAttributes = Metrics.veryHighNumberOfMethodsAndAttributes
    let lowNumberOfmethodsAndAttributes = Metrics.lowNumberOfMethodsAndAttributes
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class)-[r:EXTENDS]->(parent:Class) where not ()-[:EXTENDS]->(c) and c.number_of_methods+c.number_of_attributes < \(self.lowNumberOfmethodsAndAttributes) and parent.number_of_methods + parent.number_of_attributes >= \(self.veryHighNumberOfMethodsAndAttributes) return c.app_key as app_key, c.name as class_name, parent.name as parent_class_name"
    }
    
    var appString: String {
        return "match (c:Class)-[r:EXTENDS]->(parent:Class) where not ()-[:EXTENDS]->(c) and c.number_of_methods+c.number_of_attributes < \(self.lowNumberOfmethodsAndAttributes) and parent.number_of_methods + parent.number_of_attributes >= \(self.veryHighNumberOfMethodsAndAttributes) return distinct(c.app_key) as app_key, count(distinct c) as number_of_smells"
    }
    
    var notes: String {
        return "Queries for classes that: 'A class that inherits from a large parent class but that provides little behaviour and without subclasses.' Different sources have different definitions. Figure out if this makes sense. Low number of methods and attributes and high number of methods and attributes need to be determined statistically with the boxplot technique."
    }
    
    
}
