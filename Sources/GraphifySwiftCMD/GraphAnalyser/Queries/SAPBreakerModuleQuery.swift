//
//  SAPBreakerModuleQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 04/11/2019.
//

import Foundation

class SAPBreakerModuleQuery: Query {
    var name = "SAPBreakerModule"
    let allowedDistanceFromMain = 0.5
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (module:Module)
        match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)
        match (app:App)-[:APP_OWNS_MODULE]->(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
        where (other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and module <> other_module
        with count(distinct other_class) as number_of_dependant_classes, module
        with module, number_of_dependant_classes as efferent_coupling_number

        match (module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)
        match (other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
        where (class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and module <> other_module
        with count(distinct other_class) as afferent_coupling_number, module, efferent_coupling_number
        with efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, afferent_coupling_number, efferent_coupling_number, module

        optional match (module)-[:MODULE_OWNS_CLASS]->(class:Class)
        where class.is_interface
        with count(distinct class)/module.number_of_classes as abstractness_number, instability_number, afferent_coupling_number, efferent_coupling_number, module
        with 1 - (abstractness_number + instability_number)^2 as difference_from_main, instability_number, abstractness_number, module

        where difference_from_main < -\(self.allowedDistanceFromMain) or difference_from_main > \(self.allowedDistanceFromMain)
        return module.app_key as app_key, module.name as module_name, instability_number, abstractness_number, difference_from_main
        """
    }
    
    var appString: String {
        return """
        match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)
        match (app:App)-[:APP_OWNS_MODULE]->(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
        where (other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and module <> other_module
        with count(distinct other_class) as number_of_dependant_classes, module
        with module, number_of_dependant_classes as efferent_coupling_number

        match (module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)
        match (other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
        where (class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and module <> other_module
        with count(distinct other_class) as afferent_coupling_number, module, efferent_coupling_number
        with efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, afferent_coupling_number, efferent_coupling_number, module

        optional match (module)-[:MODULE_OWNS_CLASS]->(class:Class)
        where class.is_interface
        with count(distinct class)/module.number_of_classes as abstractness_number, instability_number, afferent_coupling_number, efferent_coupling_number, module
        with 1 - (abstractness_number + instability_number)^2 as difference_from_main, instability_number, abstractness_number, module

        where difference_from_main < - \(self.allowedDistanceFromMain) or difference_from_main > \(self.allowedDistanceFromMain)
        return distinct(module.app_key) as app_key, count(distinct module) as number_of_smells
        """
    }
    
    var notes: String {
        return ""
    }
    
}
