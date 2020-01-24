//
//  DataClumpArgumentsQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 23/10/2019.
//

import Foundation

class DataClumpArgumentsQuery: Query {
    var name = "DataClumpArguments"
    let highNumberOfRepeatingArguments = 3
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match        (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
        match
        (app)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)-[:METHOD_OWNS_ARGUMENT]->(other_argument:Argument)
        where method <> other_method and argument.name = other_argument.name and argument.type = other_argument.type
        with app, class, other_class, method, other_method, argument order by other_method.name
        with app, class, other_class, method, other_method, argument  order by argument.name
        with collect(argument.name) as argument_names, count(argument.name) as argument_count, method, other_method, app, class
        where argument_count >= \(self.highNumberOfRepeatingArguments)
        with collect(other_method.name)+ method.name as method_names, collect(id(other_method)) + id(method) as method_ids, count(distinct other_method) as method_count,  method, app, argument_names, argument_count, class
        with collect(class.name) as class_names, method_names, app, argument_names, argument_count, method_ids, method_count
        match
        (app)-[:APP_OWNS_MODULE]->(:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
        where id(method) in method_ids and argument.name in argument_names
        with argument, app, method, argument_names, argument_count, class order by argument.name
        with collect(distinct argument.name) as new_argument_names, app, method, argument_names, argument_count, class
        with collect(method.name) as new_method_names, collect(class.name) as class_names, new_argument_names, app, argument_names, argument_count
        return app.app_key as app_key, class_names, new_method_names as method_names, new_argument_names as argument_names, argument_count
        """
    }
    
    var appString: String {
        return """
            match        (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
            match
            (app)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)-[:METHOD_OWNS_ARGUMENT]->(other_argument:Argument)
            where method <> other_method and argument.name = other_argument.name and argument.type = other_argument.type
            with app, class, other_class, method, other_method, argument order by other_method.name
            with app, class, other_class, method, other_method, argument  order by argument.name
            with collect(argument.name) as argument_names, count(argument.name) as argument_count, method, other_method, app, class
            where argument_count >= \(self.highNumberOfRepeatingArguments)
            with collect(other_method.name)+ method.name as method_names, collect(id(other_method)) + id(method) as method_ids, count(distinct other_method) as method_count,  method, app, argument_names, argument_count, class
            with collect(class.name) as class_names, method_names, app, argument_names, argument_count, method_ids, method_count
            match
            (app)-[:APP_OWNS_MODULE]->(:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
            where id(method) in method_ids and argument.name in argument_names
            with argument, app, method, argument_names, argument_count, class order by argument.name
            with collect(distinct argument.name) as new_argument_names, app, method, argument_names, argument_count, class
            with collect(method.name) as new_method_names, collect(class.name) as class_names, new_argument_names, app, argument_names, argument_count
            return distinct(app.app_key) as app_key, count(distinct class_names) as number_of_smells
        """
    }
    
    var notes: String {
        return "Queries methods that have at least 3 arguments with the same name and type. Second part of query takes care of repeating rows."
    }
    
}
