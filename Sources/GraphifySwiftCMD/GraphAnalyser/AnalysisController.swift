//
//  AnalysisController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

class AnalysisController {
    func analyse(queryString: String, completition: @escaping ([[String]]?) -> Void) {
        var query: Query?
        
        switch queryString {
        case "LM":
            query = LM()
        default:
            query = Custom(queryString: queryString)
        }
        
        if let query = query {
            let dbController = DatabaseController()
            print("Running query: \(query.string)")
            dbController.runQueryReturnRows(transaction: query.string) { rows in
                if let rows = rows {
                    completition(rows)
                }
            }
        } else {
            completition(nil)
        }
    }
}
