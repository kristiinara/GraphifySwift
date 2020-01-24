//
//  ComplexClassPaprikaQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 30/11/2019.
//

import Foundation


class ComplexClassPaprikaQuery: Query {
    var name = "ComplexClassPaprika"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (cl:Class) WHERE cl.class_complexity > \(Metrics.veryHighClassComplexity) RETURN cl.app_key as app_key"
    }
    
    var appString: String {
        return "MATCH (cl:Class) WHERE cl.class_complexity > \(Metrics.veryHighClassComplexity) RETURN distinct(cl.app_key) as app_key, count(distinct cl) as number_of_smells"
    }
    
    var notes: String {
        return ""
    }
}
