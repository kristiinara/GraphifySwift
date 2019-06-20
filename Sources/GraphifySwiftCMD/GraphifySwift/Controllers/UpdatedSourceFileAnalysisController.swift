//
//  UpdatedSourceFileAnalysisController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 13/06/2019.
//

import Foundation
import SourceKittenFramework

class UpdatedSourceFileAnalysisController {
    var fileQueue: [URL] = []
    
    func analyseFolder(at url: URL, appKey: String, printOutput: Bool, finished: @escaping () -> Void) {
        
        fileQueue = FolderUtility.getFileQueue(for: url)
        
        if self.fileQueue.count > 0 {
            self.analyseFiles() {
                finished()
//                self.analyseSpecialSuperClasses()
//                self.analyseClassHierarchy()
//                self.printApp()
//                self.dataSyncController.finished = finished
//                self.dataSyncController.sync(app: self.app)
            }
        }
    }
    
    func analyseFiles(completition: @escaping () -> Void) {
        if fileQueue.count > 0 {
            let file = self.fileQueue.remove(at: 0)
            analyseFile(at: file) {
                self.analyseFiles(completition: completition)
                
            }
        } else {
            completition()
        }
    }
    
    func analyseStructure(_ structure: [[String: SourceKitRepresentable]], mainStructure: [String:SourceKitRepresentable], lines: [String])  -> [[String:Any]]{
        var results : [[String: Any]] = []
        
        for substructure in structure {
            results.append(analyseStructureSingle(substructure, mainStructure: mainStructure, lines: lines))
        }
        return results
    }
    
    func analyseStructureSingle(_ structure: [String: SourceKitRepresentable], mainStructure: [String:SourceKitRepresentable], lines: [String]) -> [String: Any] {
        let entities = structure["key.entities"] as? [SourceKitRepresentable]
        let name = structure["key.name"] as? String
        let usr = structure["key.usr"] as? String
        let kind = structure["key.kind"] as? String
        
        var result : [String: Any] = [:]
        //result["entities"] = entities
        result["name"] = name
        result["usr"] = usr
        result["kind"] = kind
        
        //print("\(String(describing: name)) - \(String(describing: usr)) - \(kind)")
        
        if let usr = usr {
            let uses = usesOfUSR(usr: usr, dictionary: mainStructure)
            var usedLines : [String] = []
            for use in uses {
                //print(lines[use.line])
                usedLines.append(lines[use.line])
            }
            result["uses"] = uses
            result["lines"] = usedLines
        }
        
        var resultEntities : [[String: Any]] = []
        
        if let entities = entities {
            for entity in entities {
                if let entity = entity as? [[String: SourceKitRepresentable]] {
                    resultEntities.append(contentsOf: analyseStructure(entity, mainStructure: mainStructure, lines: lines))
                } else if let entity = entity as? [String: SourceKitRepresentable] {
                    resultEntities.append(analyseStructureSingle(entity, mainStructure: mainStructure, lines: lines))
                }
            }
        }
        result["entities"] = resultEntities
        return result
    }
 
    func analyseFile(at url: URL, completitionHandler: @escaping () -> Void) {
        if let file = File(path: url.path) {
            do {
                print("file: \(url.lastPathComponent)")
                let request = Request.index(file: url.path, arguments: [url.path])
                let result = try request.send()
                let index = (result["key.entities"] as! [SourceKitRepresentable]).map({ $0 as! [String: SourceKitRepresentable] })
                
                let resIndex = result as! [String: SourceKitRepresentable]
                
                let fileContents = file.contents
                let lines = (fileContents as NSString).lines().map({ $0.content })
                let analysisResult = analyseStructure(index, mainStructure: resIndex, lines: lines)
                
                prettyPrint(array: analysisResult)
                
                //if self.printOutput {
                    let resultString = "\(index)"
                    ResultToFileHandler.write(resultString: resultString, toFile: url.path)
                //}
                
                completitionHandler()
            } catch {
                print("Failed")
                completitionHandler()
            }
        } else {
            print("No such file: \(url)")
            completitionHandler()
        }
    }
    
    func usesOfUSR(usr: String, dictionary: [String: SourceKitRepresentable]) -> [(line: Int, column: Int)] {
        if dictionary["key.usr"] as? String == usr,
            let line = dictionary["key.line"] as? Int64,
            let column = dictionary["key.column"] as? Int64 {
            return [(Int(line - 1), Int(column))]
        }
        return (dictionary["key.entities"] as? [SourceKitRepresentable])?
            .map({ $0 as! [String: SourceKitRepresentable] })
            .flatMap { usesOfUSR(usr: usr, dictionary: $0) } ?? []
    }
    
    func prettyPrint(array: [[String: Any]]) {
        for row in array {
            prettyPrintSingle(object: row)
        }
    }
    
    func prettyPrintSingle(object: [String: Any]) {
        for key in object.keys {
            let subObject = object[key]
            if let subObject = subObject as? String {
                print(subObject)
            } else if let subObject = subObject as? [String: SourceKitRepresentable] {
                prettyPrintSingle(object: subObject)
            } else if let subObject = subObject as? [[String: SourceKitRepresentable]] {
                prettyPrint(array: subObject)
            } else {
                print("--- \(subObject)")
            }
        }
    }
}
