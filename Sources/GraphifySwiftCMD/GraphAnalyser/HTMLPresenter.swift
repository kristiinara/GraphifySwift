//
//  HTMLPresenter.swift
//  Basic
//
//  Created by Kristiina Rahkema on 18/10/2019.
//

import Foundation

class HTMLPresenter {
    
    static func generateHTML(dictionary: [String:[String:[[String]]]], headerDictionary: [String: [String]]) -> String {
        var body = ""
        
        for appName in dictionary.keys {
            body += "<details open><summary>"
            if let appStuff = dictionary[appName] {
                body += "\(appName) (\(appStuff.keys.count))</summary>"
                for queryName in appStuff.keys {
                    body += "<details open><summary>"
                    if let queryStuff = appStuff[queryName] {
                        body += "\(queryName) (\(queryStuff.count))</summary>"
                        body += "<table>"
                        
                        if let headers = headerDictionary[queryName] {
                            body += "<tr>"
                            for header in headers {
                                body += "<th>\(header)</th>"
                            }
                            body += "</tr>"
                        }
                        
                        for row in queryStuff {
                            body += "<tr>"
                            
                            for column in row {
                                body += "<td>\(column)</td>"
                            }
                            
                            body += "</tr>"
                        }
                        
                        body += "</table>"
                        body += "</details>"
                    } else {
                        body += "\(queryName)</summary>"
                    }
                }
            } else {
                body += "\(appName)</summary>"
            }
            body += "</details>"
        }
        
        let htmlString = """
            <head>
                <style type="text/css">
                    details {
                border: 1px solid #aaa;
                border-radius: 4px;
                padding: .5em .5em 0;
            }

            summary {
                font-weight: bold;
                margin: -.5em -.5em 0;
                padding: .5em;
            }

            details[open] {
                padding: .5em;
            }

            details[open] summary {
                border-bottom: 1px solid #aaa;
                margin-bottom: .5em;
            }

            table, th, td {
              border: 1px solid black;
              border-collapse: collapse;
              padding: 5px;
            }
                </style>

            </head>

            <body>
               \(body)
            </body>
        """
        
        return htmlString
    }
    
    static func generateCSV(dictionary: [String: [[String]]], headerDictionary: [String: [String]], fileNamePrefix: String) -> [String: String] {
        
        var resultDictionary: [String: String] = [:]
        
        for queryName in dictionary.keys {
            var queryCSV = ""
            
            if let headers = headerDictionary[queryName] {
                queryCSV += headers.joined(separator: ",")
                queryCSV += "\n"
            }
            
            if let rows = dictionary[queryName] {
                for var row in rows {
                    row = row.map() { item in
                        if item.contains("\n") {
                            return "\"\(item.replacingOccurrences(of: "\n", with: "\r"))\""
                        }
                        return item
                    }
                    
                    queryCSV += row.joined(separator: ",")
                    queryCSV += "\n"
                }
            }
            
            resultDictionary["\(fileNamePrefix)\(queryName).csv"] = queryCSV
        }
        
        return resultDictionary
    }
}
