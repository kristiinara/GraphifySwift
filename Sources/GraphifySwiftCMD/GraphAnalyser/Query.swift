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
    var appString: String {get}
    
    var result: String? {get set}
    var json: [String: Any]? {get set}
    var notes: String {get}
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
    
    var headers: [String]? {
        var headers: [String] = []
        
        var result: [String: Any]? = nil
        if let resultDictionary = self.resultDictionary {
            result = resultDictionary
        } else if let json = self.json {
            result = json
        }
        
        if let result = result {
            if let results = result["results"] as? [[String: Any]] {
                for item in results {
                    
                    if let columns = item["columns"] as? [String] {
                        headers = columns
                    }
                }
            }
        }
        
        return headers
    }
    
    //TODO: make parsedDictionary and parsedResult work together
    var parsedDictionary: [[String]]? {
        var parsedDictionary: [[String]] = []
        
        var result: [String: Any]? = nil
        if let resultDictionary = self.resultDictionary {
            result = resultDictionary
        } else if let json = self.json {
            result = json
        }
        
        if let result = result {
            if let results = result["results"] as? [[String: Any]] {
                for item in results {
                    var headers: [String] = []
                    
                    if let columns = item["columns"] as? [String] {
                        headers = columns
                    }
                    
                    if let data = item["data"] as? [[String: Any]] {
                        for row in data {
                            //print("     row: \(row)")
                            if let rowRaw = row["row"] as? [Any] {
                                let rowString = rowRaw.map() { item in return "\(item)" }
                                parsedDictionary.append(rowString)
                                
                                /*
                                 if headers.count == rowStrings.count {
                                     for var i in 0...(headers.count - 1) {
                                         dictionary[headers[i]] = rowStrings[i]
                                     }
                                 }
                                 
                                 */
                                
                                //append(rowString)
                                
//                                parsedResults.append(rowString.map() { object in
//                                    return "\(object)"
//                                })
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
        
        return parsedDictionary
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
