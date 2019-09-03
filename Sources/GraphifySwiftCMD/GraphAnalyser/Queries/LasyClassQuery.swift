//
//  LasyClass.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class LazyClass: Query {
    var name = "LazyClass"
    let mediumNumberOfInstructions = 50
    let lowComplexityMethodRatio = 2
    let mediumCouplingBetweenObjectClasses = 20
    let numberOfSomeDepthOfInheritance = 1
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (c:Class) where c.number_of_methods = 0 or (c.number_of_instructions < \(self.mediumNumberOfInstructions) and  c.number_of_weighted_methods/c.number_of_methods <= \(self.lowComplexityMethodRatio)) or (c.coupling_between_object_classes < \(self.mediumCouplingBetweenObjectClasses) and c.depth_of_inheritance > \(self.numberOfSomeDepthOfInheritance)) return c.name as name, c.app_key as app_key"
    }
}
