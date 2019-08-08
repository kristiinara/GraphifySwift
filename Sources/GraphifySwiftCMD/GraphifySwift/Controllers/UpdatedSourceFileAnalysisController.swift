//
//  UpdatedSourceFileAnalysisController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 13/06/2019.
//

import Foundation
import SourceKittenFramework
//import SourceKit

class UpdatedSourceFileAnalysisController {
    var fileQueue: [URL] = []
    var allPaths: [String] = []
    var printOutput = true
    var analysedFiles: [String: [String: Any]] = [:]
    
    var rawAnalysedData: [String: [String: SourceKitRepresentable]] = [:]
    var fileContents: [String: [String]] = [:]
    
//    var mainStructure: [String: Any] = [:]
//
//    func analyseFolder(at url: URL, appKey: String, printOutput: Bool, finished: @escaping () -> Void) {
//
//        fileQueue = FolderUtility.getFileQueue(for: url)
////        self.allPaths = fileQueue.reduce([]) { res, file in
////            return res + [file.path]
////        }
//
//        if self.fileQueue.count > 0 {
//            self.analyseFiles() {
//                finished()
////                self.analyseSpecialSuperClasses()
////                self.analyseClassHierarchy()
////                self.printApp()
////                self.dataSyncController.finished = finished
////                self.dataSyncController.sync(app: self.app)
//            }
//        }
//    }
//
//    func analyseFiles(completition: @escaping () -> Void) {
//        if fileQueue.count > 0 {
//            let file = self.fileQueue.remove(at: 0)
//            analyseFile(at: file) {
//                self.analyseFiles(completition: completition)
//
//            }
//        } else {
//            completition()
//        }
//    }
//
//    func analyseStructure(_ structure: [[String: SourceKitRepresentable]], mainStructure: [String:SourceKitRepresentable], lines: [String])  -> [[String:Any]]{
//        var results : [[String: Any]] = []
//
//        for substructure in structure {
//            results.append(analyseStructureSingle(substructure, mainStructure: mainStructure, lines: lines))
//        }
//        return results
//    }
//
//    func analyseStructureSingle(_ structure: [String: SourceKitRepresentable], mainStructure: [String:SourceKitRepresentable], lines: [String]) -> [String: Any] {
//        let entities = structure["key.entities"] as? [SourceKitRepresentable]
//        let name = structure["key.name"] as? String
//        let usr = structure["key.usr"] as? String
//        let kind = structure["key.kind"] as? String
//
//        var result : [String: Any] = [:]
//        //result["entities"] = entities
//        result["name"] = name
//        result["usr"] = usr
//        result["kind"] = kind
//
//        //print("\(String(describing: name)) - \(String(describing: usr)) - \(kind)")
//
//        if let usr = usr {
//            let uses = usesOfUSR(usr: usr, dictionary: mainStructure)
//            var usedLines : [String] = []
//            var lineNumbers : [Int] = []
//
//            for use in uses {
//                //print(lines[use.line])
//                lineNumbers.append(use.line)
//                usedLines.append(lines[use.line - 1])
//            }
//            result["uses"] = uses
//            result["lines"] = usedLines
//            result["line_numbers"] = lineNumbers
//        }
//
//        var resultEntities : [[String: Any]] = []
//
//        if let entities = entities {
//            for entity in entities {
//                if let entity = entity as? [[String: SourceKitRepresentable]] {
//                    resultEntities.append(contentsOf: analyseStructure(entity, mainStructure: mainStructure, lines: lines))
//                } else if let entity = entity as? [String: SourceKitRepresentable] {
//                    resultEntities.append(analyseStructureSingle(entity, mainStructure: mainStructure, lines: lines))
//                }
//            }
//        }
//        result["entities"] = resultEntities
//        return result
//    }
//
////    func structureForFolder(at path: String, completition: @escaping () -> Void) {
////        let path = "/Users/kristiina/PhD/Graph-tool/GraphifySwiftCMD/Sources/GraphifySwiftCMD/GraphifySwift/Controllers/SourceFileAnalysisController.swift"
////        if let file = File(path: path) {
////            let request = Request.docInfo(text: file.contents, arguments: [])
////
////            do {
////                let result = try request.send()
////                print("__res: \(result)")
////                ResultToFileHandler.write(resultString: "\(result)", toFile: path)
////                completition()
////            } catch let error {
////                print("failed! \(error)")
////                completition()
////            }
////        }
////    }
//
//    func structureFromFile(at path: String) -> [String: Any]? {
//        if let file = File(path: path) {
//            do {
//                let url = URL(string: path)
//                print("file: \(String(describing: url?.lastPathComponent))")
//
////                let customRequest = ["key.request": UID("source.request.indexsource"),
////                                     "key.sourcefile": path,
////                                     "key.compilerargs": [self.allPaths]] as SourceKitObject
//
//                //let request = Request.customRequest(request: customRequest)
//
//                //let arguments = [path] + allPaths
//                var arguments = ["-sdk", "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk", "-j4"]
//                print("allPaths: \(allPaths)")
//                arguments.append(contentsOf: allPaths)
//
//                //TODO: check if there is a difference -- but seems to have no difference
//                let request = Request.index(file: path, arguments: arguments)
//                print("request: \(request.description)")
//
//                //let request = Request.index(file: path, arguments: [path, "--", "-workspace", "/Users/kristiina/PhD/Graph-tool/GraphifySwiftCMD/GraphifySwiftCMD.xcodeproj/project.xcworkspace"])
//                let result = try request.send()
//                //let index = (result["key.entities"] as! [SourceKitRepresentable]).map({ $0 as! [String: SourceKitRepresentable] })
//
////                let response = sourcekitd_send_request_sync(customRequest.sourcekitdObject!)
//
//                if self.printOutput {
//                    //let resultString = "\(response)"
//                    let resultString = "\(result)"
//                    ResultToFileHandler.write(resultString: resultString, toFile: path)
//                }
//
//                let resIndex = result
//
//                let fileContents = file.contents
//                let lines = (fileContents as NSString).lines().map({ $0.content })
//                let analysisResult = analyseStructureSingle(resIndex, mainStructure: resIndex, lines: lines)
//
//                //prettyPrintSingle(object: analysisResult)
//
//                return analysisResult
//            } catch {
//                print("Failed index request for file \(path)")
//                return nil
//            }
//        } else {
//            print("No such file: \(path)")
//            return nil
//        }
//    }
//
//    func analyseFile(at url: URL, completitionHandler: @escaping () -> Void) {
//        if let file = File(path: url.path) {
//            do {
//                print("file: \(url.lastPathComponent)")
//                var arguments = ["-sdk", "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk","-j4"]
//                arguments.append(contentsOf: self.allPaths)
//
//                let request = Request.index(file: url.path, arguments: arguments)
//                let result = try request.send()
//                let index = (result["key.entities"] as! [SourceKitRepresentable]).map({ $0 as! [String: SourceKitRepresentable] })
//
//                let resIndex = result
//
//                let fileContents = file.contents
//                let lines = (fileContents as NSString).lines().map({ $0.content })
//                let analysisResult = analyseStructure(index, mainStructure: resIndex, lines: lines)
//
//                //prettyPrint(array: analysisResult)
//
//                if self.printOutput {
//                    let resultString = "\(index) \n res: --- \n \(analysisResult)"
//                    ResultToFileHandler.write(resultString: resultString, toFile: url.path)
//                }
//
//                completitionHandler()
//            } catch {
//                print("Failed")
//                completitionHandler()
//            }
//        } else {
//            print("No such file: \(url)")
//            completitionHandler()
//        }
//    }
//
//
//    func usesOfUSR(usr: String, structure: [String: Any]) -> [Int]? {
//        if let objectStructure = objectWith(objectUsr: usr, structure: structure) {
//            if let uses = objectStructure["line_numbers"] as? [Int] {
//                return uses
//            }
//        }
//
//        return nil
//    }
//
//    func usesOfUSR(usr: String, path: String) -> [Int]? {
//        var structure = self.analysedFiles[path]
//
//        if structure == nil {
//            structure = self.structureFromFile(at: path)
//            self.analysedFiles[path] = structure
//        }
//
//        return usesOfUSR(usr: usr, structure: structure!)
//    }
//
//    func allUsesOfUSR(usr: String) -> [String: [Int]] {
//        var uses: [String: [Int]] = [:]
//        for file in self.allPaths {
//            if let usesForFile = self.usesOfUSR(usr: usr, path: file) {
//                uses[file] = usesForFile
//            }
//        }
//
//        return uses
//    }
//
////    func prettyPrint(array: [[String: Any]]) {
////        for row in array {
////            prettyPrintSingle(object: row)
////        }
////    }
////
////    func prettyPrintSingle(object: [String: Any]) {
////        for key in object.keys {
////            let subObject = object[key]
////            if let subObject = subObject as? String {
////                print(subObject)
////            } else if let subObject = subObject as? [String: SourceKitRepresentable] {
////                prettyPrintSingle(object: subObject)
////            } else if let subObject = subObject as? [[String: SourceKitRepresentable]] {
////                prettyPrint(array: subObject)
////            } else {
////                print("--- \(String(describing: subObject))")
////            }
////        }
////    }
//
//    func usrOf(objectName: String, objectKind: String, structure: [String: Any]) -> String? {
//        if let objectStructure = objectWith(objectName: objectName, objectKind: objectKind, structure: structure) {
//            if let usr = objectStructure["usr"] as? String {
//                return usr
//            }
//        }
//
//        return nil
//    }
//
//    func usrOf(objectName: String, objectKind: String, inFileAt path: String) -> String? {
//        var structure = self.analysedFiles[path]
//
//        if structure == nil {
//            structure = self.structureFromFile(at: path)
//            self.analysedFiles[path] = structure
//        }
//
//        return usrOf(objectName: objectName, objectKind: objectKind, structure: structure!)
//    }
//
//    func objectWith(objectUsr: String, structure: [String: Any]) -> [String: Any]? {
//        let usr = structure["usr"] as? String
//
//        if usr == objectUsr {
//            return structure
//        }
//
//        if let entities = structure["entities"] as? [[String: Any]]  {
//            for entity in entities {
//                if let foundStruct = objectWith(objectUsr: objectUsr, structure: entity) {
//                    return foundStruct
//                }
//            }
//        }
//
//        return nil
//    }
//
//    func objectWith(objectName: String, objectKind: String, structure: [String: Any]) -> [String: Any]? {
//        let name = structure["name"] as? String
//        let kind = structure["kind"] as? String
//
//        if name == objectName && kind == objectKind {
//            return structure
//        }
//
//        if let entities = structure["entities"] as? [[String: Any]]  {
//            for entity in entities {
//                if let foundStruct = objectWith(objectName: objectName, objectKind: objectKind, structure: entity) {
//                    return foundStruct
//                }
//            }
//        }
//
//        return nil
//    }
//
//    func objectWith(objectName: String, objectKind: String, path: String) -> [String: Any]? {
//        var structure = self.analysedFiles[path]
//
//        if structure == nil {
//            structure = self.structureFromFile(at: path)
//            self.analysedFiles[path] = structure
//        }
//        return objectWith(objectName: objectName, objectKind: objectKind, structure: structure!)
//    }
//
//    func allUsrsForObject(objectName: String, objectKind: String, path: String) -> [String] {
//        var structure = self.analysedFiles[path]
//
//        if structure == nil {
//            structure = self.structureFromFile(at: path)
//            self.analysedFiles[path] = structure
//        }
//
//        if let object = objectWith(objectName: objectName, objectKind: objectKind, structure: structure!) {
//            return allUsrsInStructure(structure: object)
//        }
//        return []
//    }
//
//    func allUsrsInStructure(structure: [String: Any]) -> [String] {
//        let usr = structure["usr"] as? String
//        var allUsrs : [String] = []
//
//        if let usr = usr {
//            allUsrs.append(usr)
//        }
//
//        if let entities = structure["entities"] as? [[String: Any]]  {
//            for entity in entities {
//                let foundUsrs = allUsrsInStructure(structure: entity)
//                allUsrs.append(contentsOf: foundUsrs)
//            }
//        }
//
//        return allUsrs
//    }
    
