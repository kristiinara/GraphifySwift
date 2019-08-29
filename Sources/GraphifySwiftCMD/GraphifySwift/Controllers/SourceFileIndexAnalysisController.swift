//
//  SourceFileIndexAnalysisController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 29/08/2019.
//

import Foundation
import SourceKittenFramework

class SourceFileIndexAnalysisController {
    let homeURL: URL
    let dependencyURL: URL
    let sdk: String
    let target: String
    let dependencyController: DependencyController
    
    var fileQueue: [URL]
    var allPaths: [String]
    var printOutput = true
    
    var allFirstLevel: [String:FirstLevel] = [:]
    var allEntities: [String:Entity] = [:]
    
    var allClasses: [String: Class] = [:]
    var allMethods: [String: Function] = [:]
    var allVariables: [String: Variable] = [:]
    
    init(homeURL: URL, dependencyURL: URL) {
        self.homeURL = homeURL
        self.dependencyURL = dependencyURL
        self.sdk = "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk"
        self.target = "arm64-apple-ios12.1"
        
        self.dependencyController = DependencyController(homeURL: dependencyURL)
        
        self.fileQueue = FolderUtility.getFileQueue(for: homeURL, ignore: "Carthage")
        self.allPaths = self.fileQueue.map() { url in return url.path }
    }
    
    func analyseAllFiles() {
        var allObjects : [FirstLevel] = []
        
        while self.fileQueue.count > 0 {
            let fileUrl = self.fileQueue.remove(at: 0)
            let result = indexFile(at: fileUrl.path)
            
            let objects = analyseResult(result: result)
            for object in objects {
                object.path = fileUrl.path
                addStructureAnalysis(object: object, path: fileUrl.path)
            }
            
            allObjects.append(contentsOf: objects)
            
            //let structureResult = makeStructureRequest(at: fileUrl.path)
            
        }
        
        for object in allObjects {
            object.printout(filler: " -")
        }
        
        let app = translateEntitiesToApp(objects: allObjects)
        self.addReferences(app: app)
    }
    
    func makeStructureRequest(at path: String) -> [String: SourceKitRepresentable] {
        if let file = File(path: path) {
            do {
                let structure = try Structure(file: file)
                if let structure = structure.dictionary as? [String: SourceKitRepresentable] {
                    return structure
                } else {
                    return [:]
                }
                
                
            } catch {
                print("Could not get structure of file \(path)")
            }
        }
        return [:]
    }
    
    func makeIndexRequest(at path: String, filePaths: [String]) throws -> [String: SourceKitRepresentable] {
        var arguments = ["-target", self.target, "-sdk", self.sdk ,"-j4"]
        arguments.append(contentsOf: filePaths)
        
        let request = Request.index(file: path, arguments: arguments)
        print("---- request: ----")
        print("\(request)")
        
        let result = try request.send()
        
        return result
    }
    
    func indexFile(at path: String) -> [String: SourceKitRepresentable] {
        if self.dependencyController.resolved == false {
            self.resolveDependencies(with: path)
        }
        
        if let file = File(path: path)  {
            do {
                var paths = self.allPaths
                paths.append(contentsOf: self.dependencyController.successfullPaths)
                
                let result = try makeIndexRequest(at: path, filePaths: paths)
                
                if self.printOutput {
                    //let resultString = "\(response)"
                    let resultString = "\(result)"
                    ResultToFileHandler.write(resultString: resultString, toFile: path)
                }
                
                //let fileContents = file.contents
                //let lines = (fileContents as NSString).lines().map({ $0.content })
                //self.fileContents[path] = lines
                
                return result
            } catch {
                print("Could not index file: \(path)")
            }
        }
        return [:]
    }
    
    func resolveDependencies(with filePath: String) {
        while dependencyController.resolved == false {
            dependencyController.tryNextDependency() { dependencyPaths in
                do {
                    var paths = self.allPaths
                    paths.append(contentsOf: dependencyPaths)
                    
                    let _ = try makeIndexRequest(at: filePath, filePaths: paths)
                    print("Resolving dependency successful")
                    return true
                    
                } catch {
                    print("Resolving dependency failed")
                    return false
                }
            }
        }
    }
}

