//
//  BlobClass.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class BlobClassQuery : Query {
    let name = "BlobClass"
    let veryHighLackOfCohesienInMethods = 40
    let veryHighNumberOfAttributes = 13
    let veryHighNumberOfMethods = 22
    
    var string: String {
        return """
        MATCH (cl:Class) WHERE
            cl.lack_of_cohesion_in_methods > \(self.veryHighLackOfCohesienInMethods) AND
            cl.number_of_methods >  \(self.veryHighNumberOfMethods) AND
            cl.number_of_attributes > \(self.veryHighNumberOfMethods)
        RETURN cl.app_key as app_key, cl.name as class_name, cl.lack_of_cohesion_in_methods as lack_of_cohesion_in_methods, cl.number_of_methods as number_of_methods, cl.number_of_attributes as number_of_attributes
        """
    }
    
    var result: String?
    var json: [String : Any]?
    
    var notes: String {
        return "Blob class code smell uses lackOfCohesionInMethods, NumberOfMethods and NumberOfAttributes. Code smell is present if allthese values are high. What is high needs to be determined statistically."
    }
}