    func indexFile(at path: String) -> [String: SourceKitRepresentable] {
        if let file = File(path: path)  {
            do {
                var arguments = ["-sdk", "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk","-j4"]
                arguments.append(contentsOf: self.allPaths)
                //arguments.append(path)
                
                let request = Request.index(file: path, arguments: arguments)
                let result = try request.send()
                //                let index = (result["key.entities"] as! [SourceKitRepresentable]).map({ $0 as! [String: SourceKitRepresentable] })
                //
                //                let resIndex = result
                
                if self.printOutput {
                    //let resultString = "\(response)"
                    let resultString = "\(result)"
                    ResultToFileHandler.write(resultString: resultString, toFile: path)
                }
                
                let fileContents = file.contents
                let lines = (fileContents as NSString).lines().map({ $0.content })
                self.fileContents[path] = lines
                
                return result
            } catch {
                print("Could not index file: \(path)")
            }
        }
        return [:]
    }
    
    func findUsrOf(name: String, kind: String, path: String) -> String? {
        var structure = self.rawAnalysedData[path]
        
        if structure == nil {
            structure = indexFile(at: path)
            self.rawAnalysedData[path] = structure
        }
        
        return findUsrOf(name: name, kind: kind, structure: structure!)
    }
    
    func findUsrOf(name: String, kind: String, structure: [String: SourceKitRepresentable]) -> String? {
        let objectName = structure["key.name"] as? String
        let objectKind = structure["key.kind"] as? String
        print("\(objectName) - \(objectKind)")
        
        if objectName == name && objectKind == kind {
            if let usr = structure["key.usr"] as? String {
                print("\(usr)")
                return usr
            }
        }
        
        if let entities = structure["key.entities"] as? [[String: SourceKitRepresentable]] {
            for entity in entities {
                if let usr = findUsrOf(name: name, kind: kind, structure: entity) {
                    return usr
                }
            }
        }
        return nil
    }
    
