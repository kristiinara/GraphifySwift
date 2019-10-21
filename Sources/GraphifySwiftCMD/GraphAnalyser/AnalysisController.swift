//
//  AnalysisController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class AnalysisController {
    let dispatchGroup = DispatchGroup()
    
    func analyse(queryString: String, completition: @escaping (String, [[String]]?, [String]?) -> Void) {
        var queries: [Query?]
        
        switch queryString {
        case "all":
            queries = [LongMethodQuery(), BlobClassQuery(), ShotgunSurgeryQuery(), SwitchStatementsQuery(), LazyClass(), MessageChainsQuery(), DataClassQuery(), CommentsQuery(), CyclicClassDependenciesQuery(), IntensiveCouplingQuery(), DistortedHierarchyQuery(), TraditionBreakerQuery(), SiblingDuplicationQuery(), InternalDuplicationQuery(), ExternalDuplicationQuery(), DivergentChangeQuery(), LongParameterListQuery()]
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
        default:
            queries = [CustomQuery(queryString: queryString)]
        }
        
        for query in queries {
            dispatchGroup.enter()
            runquery(query: query, completition: completition)
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
    
    func runquery(query: Query?, completition: @escaping (String, [[String]]?, [String]?) -> Void) {
        if var query = query {
            let dbController = DatabaseController()
            print("Running query: \(query.string)")
            dbController.runQueryReturnDataString(transaction: query.string) { json in
                print(" --- Query: \(query.name) ---")
                query.json = json
                
                print("res nonparsed: \(json)")
                print("res: \(query.parsedResult)")
//                if let parsedResults = query.parsedResult {
//                    completition(query.name, parsedResults)
//                    self.dispatchGroup.leave()
                if let parsedDictionary = query.parsedDictionary {
                    completition(query.name, parsedDictionary, query.headers)
                    self.dispatchGroup.leave()
                } else {
                    completition(query.name, nil, query.headers)
                    self.dispatchGroup.leave()
                }
            }
        } else {
            completition("", nil, nil)
            self.dispatchGroup.leave()
        }
    }
}
