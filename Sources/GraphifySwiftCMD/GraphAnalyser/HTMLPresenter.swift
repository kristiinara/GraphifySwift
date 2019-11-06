//
//  HTMLPresenter.swift
//  Basic
//
//  Created by Kristiina Rahkema on 18/10/2019.
//

import Foundation

class HTMLPresenter {
    
    static func generateHTML(fileName: String, dictionary: [String:[String:[[String]]]], headerDictionary: [String: [String]]) -> [String: String] {
        var files: [String: String] = [:]
        
        var body = ""
        
        for appName in dictionary.keys {
            print("appName: \(appName)")
            body += "<details open><summary>"
            if let appStuff = dictionary[appName] {
                body += "\(appName) (\(appStuff.keys.count))</summary>"
                for queryName in appStuff.keys {
                    print("query: \(queryName)")
                    body += "<details open><summary>"
                    if let queryStuff = appStuff[queryName] {
                        body += "\(queryName) (\(queryStuff.count))</summary>"
                        body += "<table>"
                        
                        var mainIndex: Int? = nil
                        var affectedIndex: Int? = nil
                        
                        if let headers = headerDictionary[queryName] {
                            var count = 0
                            body += "<tr>"
                            for header in headers {
                                if header == "main_text" {
                                    mainIndex = count
                                } else if header == "affected_text" {
                                    affectedIndex = count
                                } else {
                                    body += "<th>\(header)</th>"
                                }
                                count += 1
                            }
                            if mainIndex != nil { // && affectedIndex != nil {
                                body += "<th>Code</th>"
                            }
                            
                            body += "</tr>"
                        }
                        
                        var rowCount = 0
                        for row in queryStuff {
                            print("count: \(rowCount)")
                            var mainString: String? = nil
                            var affectedString: String? = nil
                            
                            var count = 0
                            body += "<tr>"
                            for column in row {
                                if count == mainIndex {
                                    mainString = column
                                } else if count == affectedIndex {
                                    affectedString = column
                                } else {
                                    body += "<td>\(column)</td>"
                                }
                                count += 1
                            }
                            
                            if let mainString = mainString {
                                let subHtml = generateHTML(mainText: mainString, affectedText: affectedString)
                                let subFileName = "\(fileName)-\(appName)-\(queryName)-\(rowCount).html"
                                
                                
                                body += "<td><a href=\"\(subFileName)\">Code</a></td>"
                                files[subFileName] = subHtml
                            }
                            
                            body += "</tr>"
                            rowCount += 1
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
        files["\(fileName).html"] = htmlString
        
        return files
    }
    
    static func generateHTML(mainText: String, affectedText: String?) -> String {
        var body = ""
        
        if let affectedText = affectedText {
            let split = mainText.split(around: affectedText)
            body += "<pre><code><font color=\"black\">\(split.0)"
            if let second = split.1 {
                body += "<font color=\"red\">\(affectedText)</font>"
                body += "\(second)"
            }
            body += "</font></code></pre>"
            
        } else {
            body += "<pre><code>\(mainText)</code></pre>"
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
        
       // print("htmlString: \(htmlString)")
        
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
                        var item = item
                        var changed = false
                        
                        if item.contains("\n") {
                            item = item.replacingOccurrences(of: "\n", with: "\r")
                            changed = true
                        }
                        
                        if item.contains(",") {
                            changed = true
                        }
                        
                        if item.contains("\"") {
                            item = item.replacingOccurrences(of: "\"", with: "\'")
                        }
                        
                        if changed {
                            return "\"\(item)\""
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
