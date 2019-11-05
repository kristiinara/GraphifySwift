//
//  UnstableDependenciesQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 05/11/2019.
//

import Foundation

class UnstableDependenciesQuery: Query {
    let name = "UnstableDependencies"
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
            match (class:Class)
                match (other_class:Class)
                where (other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and class <> other_class
                with count(distinct other_class) as number_of_dependant_classes, class
                with class, number_of_dependant_classes as efferent_coupling_number

                match (class:Class)
                match (other_class:Class)
                where (class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and class <> other_class
                with count(distinct other_class) as afferent_coupling_number, class, efferent_coupling_number
                with efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, class, afferent_coupling_number, efferent_coupling_number

        match (comparison_class:Class)
        where (comparison_class)-[:CLASS_OWNS_METHOD]->(:Method)-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and comparison_class <> class

                match (other_class:Class)
                where (other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(comparison_class) and comparison_class <> other_class
                with count(distinct other_class) as number_of_dependant_classes2, comparison_class, class, instability_number
                with comparison_class, number_of_dependant_classes2 as efferent_coupling_number2, class, instability_number

                match (comparison_class:Class)
                match (other_class:Class)
                where (comparison_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and comparison_class <> other_class
                with count(distinct other_class) as afferent_coupling_number2, comparison_class, efferent_coupling_number2, class, instability_number
                with efferent_coupling_number2*1.0/(efferent_coupling_number2 + afferent_coupling_number2) as instability_number2, comparison_class, afferent_coupling_number2, efferent_coupling_number2, class, instability_number
                
                where instability_number2 < instability_number

                return comparison_class.app_key as app_key, comparison_class.name as class_name, class.name as referenced_class_name, instability_number2 as instability_number, instability_number as referenced_instability_number
        """
    }
    
    var notes: String {
        return "Query classes that depend on other classes that are less stable than themselves."
    }
}
