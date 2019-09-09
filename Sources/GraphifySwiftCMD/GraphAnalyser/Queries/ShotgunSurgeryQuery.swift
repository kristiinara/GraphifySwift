//
//  ShotgunSurgery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class ShotgunSurgeryQuery: Query {
    var name = "ShotgunSurgery"
    let veryHighNumberOfCallers = 2 //TODO: find an appropriate number
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (other_m:Method)-[r:CALLS]->(m:Method) with m, COUNT(r) as number_of_callers where number_of_callers > \(self.veryHighNumberOfCallers) RETURN m.name as name, m.app_key as app_key, number_of_callers as number_of_callers"
    }
    
    var notes: String {
        return "Shotgun surgery code smell looks at methods where the number of callers is bigger than very high. Very high number of callers needs to be defined statistically."
    }
}
