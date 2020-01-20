//
//  BlobClass.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class BlobClassQuery : Query {
    let name = "BlobClass"
    let veryHighLackOfCohesienInMethods = Metrics.veryHighLackOfCohesionInMethods
    let veryHighNumberOfAttributes = Metrics.veryHighNumberOfAttributes
    let veryHighNumberOfMethods = Metrics.veryHighNumberOfMethods
    
    var string: String {
        return """
        MATCH (cl:Class) WHERE
            cl.lack_of_cohesion_in_methods > \(self.veryHighLackOfCohesienInMethods) AND
            cl.number_of_methods >  \(self.veryHighNumberOfMethods) AND
            cl.number_of_attributes > \(self.veryHighNumberOfAttributes)
        RETURN cl.app_key as app_key, cl.name as class_name, cl.lack_of_cohesion_in_methods as lack_of_cohesion_in_methods, cl.number_of_methods as number_of_methods, cl.number_of_attributes as number_of_attributes, cl.data_string as main_text
        """
    }
    
    var appString: String {
        return """
        MATCH (cl:Class) WHERE
            cl.lack_of_cohesion_in_methods > \(self.veryHighLackOfCohesienInMethods) AND
            cl.number_of_methods >  \(self.veryHighNumberOfMethods) AND
            cl.number_of_attributes > \(self.veryHighNumberOfAttributes)
        RETURN distinct cl.app_key as app_key, count(distinct cl) as number_of_smells
        """
    }
    
    var result: String?
    var json: [String : Any]?
    
    var notes: String {
        return "Blob class code smell uses lackOfCohesionInMethods, NumberOfMethods and NumberOfAttributes. Code smell is present if allthese values are high. What is high needs to be determined statistically."
    }
}
