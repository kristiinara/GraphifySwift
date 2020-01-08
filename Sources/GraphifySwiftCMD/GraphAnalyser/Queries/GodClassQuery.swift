//
//  GodClassQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 01/11/2019.
//

import Foundation

class GodClassQuery: Query {
    let name = "GodClass"
    let fewAccessToForeignData = 2
    let veryHighClassComplexity = Metrics.veryHighClassComplexity
    let tightClassCohesionFraction = 0.3
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
        match (class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
        where method <> other_method
        with count(DISTINCT [method, other_method]) as pair_count, class
        match (class)-[:CLASS_OWNS_METHOD]->(method:Method)
        match (class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
        match (class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
        where method <> other_method and (method)-[:USES]->(variable)<-[:USES]-(other_method)
        with class, pair_count, method, other_method, collect(distinct variable.name) as variable_names, count(distinct variable) as variable_count
        where variable_count >= 1
        with class, pair_count, count(distinct [method, other_method]) as connected_method_count
        with class, connected_method_count*0.1/pair_count as class_cohesion, connected_method_count, pair_count
        where class_cohesion < \(self.tightClassCohesionFraction) and class.class_complexity >= \(self.veryHighClassComplexity)
        optional match (class)-[:CLASS_OWNS_METHOD]->(m:Method)-[:USES]->(variable:Variable)<-[:CLASS_OWNS_VARIABLE]-(other_class:Class)
        where class <> other_class
        with class, class_cohesion, connected_method_count, pair_count, count(distinct variable) as foreign_variable_count
        where foreign_variable_count >= \(self.fewAccessToForeignData)
        return class.app_key as app_key, class.name as class_name, pair_count, connected_method_count, class_cohesion, class.class_complexity as class_complexity, foreign_variable_count, class.data_string as main_text
        """
    }
    
    var appString: String {
        return """
        match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
        match (class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
        where method <> other_method
        with count(DISTINCT [method, other_method]) as pair_count, class
        match (class)-[:CLASS_OWNS_METHOD]->(method:Method)
        match (class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
        match (class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
        where method <> other_method and (method)-[:USES]->(variable)<-[:USES]-(other_method)
        with class, pair_count, method, other_method, collect(distinct variable.name) as variable_names, count(distinct variable) as variable_count
        where variable_count >= 1
        with class, pair_count, count(distinct [method, other_method]) as connected_method_count
        with class, connected_method_count*0.1/pair_count as class_cohesion, connected_method_count, pair_count
        where class_cohesion < \(self.tightClassCohesionFraction) and class.class_complexity >= \(self.veryHighClassComplexity)
        optional match (class)-[:CLASS_OWNS_METHOD]->(m:Method)-[:USES]->(variable:Variable)<-[:CLASS_OWNS_VARIABLE]-(other_class:Class)
        where class <> other_class
        with class, class_cohesion, connected_method_count, pair_count, count(distinct variable) as foreign_variable_count
        where foreign_variable_count >= \(self.fewAccessToForeignData)
        return distinct(class.app_key) as app_key, count(distinct class) as number_of_smells
        """
    }
    
    var notes: String {
        return "Query classes with a tight class cohesion of less than a third, very high number of weighted methods and at least few access to foreign data variables."
    }
    
    
}
