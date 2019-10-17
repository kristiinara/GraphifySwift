//
//  DivergentChangeQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 17/10/2019.
//

import Foundation

class DivergentChangeQuery: Query {
    let name = "DivergentChange"
    let veryHighNumberOfCalledMethods = 20
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (m:Method)-[r:CALLS]->(other_method:Method) with m, COUNT(r) as number_of_called_methods where number_of_called_methods > \(self.veryHighNumberOfCalledMethods) RETURN m.name as name, m.app_key as app_key, number_of_called_methods as number_of_called_methods"
    }
    
    var notes: String {
        return "Queries all methods that call more than a very high number of methods. Very high number of methods currently set to 20."
    }
}
