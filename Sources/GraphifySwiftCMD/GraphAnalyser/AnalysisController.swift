//
//  AnalysisController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class AnalysisController {
    let dispatchGroup = DispatchGroup()
    
    func analyse(queryString: String, completition: @escaping ([[String]]?) -> Void) {
        var queries: [Query?]
        
        switch queryString {
        case "all":
            queries = [LongMethodQuery(), BlobClassQuery()]
        case "LM":
            queries = [LongMethodQuery()]
        case "BLOB":
            queries = [BlobClassQuery()]
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
    
    func runquery(query: Query?, completition: @escaping ([[String]]?) -> Void) {
        if var query = query {
            let dbController = DatabaseController()
            print("Running query: \(query.string)")
            dbController.runQueryReturnDataString(transaction: query.string) { json in
                print(" --- Query: \(query.name) ---")
                query.json = json
                if let parsedResults = query.parsedResult {
                    completition(parsedResults)
                    self.dispatchGroup.leave()
                } else {
                    completition(nil)
                    self.dispatchGroup.leave()
                }
            }
        } else {
            completition(nil)
            self.dispatchGroup.leave()
        }
    }
}