//Analysis
private extension SourceFileIndexAnalysisController {
    func analyseResult(result: [String: SourceKitRepresentable]) -> [FirstLevel] {
        guard let entities = result["key.entities"] as? [[String: SourceKitRepresentable]] else {
            return []
        }
        
        var objects : [FirstLevel] = []
        
        for entity in entities { // for every class/structure definition there should be one entity
            let kind = entity["key.kind"] as? String
            let name = entity["key.name"] as? String
            
            if let kind = kind, let name = name {
                print("Handle entity \(kind), name: \(name)")
                let object = handleFirstLevel(structure: entity)
                print("found: \(object)")
                objects.append(object)
                
                if let usr = object.usr {
                    self.allFirstLevel[usr] = object
                } else {
                    print("no usr: \(object.name)")
                }
            }
        }
        
        return objects
    }
    
    func handleFirstLevel(structure: [String: SourceKitRepresentable]) -> FirstLevel {
        let kind = structure["key.kind"] as! String
        let name = structure["key.name"] as! String
        let usr = structure["key.usr"] as? String
        let line = structure["key.line"] as? Int
        let column = structure["key.column"] as? Int
        
        var relatedClasses: [(name: String, usr: String?)] = []
        var relatedStructures: [(name: String, usr: String?)] = []
        
        if let related = structure["key.related"] as? [[String: SourceKitRepresentable]] {
            for relatedInstence in related {
                let kind = relatedInstence["key.kind"] as? String
                let name = relatedInstence["key.name"] as? String
                let usr = relatedInstence["key.usr"] as? String
                
                if kind == "source.lang.swift.ref.class" {
                    if let name = name {
                        relatedClasses.append((name: name, usr: usr))
                    }
                } else if kind == "ource.lang.swift.ref.struct" {
                    if let name = name {
                        relatedStructures.append((name: name, usr: usr))
                    }
                }
            }
        }
        
        let object = FirstLevel(name: name, kind: kind, usr: usr)
        object.parentStructs = relatedStructures
        object.parentsClasses = relatedClasses
        
        if let entities = structure["key.entities"] as? [[String: SourceKitRepresentable]] {
            for entity in entities {
                if let handledEntity = handleEntity(structure: entity) {
                    object.entities.append(handledEntity)
                    
                    if let usr = handledEntity.usr {
                        self.allEntities[usr] = handledEntity
                    } else {
                        print("no usr: \(handledEntity.name)")
                    }
                } else {
                    print("Could not handle entity: \(entity)")
                }
            }
        }
        
        print("Found \(object) on line \(String(describing: line)) column \(String(describing: column))")
        return object
    }
    
    func handleEntity(structure: [String: SourceKitRepresentable]) -> Entity? {
        let name = structure["key.name"] as? String
        
        guard let kind = structure["key.kind"] as? String else {
            return nil
        }
        
        let usr = structure["key.usr"] as? String
        
        var object = (name != nil) ? Entity(name: name!, kind: kind, usr: usr, structure: structure) : Entity(kind: kind, usr: usr, structure: structure)
        
        if let attributes = structure["key.attributes"] as? [[String: SourceKitRepresentable]]{
            for attribute in attributes {
                if let name = attribute["key.attribute"] as? String {
                    let handledAttribute = Attribute(name: name)
                    object.attributes.append(handledAttribute)
                }
            }
        }
        
        if let entities = structure["key.entities"] as? [[String: SourceKitRepresentable]] {
            for entity in entities {
                if let handledEntity = handleEntity(structure: entity) {
                    object.entities.append(handledEntity)
                    
                    if let usr = handledEntity.usr {
                        self.allEntities[usr] = handledEntity
                    } else {
                        print("no usr: \(handledEntity.name)")
                    }
                }
            }
        }
        
        if let related = structure["key.related"] as? [[String: SourceKitRepresentable]] {
            for relatedObject in related {
                let kind = relatedObject["key.kind"] as? String
                let name = relatedObject["key.name"] as? String
                let usr = relatedObject["key.usr"] as? String
                
                if kind != nil && name != nil {
                    object.relatedObjects.append((name: name!, kind: kind!, usr: usr))
                }
            }
        }
        
        return object
    }
}

