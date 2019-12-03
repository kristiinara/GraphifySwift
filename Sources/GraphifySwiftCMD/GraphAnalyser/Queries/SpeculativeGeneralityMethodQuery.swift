//
//  SpeculativeGeneralityMethodQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 24/10/2019.
//

import Foundation

class SpeculativeGeneralityMethodQuery: Query {
    var name = "SpeculativeGeneralityMethod"

    var result: String?
    var json: [String : Any]?

    var string: String {
        return "match  (class)-[:CLASS_OWNS_METHOD]->(m:Method)-[:METHOD_OWNS_ARGUMENT]->(p:Argument)-[:IS_OF_TYPE]->(other_class:Class) where not (m)-[:CALLS|USES]->()<-[:CLASS_OWNS_VARIABLE|CLASS_OWNS_METHOD]-(other_class) and not m.data_string contains (\"=\" + p.name) and not m.data_string contains (\"= \" + p.name) and not m.data_string contains (\":\" + p.name) and not m.data_string contains (\": \" + p.name) and not m.data_string contains (\"(\" + p.name + \")\") and not m.data_string contains (\"(\" + p.name + \",\") and not m.data_string contains (\", \" + p.name + \")\") and not m.data_string contains (\", \" + p.name + \",\") and class.is_interface = false return class.app_key as app_key, class.name as class_name, m.name as method_name, p.name as argument_name, m.data_string as main_text, p.name as affected_text"
    }
    
    var appString: String {
        return "match  (class)-[:CLASS_OWNS_METHOD]->(m:Method)-[:METHOD_OWNS_ARGUMENT]->(p:Argument)-[:IS_OF_TYPE]->(other_class:Class) where not (m)-[:CALLS|USES]->()<-[:CLASS_OWNS_VARIABLE|CLASS_OWNS_METHOD]-(other_class) and not m.data_string contains (\"=\" + p.name) and not m.data_string contains (\"= \" + p.name) and not m.data_string contains (\":\" + p.name) and not m.data_string contains (\": \" + p.name) and not m.data_string contains (\"(\" + p.name + \")\") and not m.data_string contains (\"(\" + p.name + \",\") and not m.data_string contains (\", \" + p.name + \")\") and not m.data_string contains (\", \" + p.name + \",\") and class.is_interface = false return distinct(class.app_key) as app_key, count(distinct m) as number_of_smells"
    }

    var notes: String {
        return "Tries to query methods where arguments are not used by querying for arguments where the method does not call or use any variable/method in the class of the arguments type. Does not work correctly as there are no references to setting variables."
    }
}
