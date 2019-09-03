//
//  Query.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/05/2019.
//

import Foundation

protocol Query {
    var name: String {get}
    var string: String {get}
    var result: String? {get set}
    var json: [String: Any]? {get set}
}

extension Query {
    var finished: Bool {
        return self.result != nil
    }
    
    var resultDictionary: [String: Any]? {
        if let result = result {
            if let data = result.data(using: .utf8) {
                do {
                    let dictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                    return dictionary
                } catch let error {
                    print("JsonError \(error.localizedDescription)")
                    return nil
                }
            }
        }
        return nil
    }
    
    var parsedResult: [[String]]? {
        var parsedResults: [[String]] = []
        
        var result: [String: Any]? = nil
        if let resultDictionary = self.resultDictionary {
            result = resultDictionary
        } else if let json = self.json {
            result = json
        }
        
        if let result = result {
            if let results = result["results"] as? [[String: Any]] {
                for item in results {
                    if let data = item["data"] as? [[String: Any]] {
                        for row in data {
                            if let rowString = row["row"] as? [Any] {
                                parsedResults.append(rowString.map() { object in
                                    return "\(object)"
                                })
                            }
                        }
                    } else {
                        print("no data")
                    }
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
        
        return parsedResults
    }
}
