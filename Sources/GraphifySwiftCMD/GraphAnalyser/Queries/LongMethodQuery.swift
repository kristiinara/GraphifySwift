//
//  LM.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class LongMethodQuery : Query {
    let name = "LongMethod"
    var veryHighNumberOfInstructions = Metrics.veryHighNumberOfInstructionsMethod
    
    var string: String {
        return "MATCH (c:Class)-[r:CLASS_OWNS_METHOD]->(m:Method) WHERE m.number_of_instructions > \(self.veryHighNumberOfInstructions) RETURN m.app_key as app_key, c.name as class_name, m.name as method_name, m.number_of_instructions as number_of_instructions, c.data_string as main_text, m.data_string as affected_text"
    }
    
    var appString: String {
        return "MATCH (c:Class)-[r:CLASS_OWNS_METHOD]->(m:Method) WHERE m.number_of_instructions > \(self.veryHighNumberOfInstructions) RETURN distinct(m.app_key) as app_key, count(distinct m) as number_of_smells"
    }
    
    var result: String?
    var json: [String : Any]?
    
    var notes: String {
        return "Long Method code smell looks at methods where number of instructions is bigger than very high. Very high number of instructions has to be defined statistically."
    }
}
