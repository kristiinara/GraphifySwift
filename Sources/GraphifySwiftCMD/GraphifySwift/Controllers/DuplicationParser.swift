//
//  DuplicationParser.swift
//  Basic
//
//  Created by Kristiina Rahkema on 16/10/2019.
//

import Foundation

class DuplicationParser {
    var json: [String: Any]?
    
    init(jsonData: Data) {
        self.json = self.jsonFromData(data: jsonData)
    }
    
    init(path: String) {
        self.json = self.jsonFromPath(path: path)
    }
    
    init(homePath: String, ignore: [String]) {
        var path = homePath
        if !path.hasSuffix("/") {
            path = "\(path)/"
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = [
            "jscpd",
            homePath,
            "--min-tokens", "10",
            "--format", "swift",
            "--reporters", "json",
            "--absolute",
            "--output", "\(homePath)jscpd-report/",
            "--ignore ", ignore.joined(separator: ",")
        ]
        task.launch()
        task.waitUntilExit()
        
        self.json = self.jsonFromPath(path:"\(homePath)jscpd-report/jscpd-report.json")
    }
    
    func jsonFromData(data: Data) -> [String: Any]? {
        do {
            //create json object from data
            if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                return json
            } else {
                return nil
            }
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func jsonFromPath(path: String) -> [String: Any]? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return self.jsonFromData(data: data)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
    func addDuplicatesToApp(app: App) {
        var parsedDuplicates: [Duplication] = []
        
        guard let json = self.json else {
            print("No json data available!")
            return
        }
        
        guard let duplicates = json["duplicates"] as? [[String: Any]] else {
            print("No duplicates in data!")
            return
        }
        
        let allClasses = app.allClasses
        var classDictionary: [String: Class] = [:]
        
        for classInstance in allClasses {
            classDictionary[classInstance.path] = classInstance
        }
        
        for duplicate in duplicates {
            print("Parsind duplicate: \(duplicate)")
            if let firstFile = duplicate["firstFile"] as? [String: Any], let secondFile = duplicate["secondFile"] as? [String: Any] {
                
                if let firstFilePath = firstFile["name"] as? String,
                    let secondFilePath = secondFile["name"] as? String,
                    let firstfileStart = firstFile["start"] as? Int,
                    let secondfileStart = secondFile["start"] as? Int,
                    let firstfileEnd = firstFile["end"] as? Int,
                    let secondfileEnd = secondFile["end"] as? Int,
                    let fragment = duplicate["fragment"] as? String {
                    
                    let newDuplicate = Duplication(
                        firstClassPath: firstFilePath, secondClassPath: secondFilePath, firstFileStart: firstfileStart, secondFileStart: secondfileStart, firstFileEnd: firstfileEnd, secondFileEnd: secondfileEnd, fragment: fragment)
                    parsedDuplicates.append(newDuplicate)
                    
                    if let firstClass = classDictionary[firstFilePath] {
                        newDuplicate.firstClass = firstClass
                    } else {
                        print("Could not locate firstClass: \(firstFilePath)")
                    }
                    
                    if let secondClass = classDictionary[secondFilePath] {
                        newDuplicate.secondClass = secondClass
                    } else {
                        print("Could not locate secondClass: \(secondFilePath)")
                    }
                } else {
                    print("Could not add duplication, some values were nil")
                }
            } else {
                print("Could not find fristFile and/or secondFile")
            }
        }
        
        app.duplicates = parsedDuplicates
    }
}
