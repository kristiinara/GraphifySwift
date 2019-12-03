//
//  BrainMethodQuery.swift
//  Basic
//
//  Created by Kristiina Rahkema on 01/11/2019.
//

import Foundation

class BrainMethodQuery: Query {
    let name = "BrainMethod"
    let highNumberOfInstructionsForClass = Metrics.veryHighNumberOfInstructionsClass
    let highCyclomaticComplexity = Metrics.highCyclomaticComplexity
    let severalMaximalNestingDepth = 3
    let manyAccessedVariables = Metrics.shorTermMemoryCap
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return """
        match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
        where class.number_of_instructions > \(self.highNumberOfInstructionsForClass) and method.cyclomatic_complexity >= \(self.highCyclomaticComplexity) and method.max_nesting_depth >= \(self.severalMaximalNestingDepth)
        match (method)-[:USES]->(variable:Variable)
        with class, method, count(distinct variable) as number_of_variables, collect(distinct variable.name) as variable_names
        where number_of_variables > \(self.manyAccessedVariables)
        return class.app_key as app_key, class.name as class_name, method.name as method_name, method.cyclomatic_complexity as cyclomatic_complexity, method.max_nesting_depth as max_nesting_depth, number_of_variables, variable_names, class.data_string as main_text, method.data_string as affected_text
        """
    }
    
    var appString: String {
        return """
            match (class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
            where class.number_of_instructions > \(self.highNumberOfInstructionsForClass) and method.cyclomatic_complexity >= \(self.highCyclomaticComplexity) and method.max_nesting_depth >= \(self.severalMaximalNestingDepth)
            match (method)-[:USES]->(variable:Variable)
            with class, method, count(distinct variable) as number_of_variables, collect(distinct variable.name) as variable_names
            where number_of_variables > \(self.manyAccessedVariables)
            return distinct(class.app_key) as app_key, count(distinct method) as number_of_smells
        """
    }
    
    
    var notes: String {
        return "Queries methods with high cyclomatic complexity, many accessed variables and max nesting depth of at least several that belong to classes with high number of instructions. High number of instructions and high cyclomatic complexity are determined statistically. Several maximal nesting depth should be higher than 2 and 5 and many accessed variables is according to short term memory capacity 7 to 8."
    }
}
