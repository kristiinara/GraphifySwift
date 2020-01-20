//
//  ParallelInheritanceHierarchiesQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 25/10/2019.
//

import Foundation

class ParallelInheritanceHierarchiesQuery: Query {
    var name = "ParallelInheritanceHierarchies"
    var prefixLength = 3
    var minimumNumberOfClassesInHierarcy = 5
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (parent:Class)<-[:MODULE_OWNS_CLASS]-(:Module)<-[:APP_OWNS_MODULE]-(app:App)
        match (app)-[:APP_OWNS_MODULE]->(:Module)-[:MODULE_OWNS_CLASS]->(other_parent:Class)
        where parent <> other_parent
        match path = (class:Class)-[:EXTENDS*]->(parent)
        match other_path = (other_class:Class)-[:EXTENDS*]->(other_parent)
        where length(path) = length(other_path) and length(path) > 0 and class.name starts with substring(other_class.name, 0, \(self.prefixLength)) and parent.name starts with substring(other_parent.name, 0, \(self.prefixLength))
        with collect(distinct [n in nodes(path) | n.name ]) as first, collect(distinct [n in nodes(other_path) | n.name]) as second, parent, other_parent
        with REDUCE(output = [], r IN first | output + r) as first_names, REDUCE(output = [], r IN second | output + r) AS second_names, parent, other_parent
        unwind first_names as first_name
        with collect(distinct first_name) as first_names, second_names, parent, other_parent
        unwind second_names as second_name
        with collect(distinct second_name) as second_names, first_names, parent, other_parent
        where size(first_names) >= \(self.minimumNumberOfClassesInHierarcy) and size(second_names) >= \(self.minimumNumberOfClassesInHierarcy)
        return parent.app_key as app_key, parent.name as parent_class_name, other_parent.name as other_parent_class_name , first_names as first_class_names, second_names as second_class_names, size(first_names) as number_of_classes
        """
    }
    
    var appString: String {
        return """
        match (parent:Class)<-[:MODULE_OWNS_CLASS]-(:Module)<-[:APP_OWNS_MODULE]-(app:App)
        match (app)-[:APP_OWNS_MODULE]->(:Module)-[:MODULE_OWNS_CLASS]->(other_parent:Class)
        where parent <> other_parent
        match path = (class:Class)-[:EXTENDS*]->(parent)
        match other_path = (other_class:Class)-[:EXTENDS*]->(other_parent)
        where length(path) = length(other_path) and length(path) > 0 and class.name starts with substring(other_class.name, 0, \(self.prefixLength)) and parent.name starts with substring(other_parent.name, 0, \(self.prefixLength))
        with collect(distinct [n in nodes(path) | n.name ]) as first, collect(distinct [n in nodes(other_path) | n.name]) as second, parent, other_parent
        with REDUCE(output = [], r IN first | output + r) as first_names, REDUCE(output = [], r IN second | output + r) AS second_names, parent, other_parent
        unwind first_names as first_name
        with collect(distinct first_name) as first_names, second_names, parent, other_parent
        unwind second_names as second_name
        with collect(distinct second_name) as second_names, first_names, parent, other_parent
        where size(first_names) >= \(self.minimumNumberOfClassesInHierarcy) and size(second_names) >= \(self.minimumNumberOfClassesInHierarcy)
        return distinct(parent.app_key) as app_key, count(parent)/2 as number_of_smells
        """
    }
    
    var notes: String {
        return "Queries parallel hierarchy trees for classes that start with the same prefixes. Prefix length currently set to 1, minimumNumberOfClassesInHierarchy set to 5."
    }
}
