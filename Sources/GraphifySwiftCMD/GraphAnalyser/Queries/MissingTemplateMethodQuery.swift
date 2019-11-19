//
//  MissingTemplateMethodQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/11/2019.
//

import Foundation

class MissingTemplateMethodQuery: Query {
    let name = "MissingTemplateMethod"
    let minimalCommonMethodAndVariableCount = 5
    let minimalMethodCount = 2
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
        match (other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
        optional match (method)-[:USES]->(common_variable:Variable)<-[:USES]-(other_method)
        optional match (method)-[:CALLS]->(common_method:Method)<-[:CALLS]-(other_method)
                where
                    class.app_key = other_class.app_key and
                    method <> other_method
                with
                    collect(distinct common_variable) as common_variables,
                    collect(distinct common_method) as common_methods,
                    count(distinct common_variable) as common_variable_count,
                    count(DISTINCT common_method) as common_method_count,
                    class, other_class, method, other_method
               where
                    common_variable_count + common_method_count >= \(self.minimalCommonMethodAndVariableCount)
               with
                    [variable in common_variables | class.name+"."+variable.name] as common_variable_names,
                    [common_method in common_methods | class.name+"."+common_method.name] as common_method_names,
                    class, other_class, method, other_method, common_variable_count, common_method_count
               with
                    collect(class.name) as class_names,
                    collect(class.name + "." + method.name) as method_names,
                    count(distinct method) as method_count,
                    class.app_key as app_key,
                    common_variable_count, common_method_count,
                    common_variable_names,common_method_names
            where
                method_count >= \(self.minimalMethodCount)
        return app_key, class_names, method_names, common_variable_count, common_method_count, common_variable_names, common_method_names
        """
        
        /* query that I used for debugging
         match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
         match (other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
         optional match (method)-[:USES]->(common_variable:Variable)<-[:USES]-(other_method)
         optional match (method)-[:CALLS]->(common_method:Method)<-[:CALLS]-(other_method)
                 where
                     class.app_key = other_class.app_key and
                     method <> other_method
                 with
                     collect(distinct common_variable) as common_variables,
                     collect(distinct common_method) as common_methods,
                     count(distinct common_variable) as common_variable_count,
                     count(DISTINCT common_method) as common_method_count,
                     class, other_class, method, other_method
                where
                     common_variable_count + common_method_count >= 5
                with
                     [variable in common_variables | class.name+"."+variable.name] as common_variable_names,
                     [common_method in common_methods | class.name+"."+common_method.name] as common_method_names,
                     class, other_class, method, other_method, common_variable_count, common_method_count,
                     [variable in common_variables | id(variable)] as common_variable_ids,
                     [method in common_methods | id(method)] as common_method_ids
                with
                     collect(distinct class.name) as class_names,
                     collect(distinct class.name + "." + method.name) as method_names,
                     count(distinct method) as method_count,
                     class.app_key as app_key,
                     common_variable_count, common_method_count,
                     common_variable_names,common_method_names,
                     collect(DISTINCT id(class)) as ids,
                     common_method_ids,
                     common_variable_ids,
                     collect(distinct id(method)) as method_ids
             where
                 method_count >= 2
         return ids, app_key, class_names, method_ids,method_names, common_variable_count, common_method_count, common_variable_names, common_method_names, common_method_ids, common_variable_ids
         */
    }
    
    var notes: String {
        return ""
    }
}
