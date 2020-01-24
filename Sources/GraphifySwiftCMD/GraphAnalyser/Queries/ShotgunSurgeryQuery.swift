//
//  ShotgunSurgery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class ShotgunSurgeryQuery: Query {
    var name = "ShotgunSurgery"
    let veryHighNumberOfCallers = Metrics.veryHighNumberOfCallers 
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (other_m:Method)-[r:CALLS]->(m:Method)<-[:CLASS_OWNS_METHOD]-(c:Class) with c,m, COUNT(r) as number_of_callers where number_of_callers > \(self.veryHighNumberOfCallers) RETURN m.app_key as app_key, c.name as class_name, m.name as method_name, number_of_callers as number_of_callers, c.data_string as main_text, m.data_string as affected_text"
    }
    
    var appString: String {
        return "MATCH (other_m:Method)-[r:CALLS]->(m:Method)<-[:CLASS_OWNS_METHOD]-(c:Class) with c,m, COUNT(r) as number_of_callers where number_of_callers > \(self.veryHighNumberOfCallers) RETURN distinct(m.app_key) as app_key,count(distinct m) as number_of_smells"
    }
    
    var notes: String {
        return "Shotgun surgery code smell looks at methods where the number of callers is bigger than very high. Very high number of callers needs to be defined statistically."
    }
}