    func findUsesOfUsr(usr: String) -> [String: [(line: Int, column: Int)]] {
        var uses : [String: [(line: Int, column: Int)]] = [:]
        
        //let paths = self.rawAnalysedData.keys

        for path in self.allPaths {
        //for path in paths {
            var structure = self.rawAnalysedData[path]
            
            if structure == nil {
                print("\(self.rawAnalysedData.keys)")
                print("Structure NIL - indexing - \(path)")
                
                structure = indexFile(at: path)
                self.rawAnalysedData[path] = structure
            }
            uses[path] = findUsesOfUsr(usr: usr, structure: structure!)
            //uses[path] = usesOfUSR(usr: usr, dictionary: structure!)
            if uses[path]!.count > 0 {
                print("\(path): \(uses[path])")
            }
        }
        return uses
    }
    
//    func usesOfUSR(usr: String, dictionary: [String: SourceKitRepresentable]) -> [(line: Int, column: Int)] {
//        if dictionary["key.usr"] as? String == usr,
//            let line = dictionary["key.line"] as? Int64,
//            let column = dictionary["key.column"] as? Int64 {
//            return [(Int(line), Int(column))]
//        }
//        return (dictionary["key.entities"] as? [SourceKitRepresentable])?
//            .map({ $0 as! [String: SourceKitRepresentable] })
//            .flatMap { usesOfUSR(usr: usr, dictionary: $0) } ?? []
//    }
    
//
    func findUsesOfUsr(usr: String, structure: [String: SourceKitRepresentable]) -> [(line: Int, column: Int)] {
        var uses: [(line: Int, column: Int)] = []

        if structure["key.usr"] as? String == usr {
            if let line = structure["key.line"] as? Int64 {
                //let kind = structure["key.kind"] as? String ?? ""

                    let use = (line: Int(line), column: 0)
                uses.append(use)
            }
        }

        if let substructure = structure["key.entities"] as? [SourceKitRepresentable] {
            let entities = substructure.map({ $0 as! [String: SourceKitRepresentable] })
            
            for entity in entities {
                let usesInEntity = findUsesOfUsr(usr: usr, structure: entity)
                uses.append(contentsOf: usesInEntity)
            }
        }

        return uses
    }
}
