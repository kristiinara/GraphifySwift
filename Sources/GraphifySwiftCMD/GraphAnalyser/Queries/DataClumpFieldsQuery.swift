//
//  DataClumpFieldsQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 23/10/2019.
//

import Foundation

class DataClumpFieldsQuery: Query {
    var name = "DataClumpFields"
    let highNumberOfRepeatingVariables = 3
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
        match
        (app)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_VARIABLE]->(other_variable:Variable)
        where class <> other_class and variable.type = other_variable.type and variable.name = other_variable.name
        with app, class, other_class, variable order by variable.name with app, class, other_class, collect(distinct variable.name) as variable_names, count(DISTINCT variable) as variable_count
        with app, class, other_class, variable_names, variable_count order by id(class)
        with app, collect(distinct id(other_class)) + id(class) as class_ids, variable_names, variable_count
        where variable_count >= \(highNumberOfRepeatingVariables)
        match (app)-[:APP_OWNS_MODULE]->(:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
        where id(class) in class_ids and variable.name in variable_names
        with app, class, variable, variable_count, variable_names order by variable.name
        with app, class, collect(distinct variable.name) as new_variable_names, variable_count, variable_names
        with app, collect(distinct class.name) as new_class_names, new_variable_names, variable_count
        return distinct app.app_key as app_key,  new_class_names as class_names, new_variable_names as variable_names, variable_count
        """
    }
    
    var appString: String {
        return """
            match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
            match
            (app)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_VARIABLE]->(other_variable:Variable)
            where class <> other_class and variable.type = other_variable.type and variable.name = other_variable.name
            with app, class, other_class, variable order by variable.name
            with app, class, other_class, collect(distinct variable.name) as variable_names, count(DISTINCT variable) as variable_count
            with app, class, other_class, variable_names, variable_count order by id(class)
            with app, collect(distinct class.name) as class_names, variable_names, variable_count
            where variable_count >= \(highNumberOfRepeatingVariables)
            return distinct(app.app_key) as app_key, count(distinct class_names) as number_of_smells
        """
    }
    
    var notes: String {
        return "Queries classes that have at least 3 variables with the same name and type. Second part of query takes care of repeating rows."
    }
}
