//
//  AlternativeClassesWithDifferentInterfacesQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 05/11/2019.
//

import Foundation

class AlternativeClassesWithDifferentInterfacesQuery: Query {
    let name = "AlternativeClassesWithDifferentInterfaces"
    let minimumCommonMethodCount = 2
    let minimumNumberOfParameters = 2
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
//        return """
//        match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
//           match (other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)-[:METHOD_OWNS_ARGUMENT]->(other_argument:Argument)
//           where
//                not (class)-[:IMPLEMENTS|:EXTENDS]->()<-[:IMPLEMENTS|:EXTENDS]-(other_class) and
//                not (class)-[:IMPLEMENTS|:EXTENDS]-(other_class) and
//        class.app_key = other_class.app_key and class <> other_class and method.number_of_parameters = other_method.number_of_parameters and method.number_of_parameters >= \(self.minimumNumberOfParameters) and argument.type = other_argument.type and
//               method.return_type = other_method.return_type
//           with class, other_class, method, other_method, argument order by argument.type
//           with collect(distinct argument) as arguments, count(distinct argument) as number_of_arguments, method, other_method, class, other_class
//           where number_of_arguments = method.number_of_parameters
//           with [argument in arguments | argument.type] as arguments, number_of_arguments, method, other_method, class, other_class order by method.name
//           with collect(class.name +"."+method.name) as method_names, count(distinct method) as method_count, class, other_class, collect(number_of_arguments) as number_of_arguments, collect(arguments) as types
//        where method_count >= \(self.minimumCommonMethodCount)
//           with collect(method_names) as method_names, collect(class.name) as class_names, types, class.app_key as app_key
//           return app_key, class_names, method_names, types
//        """
        return """
            match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
               match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)-[:METHOD_OWNS_ARGUMENT]->(other_argument:Argument)
               where
                    not (class)-[:IMPLEMENTS|:EXTENDS]->()<-[:IMPLEMENTS|:EXTENDS]-(other_class) and
                    not (class)-[:IMPLEMENTS|:EXTENDS]-(other_class) and
            class.app_key = other_class.app_key and class <> other_class and method.number_of_parameters = other_method.number_of_parameters and method.number_of_parameters >= \(minimumNumberOfParameters) and argument.type = other_argument.type and
                   method.return_type = other_method.return_type
               with class, other_class, method, other_method, argument order by argument.type
               with collect(distinct argument) as arguments, count(distinct argument) as number_of_arguments, method, other_method, class, other_class
               where number_of_arguments = method.number_of_parameters
               with [argument in arguments | argument.type] as arguments, number_of_arguments, method, other_method, class, other_class order by method.name
               with collect(distinct class.name +"."+method.name) as method_names, count(distinct method) as method_count, class, other_class, collect(number_of_arguments) as number_of_arguments, collect(distinct arguments) as types
            where method_count >= \(minimumCommonMethodCount)
               with collect(distinct method_names) as method_names, collect(distinct class.name) as class_names, types, class.app_key as app_key, count(distinct class.name) as class_count
               where class_count >= 2
               return app_key, class_names, method_names, types
        """
    }
    
    var appString: String {
        return """
        match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
           match (app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)-[:METHOD_OWNS_ARGUMENT]->(other_argument:Argument)
           where
                not (class)-[:IMPLEMENTS|:EXTENDS]->()<-[:IMPLEMENTS|:EXTENDS]-(other_class) and
                not (class)-[:IMPLEMENTS|:EXTENDS]-(other_class) and
        class.app_key = other_class.app_key and class <> other_class and method.number_of_parameters = other_method.number_of_parameters and method.number_of_parameters >= \(minimumNumberOfParameters) and argument.type = other_argument.type and
               method.return_type = other_method.return_type
           with class, other_class, method, other_method, argument order by argument.type
           with collect(distinct argument) as arguments, count(distinct argument) as number_of_arguments, method, other_method, class, other_class
           where number_of_arguments = method.number_of_parameters
           with [argument in arguments | argument.type] as arguments, number_of_arguments, method, other_method, class, other_class order by method.name
           with collect(distinct class.name +"."+method.name) as method_names, count(distinct method) as method_count, class, other_class, collect(number_of_arguments) as number_of_arguments, collect(distinct arguments) as types
        where method_count >= \(minimumCommonMethodCount)
           with collect(distinct method_names) as method_names, collect(distinct class.name) as class_names, types, class.app_key as app_key, count(distinct class.name) as class_count
           where class_count >= 2
           return distinct app_key, count(distinct class_names) as number_of_smells
        """
    }
    
    var notes: String {
        return "Query classes/protocols that do not implement or extend each other or a common parent class/protocol, but have methods with the same argument types."
    }
}
