//
//  AnalysisController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class AnalysisController {
    let dispatchGroup = DispatchGroup()
    var totalQueries = 0
    var currentQuery = 0
    let dbController = DatabaseController()
    
    func analyse(queryString: String, completition: @escaping (String, [[String]]?, [String]?, Int, Int) -> Void) {
        var queries: [Query]
        
        switch queryString {
        case "all":
            queries = [InfoQuery(), LongMethodQuery(), BlobClassQuery(), ShotgunSurgeryQuery(), SwitchStatementsQuery(), LazyClass(), MessageChainsQuery(), DataClassQuery(), CommentsQuery(), CyclicClassDependenciesQuery(), IntensiveCouplingQuery(), DistortedHierarchyQuery(), TraditionBreakerQuery(), SiblingDuplicationQuery(), InternalDuplicationQuery(), ExternalDuplicationQuery(), DivergentChangeQuery(), LongParameterListQuery(), FeatureEnvyQuery(), DataClumpArgumentsQuery(), DataClumpFieldsQuery(), SpeculativeGeneralityProtocolQuery(), MiddleManQuery(), ParallelInheritanceHierarchiesQuery(), SpeculativeGeneralityMethodQuery(), InappropriateIntimacyQuery(), BrainMethodQuery(), SAPBreakerQuery(), SAPBreakerModuleQuery(), UnstableDependenciesQuery(), PrimitiveObsessionQuery(), AlternativeClassesWithDifferentInterfacesQuery(), MissingTemplateMethodQuery(), SwissArmyKnifeQuery(), ComplexClassPaprikaQuery(), IgnoringLowMemoryWarningQuery(), MassiveViewControllerQuery(), AlternativeClassesWithDifferentInterfacesQuery(), GodClassQuery()]
        case "Info":
            queries = [InfoQuery()]
        case "LM":
            queries = [LongMethodQuery()]
        case "BLOB":
            queries = [BlobClassQuery()]
        case "ShotgunSurgery":
            queries = [ShotgunSurgeryQuery()]
        case "SwitchStatements":
            queries = [SwitchStatementsQuery()]
        case "LazyClass":
            queries = [LazyClass()]
        case "MessageChain":
            queries = [MessageChainsQuery()]
        case "DataClass":
            queries = [DataClassQuery()]
        case "Comments":
            queries = [CommentsQuery()]
        case "CyclicClassDependency":
            queries = [CyclicClassDependenciesQuery()]
        case "IntensiveCoupling":
            queries = [IntensiveCouplingQuery()]
        case "DistortedHierarchy":
            queries = [DistortedHierarchyQuery()]
        case "TraditionBreaker":
            queries = [TraditionBreakerQuery()]
        case "SiblingDuplication":
            queries = [SiblingDuplicationQuery()]
        case "InternalDuplication":
            queries = [InternalDuplicationQuery()]
        case "ExternalDuplication":
            queries = [ExternalDuplicationQuery()]
        case "DivergentChange":
            queries = [DivergentChangeQuery()]
        case "LongParameterList":
            queries = [LongParameterListQuery()]
        case "FeatureEnvy":
            queries = [FeatureEnvyQuery()]
        case "DataClumpArguments":
            queries = [DataClumpArgumentsQuery()]
        case "DataClumpFields":
            queries = [DataClumpFieldsQuery()]
        case "SpeculativeGeneralityProtocol":
            queries = [SpeculativeGeneralityProtocolQuery()]
        case "MiddleMan":
            queries = [MiddleManQuery()]
        case "ParallelInheritanceHierarchies":
            queries = [ParallelInheritanceHierarchiesQuery()]
        case "SpeculativeGeneralityMethod":
            queries = [SpeculativeGeneralityMethodQuery()]
        case "InappropriateIntimacy":
            queries = [InappropriateIntimacyQuery()]
        case "BrainMethod":
            queries = [BrainMethodQuery()]
        case "GodClass":
            queries = [GodClassQuery()]
        case "SAPBreaker":
            queries = [SAPBreakerQuery()]
        case "SAPBreakerModule":
            queries = [SAPBreakerModuleQuery()]
        case "UnstableDependencies":
            queries = [UnstableDependenciesQuery()]
        case "PrimitiveObsession":
            queries = [PrimitiveObsessionQuery()]
        case "AlternativeClassesWithDifferentInterfaces":
            queries = [AlternativeClassesWithDifferentInterfacesQuery()]
        case "MissingTemplateMethod":
            queries = [MissingTemplateMethodQuery()]
        case "SwissArmyKnife":
            queries = [SwissArmyKnifeQuery()]
        case "ComplexClassPaprika":
            queries = [ComplexClassPaprikaQuery()]
        case "IgnoringLowMemoryWarning":
            queries = [IgnoringLowMemoryWarningQuery()]
        case "MassiveViewController":
            queries = [MassiveViewControllerQuery()]
        default:
            queries = [CustomQuery(queryString: queryString)]
        }
        self.totalQueries = queries.count
        
        
//        for query in queries {
//            dispatchGroup.enter()
//            runquery(query: query, completition: completition)
//        }
        
        nextQuery(queries: queries, completition: completition)
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
    
    func nextQuery(queries: [Query], completition:@escaping (String, [[String]]?, [String]?, Int, Int) -> Void) {
        var queries = queries
        
        if let query = queries.popLast() {
             dispatchGroup.enter()
            
            runquery(query: query) { [unowned self] queryName, results, headers, totalQueries, currentQuery in
                completition(queryName, results, headers, totalQueries, currentQuery)
                
                self.nextQuery(queries: queries, completition: completition)
                
                self.dispatchGroup.leave()
            }
        }
    }
    
    func runquery(query: Query, completition: @escaping (String, [[String]]?, [String]?, Int, Int) -> Void) {
        var query = query
        print("Running query: \(query.appString)")
        dbController.runQueryReturnDataString(transaction: query.appString) { [unowned self] json in
            self.currentQuery += 1
                    
            print(" --- Query: \(query.name) ---")
            query.json = json
                            
            //print("res nonparsed: \(json)")
            //print("res: \(query.parsedResult)")
            // print("res dictionary: \(query.parsedDictionary)")
//                if let parsedResults = query.parsedResult
//                    completition(query.name, parsedResults)
//                    self.dispatchGroup.leave()
            if let parsedDictionary = query.parsedDictionary {
                completition(query.name, parsedDictionary, query.headers, self.totalQueries, self.currentQuery)
                //self.dispatchGroup.leave()
            } else {
                completition(query.name, nil, query.headers, self.totalQueries, self.currentQuery)
                //self.dispatchGroup.leave()
            }
        }
    }
}
