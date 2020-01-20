//
//  PrimitiveObsessionQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 05/11/2019.
//

import Foundation

class PrimitiveObsessionQuery: Query {
    let name = "PrimitiveObsession"
    let veryHighPrimitiveVariableUse = Metrics.veryHighPrimitiveVariableUse
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (class:Class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)<-[use:USES]-(method:Method)
        where not (variable)-[:IS_OF_TYPE]->()
        with collect(distinct method.name) as uses, count(distinct use) as use_count, variable, class
        where use_count > \(self.veryHighPrimitiveVariableUse)

        return class.app_key, class.name, variable.name, variable.type, uses, use_count, class.data_string as main_text, variable.data_string as affected_text
        """
    }
    
    var appString: String {
        return """
        match (class:Class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)<-[use:USES]-(method:Method)
        where not (variable)-[:IS_OF_TYPE]->()
        with collect(distinct method.name) as uses, count(distinct use) as use_count, variable, class
        where use_count > \(self.veryHighPrimitiveVariableUse)

        return distinct(class.app_key) as app_key, count(distinct variable) as number_of_smells
        """
    }
    
    var notes: String {
        return "Query variables whose types are not types of this application and that are used often by methods."
    }
}
