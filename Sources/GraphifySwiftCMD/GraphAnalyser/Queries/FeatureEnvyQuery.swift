//
//  FeatureEnvyQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 22/10/2019.
//

import Foundation

class FeatureEnvyQuery: Query {
    var name = "FeatureEnvy"
    let fewAccessToForeignVariables = 2
    let fewAccessToForeignClasses = 2
    let localityFraction = 0.33
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        MATCH  (class:Class)-[:CLASS_OWNS_METHOD]->(m:Method)-[:USES]->(v:Variable)<-[:CLASS_OWNS_VARIABLE]-(other_class:Class)
        WHERE class <> other_class
        WITH
            class, m,
            count(distinct v) as variable_count,
            collect(distinct v.name) as names,
            collect(distinct other_class.name) as class_names,
            count(distinct other_class) as class_count
        MATCH (class)-[:CLASS_OWNS_METHOD]->(m)-[:USES]->(v:Variable)<-[:CLASS_OWNS_VARIABLE]-(class)
        WITH
            class, m, variable_count, class_names, names,
            count(distinct v) as local_variable_count,
            collect(distinct v.name) as local_names,
            class_count
        WHERE
            local_variable_count + variable_count > 0
        WITH
            class, m, variable_count, class_names, names, local_variable_count, local_names, class_count,
            local_variable_count*1.0/(local_variable_count+variable_count) as locality
        WHERE
        variable_count > \(self.fewAccessToForeignVariables) and locality < \(self.localityFraction) and class_count <= \(self.fewAccessToForeignClasses)
        RETURN
            class.app_key as app_key, class.name as class_name, m.name as method_name, variable_count,class_count,names as foreign_variable_names, class_names, local_variable_count, local_names as local_variable_names, locality, class.data_string as main_text, m.data_string as affected_text
        """
    }
    
    var appString: String {
        return """
            MATCH  (class:Class)-[:CLASS_OWNS_METHOD]->(m:Method)-[:USES]->(v:Variable)<-[:CLASS_OWNS_VARIABLE]-(other_class:Class)
            WHERE class <> other_class
            WITH
                class, m,
                count(distinct v) as variable_count,
                collect(distinct v.name) as names,
                collect(distinct other_class.name) as class_names,
                count(distinct other_class) as class_count
            MATCH (class)-[:CLASS_OWNS_METHOD]->(m)-[:USES]->(v:Variable)<-[:CLASS_OWNS_VARIABLE]-(class)
            WITH
                class, m, variable_count, class_names, names,
                count(distinct v) as local_variable_count,
                collect(distinct v.name) as local_names,
                class_count
            WHERE
                local_variable_count + variable_count > 0
            WITH
                class, m, variable_count, class_names, names, local_variable_count, local_names, class_count,
                local_variable_count*1.0/(local_variable_count+variable_count) as locality
            WHERE
                variable_count > \(self.fewAccessToForeignVariables) and locality < \(self.localityFraction) and class_count <= \(self.fewAccessToForeignClasses)
            RETURN
                distinct(class.app_key) as app_key, count(distinct m) as number_of_smells
        """
    }
    
    var notes: String {
        return "Queries classes that tend to access more foreign variables than local variables."
    }
}
