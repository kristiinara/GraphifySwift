//
//  DatabaseController.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 28/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

import Foundation

class DatabaseController {
    private let dataURL: URL
    private let authorizationToken: String
    
    var errorDescription: [String] = []
    
    init(dbURL: URL, authorizationToken: String) {
        self.dataURL = dbURL
        self.authorizationToken = authorizationToken
    }
    
    init() {
        self.dataURL = URL(string: "http://localhost:7474/db/data/transaction/commit")!
        self.authorizationToken = "bmVvNGo6MTIzNA=="
    }
    
    //TODO: check if we need this method at all, currently added so we can easily change behaviour for all queries made
    func runQueryReturnId(transaction: String?, completition: @escaping (Int?) -> Void) {
        print("runQueryReturnId")
        if let transaction = transaction {
            requestWithDefaultCompletition(transaction: transaction, completition: completition)
        } else {
            self.errorDescription.append("No transaction")
            print("No transaction")
            completition(nil)
        }
    }
    
    func runQueryReturnDataString(transaction: String, completition: @escaping ([String: Any]?) -> Void) {
        let parameters = [
            "statements": [[
                "statement" : transaction
                ]]
        ]
        requestWithParameters(parameters) { [unowned self] json in
//            guard let self = self else {
//                completition(nil)
//                return
//            }
            
            let success = self.defaultErrorHandling(json: json)
            
            print("----- JSON result (success? \(success)): -----")
            //print(json ?? "Empty response")
            
            if success {
                completition(json)
            } else {
                completition(nil)
            }
        }
    }
    
    func runQueryReturnRows(transaction: String, completition: @escaping ([[String]]?) -> Void) {
        let parameters = [
            "statements": [[
                "statement" : transaction
                ]]
        ]
        requestWithParameters(parameters) { [unowned self] json in
//            guard let self = self else {
//                completition(nil)
//                return
//            }
            
            let success = self.defaultErrorHandling(json: json)
            
            print("----- JSON result (success? \(success)): -----")
            //print(json ?? "Empty response")
            
            if success {
                completition(self.getRows(json))
            } else {
                completition(nil)
            }
        }
    }
    
    private func requestWithDefaultCompletition(transaction: String, completition: @escaping (Int?) -> Void) {
        print("requestWithDefaultCompletition")
        let parameters = [
            "statements": [[
                "statement" : transaction
                ]]
        ]
        requestWithParameters(parameters) { [unowned self] json in
//            guard let self = self else {
//                completition(nil)
//                return
//            }
            
            print("request finished")
            let success = self.defaultErrorHandling(json: json)
            
//            print("----- JSON result (success? \(success)): -----")
//            print(json ?? "Empty response")
            
            if success {
                completition(self.getId(json))
            } else {
                completition(nil)
            }
        }
    }
    
    private func getRows(_ json: [String: Any]?) -> [[String]]? {
        var rows : [[String]] = []
        guard let json = json else { return nil }
        
        guard let results = json["results"] as? [[String:Any]] else {
            print("no results: \(json)")
            return nil
        }
        
        guard results.count > 0 else {
            print("Results length 0: \(json)")
            return nil
        }
        guard results[0]["errors"] == nil else {
            print("Resulted in errors: \(results[0]["errors"] as! [[String: Any]])")
            return nil
        }
        
        guard let data = results[0]["data"] as? [[String: Any]] else {
            print("no data: \(results[0])")
            return nil
        }
        
        guard data.count > 0 else {
            print("Data length 0")
            return []
        }
        
        for dataItem in data {
            if let row = dataItem["row"] as? [Any] {
                var subList: [String] = []
                for subItem in row {
                    subList.append("\(subItem)")
                }
                rows.append(subList)
            }
        }
        
        return rows
    }
    
    private func getId(_ json: [String: Any]?) -> Int? {
        guard let json = json else { return nil }
        
        guard let results = json["results"] as? [[String:Any]] else {
            self.errorDescription.append("No results")
            print("no results: \(json)")
            return nil
        }
        
        guard results.count > 0 else {
            self.errorDescription.append("Json length 0")
            print("Results length 0: \(json)")
            return nil
        }
        guard results[0]["errors"] == nil else {
            print("Resulted in errors: \(results[0]["errors"] as! [[String: Any]])")
            return nil
        }
        
        guard let data = results[0]["data"] as? [[String: Any]] else {
            self.errorDescription.append("No data")
            print("no data: \(results[0])")
            return nil
        }
        
        guard data.count > 0 else {
            self.errorDescription.append("Data length 0")
            print("Data length 0")
            return nil
        }
        
        guard let row = data[0]["row"] as? [Any] else {
            self.errorDescription.append("No row")
            print("no row: \(data)")
            return nil
        }
        
        guard row.count > 0 else {
            self.errorDescription.append("Row length 0")
            print("Row length 0")
            return nil
        }
        
        guard let id = row[0] as? Int else {
            self.errorDescription.append("No id")
            print("No id: \(row)")
            return nil
        }
        
        return id
    }
    
    private func requestWithParameters(_ parameters: [String: Any], completition: @escaping ([String: Any]?) -> Void) {
        print("requestWithParameters")
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: dataURL)
        request.httpMethod = "POST" //set http method as POST
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            self.errorDescription.append(error.localizedDescription)
            completition(["JsonError": error])
            print(error.localizedDescription)
            return
        }
        
        //try! print("REQUEST: \(JSONSerialization.jsonObject(with: request.httpBody!, options: .mutableContainers))")
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        request.addValue("Basic \(self.authorizationToken)", forHTTPHeaderField: "Authorization")
        
        //print("Starting request!")
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { [unowned self] data, response, error in
            
//            guard let self = self else {
//                completition(nil)
//                return
//            }
            
            //print("response: \(String(describing: response))")
            
            
            guard error == nil else {
                self.errorDescription.append("Networkerror: \(error?.localizedDescription ?? "")")
                completition(["NetworkError" : error!])
                return
            }
            
            guard let data = data else {
                self.errorDescription.append("Return data nil")
                completition(nil)
                return
            }
            
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    //print(json)
                    completition(json)
                }
            } catch let error {
                print(error.localizedDescription)
                completition(["JsonError": error])
            }
        })
        task.resume()
    }
    
    private func defaultErrorHandling(json: [String: Any]?) -> Bool {
        guard let json = json else {
            print("No results!")
            return false
        }
        
        if let jsonError = json["JsonError"] {
            print(jsonError)
            return false
        }
        
        if let networkError = json["NetworkError"] {
            print(networkError)
            return false
        }
        
        return true
    }
}
