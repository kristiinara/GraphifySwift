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
    var allPaths: [String] = []
    var printOutput = true
    var analysedFiles: [String: [String: Any]] = [:]
    
    var rawAnalysedData: [String: [String: SourceKitRepresentable]] = [:]
    var fileContents: [String: [String]] = [:]
    
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
