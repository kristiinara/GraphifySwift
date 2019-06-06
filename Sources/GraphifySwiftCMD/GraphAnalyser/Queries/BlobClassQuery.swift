//
//  BlobClass.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class BlobClassQuery : Query {
    let veryHighLackOfCohesienInMethods = 40
    let veryHighNumberOfAttributes = 13
    let veryHighNumberOfMethods = 22
    
    var string: String {
        return """
        MATCH (cl:Class) WHERE
            cl.lack_of_cohesion_in_methods > \(self.veryHighLackOfCohesienInMethods) AND
            cl.number_of_methods >  \(self.veryHighNumberOfMethods) AND
            cl.number_of_attributes > \(self.veryHighNumberOfMethods)
        RETURN cl.name as class_name, cl.app_key as app_key
        """
    }
    
    var result: String?
}