// structure analysis
private extension SourceFileIndexAnalysisController {
    func addStructureAnalysis(object: FirstLevel, path: String) {
        let result = makeStructureRequest(at: path)
        print("Structure analysis: \(result)")
        
        guard let substructure = result["key.substructure"] as? [[String: SourceKitRepresentable]] else {
            return
        }
        
        guard substructure.count > 0 else {
            return
        }
        
        for structure in substructure {
            let kind = structure["key.kind"] as? String
            let name = structure["key.name"] as? String
            
            print("First level: \(kind) - \(name)")
            
            //we found the correct object
            if kind == object.kind && name == object.name {
                print("-- match with object!")
                if let children = structure["key.substructure"] as? [[String: SourceKitRepresentable]] {
                    for child in children {
                        let childName = child["key.name"] as? String
                        let childKind = child["key.kind"] as? String
                        
                        for entity in object.entities {
                            if childName == entity.name && childKind == entity.kind {
                                handleSubstructure(structure: child, entity: entity)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func handleSubstructure(structure: [String: SourceKitRepresentable], entity: Entity) {
        let kind = structure["key.kind"] as? String
        let name = structure["key.name"] as? String
        let type = structure["key.type"] as? String
        
        if kind == "source.lang.swift.decl.var.parameter" {
            let parameter = FuncParameter(kind: kind!, type: type ?? "No type", name: name ?? "No name")
            entity.parameters.append(parameter)
            return
        }
        
        let instruction = FuncInstruction(stringValue: name ?? "No name", kind: kind ?? "No kind")
        entity.instructions.append(instruction)
        
        if let substructures = structure["key.substructure"] as? [[String: SourceKitRepresentable]] {
            for substructure in substructures {
                handleSubInstructions(structure: substructure, entity: instruction)
            }
        }
    }
    
    func handleSubInstructions(structure: [String: SourceKitRepresentable], entity: FuncInstruction) {
        let kind = structure["key.kind"] as? String
        let name = structure["key.name"] as? String
        let type = structure["key.type"] as? String
        
        let instruction = FuncInstruction(stringValue: name ?? "No name", kind: kind ?? "No kind")
        entity.instructions.append(instruction)
        
        if let substructures = structure["key.substructure"] as? [[String: SourceKitRepresentable]] {
            for substructure in substructures {
                handleSubInstructions(structure: substructure, entity: instruction)
            }
        }
    }
}


class FirstLevel {
    var path: String?
    let name: String
    let kind: String
    let usr: String?
    var parentsClasses: [(name: String, usr: String?)] = []
    var parentStructs: [(name: String, usr: String?)] = []
    
    var entities: [Entity] = []
    
    init(name: String, kind: String, usr: String?) {
        self.name = name
        self.kind = kind
        self.usr = usr
    }
    
    func printout(filler: String) {
        print("\(filler) name: \(name)")
        print("\(filler) kind: \(kind)")
        print("\(filler) user: \(usr ?? "----")")
        
        print("\(filler) parentClasses: \(parentsClasses)")
        print("\(filler) parentStructs: \(parentStructs)")
        
        print("\(filler) entities:")
        for entity in entities {
            entity.printout(filler: "\(filler)\(filler)")
        }
    }
}

extension SourceFileIndexAnalysisController {
    func translateEntitiesToApp(objects: [FirstLevel]) -> App {
        let appName = homeURL.lastPathComponent
        let appKey = appName
        
        //TODO: fix this with correct app info
        let app = App(
            name: appName,
            targetSdk: "sdk1",
            dateDownload: "2019-04-18 14:35:10",
            package: appName,
            versionCode: 1,
            versionName: "1",
            appKey: appKey,
            developer: "Me",
            sdk: "11",
            categroy: "PRODUCTIVITY"
        )
        
        for object in objects {
            var classInstance: Class?
            
            if object.kind == ClassInstance.kittenKey {
                let classInstanceInstance = ClassInstance(name: object.name, appKey: appKey, modifier: "")
                app.classes.append(classInstanceInstance)
                classInstance = classInstanceInstance
            } else if object.kind == Struct.kittenKey {
                let structInstance = Struct(name: object.name, appKey: appKey, modifier: "")
                app.structures.append(structInstance)
                classInstance = structInstance
            }
            
            if let usr = object.usr {
                self.allClasses[usr] = classInstance
                classInstance?.usr = usr
            }
            
            //TODO: make distinction between instance, class, static
            var methods: [Function] = []
            var variables: [Variable] = []
            
            for entity in object.entities {
                if entity.kind.contains("decl.function.method") {
                    let method = InstanceFunction(name: entity.name, fullName: entity.name, appKey: appKey, modifier: "", returnType: "")
                    method.instructions = entity.instructions
                    
                    methods.append(method) //TODO: add stuff into constructor
                    
                    if let usr = object.usr {
                        self.allMethods[usr] = method
                    }
                    
                } else if entity.kind.contains("decl.var") {
                    let variable = InstanceVariable(name: entity.name, appKey: appKey, modifier: "", type: "", isStatic: false, isFinal: false)
                    variables.append(variable) //TODO: add stuff into constructor
                    
                    if let usr = object.usr {
                        self.allVariables[usr] = variable
                    }
                }
            }
            
            classInstance?.instanceMethods = methods
            classInstance?.instanceVariables = variables
        }
        return app
    }
    
    func addReferences(app: App) {
        for classInstance in app.classes {
            
        }
    }
}

class Entity {
    let name: String
    let kind: String
    let usr: String?
    let structure: [String: SourceKitRepresentable]
    
    var instructions: [FuncInstruction] = []
    var entities: [Entity] = []
    var attributes: [Attribute] = []
    var parameters: [FuncParameter] = []
    
    var relatedObjects:[(name: String, kind: String, usr: String?)] = []
    
    init(name: String, kind: String, usr: String?, structure: [String:SourceKitRepresentable]) {
        self.name = name
        self.kind = kind
        self.usr = usr
        self.structure = structure
    }
    
    init(kind: String, usr: String?, structure: [String:SourceKitRepresentable]) {
        self.name = "-- Undefined"
        self.kind = kind
        self.usr = usr
        self.structure = structure
    }
    
    var isReference : Bool {
        if self.name.contains(".ref.") {
            return true
        }
        return false
    }
    
    func printout(filler: String) {
        print("\(filler) name: \(name)")
        print("\(filler) kind: \(kind)")
        print("\(filler) user: \(usr ?? "----")")
        
        print("\(filler) attributes: ")
        for attribute in attributes {
            attribute.printout(filler: "\(filler)\(filler)")
        }
        
        print("\(filler) entities:")
        for entity in entities {
            entity.printout(filler: "\(filler)\(filler)")
        }
        
        print("\(filler) related: \(self.relatedObjects)")
        
        print("\(filler) parameters: ")
        for parameter in parameters {
            parameter.printout(filler: "\(filler)\(filler)")
        }
        
        print("\(filler) instructions: ")
        for instruction in instructions {
            instruction.printout(filler: "\(filler)\(filler)")
        }
    }
}

class Attribute {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    func printout(filler: String) {
        print("\(filler) name: \(name)")
    }
}

class FuncParameter {
    let kind: String
    let type: String
    let name: String
    
    init(kind: String, type: String, name: String) {
        self.kind = kind
        self.type = type
        self.name = name
    }
    
    func printout(filler: String) {
        print("\(filler) name: \(name) type: \(type)")
    }
}

class FuncInstruction : Instruction {
//    let stringValue: String
//    let kind: String
    
    //var instructions: [FuncInstruction] = []
    
//    init(stringValue: String, kind: String) {
//        self.stringValue = stringValue
//        self.kind = kind
//    }
    
    func printout(filler: String) {
        print("\(filler) name: \(kind) type: \(stringValue)")
        print("\(filler) instructions: ")
        for instruction in instructions {
            if let instruction = instruction as? FuncInstruction {
                instruction.printout(filler: "\(filler)\(filler)")
            }
        }
    }
}
