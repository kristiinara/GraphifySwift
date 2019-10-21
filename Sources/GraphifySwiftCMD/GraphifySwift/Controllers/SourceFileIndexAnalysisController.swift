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
    let dataSyncController = DataSyncController()
    
    var fileQueue: [URL]
    var allPaths: [String]
    var printOutput = false
    var useModules = false
    
    var allFirstLevel: [String:FirstLevel] = [:]
    var allEntities: [String:Entity] = [:]
    
    var allClasses: [String: Class] = [:] // class.usr --> Class
    var classDictionary: [String: Class] = [:] // class.name --> Class
    
    var allMethods: [String: Function] = [:]
    var allVariables: [String: Variable] = [:]
    
    var allModules: [String: Module] = [:]
    
    init(homeURL: URL, dependencyURL: URL) {
        self.homeURL = homeURL
        self.dependencyURL = dependencyURL
        //self.sdk = "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk"
        self.sdk = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS13.0.sdk"
        //self.target = "arm64-apple-ios12.1"
        self.target = "arm64-apple-ios13.0"
        
        self.dependencyController = DependencyController(homeURL: dependencyURL)
        
        self.fileQueue = FolderUtility.getFileQueue(for: homeURL, ignore: ["Carthage", "Pods"])
        self.allPaths = self.fileQueue.map() { url in return url.path }
    }
    
    func analyseAllFiles() -> App {
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
        }
        
        for object in allObjects {
            object.printout(filler: " -")
        }
        
        let app = translateEntitiesToApp(objects: allObjects)
        self.findReferences(app: app)
        app.calculateCouplingBetweenClasses()
        
        self.addCommentsToApp(app: app)
        
        print("modules: \(self.allModules.keys)")
        
        return app
    }
    
    func analyseAllFilesAndAddToDatabase(finished: @escaping () -> Void) {
        let app = analyseAllFiles()
        
//        let reportPath = self.homeURL.appendingPathComponent("jscpd-report/jscpd-report.json")
//        print("jscpd report: \(reportPath)")
//        let duplicationParser = DuplicationParser(path: reportPath.path) //TODO: maybe pass url instead of String?
        
        let duplicationParser = DuplicationParser(homePath: homeURL.path, ignore: [".build/**","**/Carthage/**", "**/Pods/**"])
        duplicationParser.addDuplicatesToApp(app: app)
        
        ObjectPrinter.printApp(app)
        
        self.dataSyncController.finished = finished
        self.dataSyncController.sync(app: app)
    }
    
    func makeStructureRequest(at path: String) -> [String: SourceKitRepresentable] {
        if let file = File(path: path) {
            do {
                let structure = try Structure(file: file)
                return structure.dictionary
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
        
        //let object = (name != nil) ? Entity(name: name!, kind: kind, usr: usr, structure: structure) : Entity(kind: kind, usr: usr, structure: structure)
        let object = Entity(name: name, kind: kind, usr: usr, structure: structure)
        
        if let type = structure["key.type"] as? String {
            object.type = type
        }
        
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
        let type = structure["key.typename"] as? String
        
        print("handle substructure of kind: \(kind) type: \(type)")
        print("structure: \(structure)")
        
//        if kind == "source.lang.swift.decl.var.parameter" {
//            print("FuncParameter: \(name), method.name: \(entity.name)")
//            let parameter = FuncParameter(kind: kind!, type: type ?? "No type", name: name ?? "No name")
//            entity.parameters.append(parameter)
//            return
//        }
        
        if let type = type {
            entity.type = type
        }
        
        //TODO: change instructions to old instructions. Could we somehow add structure to each class and do the parsing there? Or add instructions to each method and do the parsing there?
        
        if let substructures = structure["key.substructure"] as? [[String: SourceKitRepresentable]] {
            for substructure in substructures {
                let kind = substructure["key.kind"] as? String
                let name = substructure["key.name"] as? String
                let type = substructure["key.typename"] as? String
                
                if kind == "source.lang.swift.decl.var.parameter" {
                    if let kind = kind, let name = name {
                        let parameter = FuncParameter(kind: kind, type: type ?? "No type", name: name)
                        entity.parameters.append(parameter)
                    }
                }
            }
        }
        
        let instruction = handleInstruction(structure)
        entity.instructions.append(instruction)
    }
    
    func handleInstruction(_ structure: [String: SourceKitRepresentable]) -> Instruction {
        let kind = structure["key.kind"] as! String
        let name = (structure["key.name"] as? String) ?? ""
        let offset = structure["key.offset"] as? Int64
        var instruction = Instruction(stringValue: name, kind: kind)
        
        switch kind {
        case LocalVariable.kittenKey:
            let localVariable = LocalVariable(stringValue: name, kind: kind)
            localVariable.typeName = structure["key.type"] as? String
            instruction = localVariable
        case MethodCall.kittenKey:
            instruction = MethodCall(stringValue: name, kind: kind)
        case For.kittenKey:
            instruction = For(stringValue: name, kind: kind)
        case ForEach.kittenKey:
            instruction = ForEach(stringValue: name, kind: kind)
        case While.kittenKey:
            instruction = While(stringValue: name, kind: kind)
        case RepeatWhile.kittenKey:
            instruction = RepeatWhile(stringValue: name, kind: kind)
        case If.kittenKey:
            instruction = If(stringValue: name, kind: kind)
        case Guard.kittenKey:
            instruction = Guard(stringValue: name, kind: kind)
        case Switch.kittenKey:
            instruction = Switch(stringValue: name, kind: kind)
        case Case.kittenKey:
            instruction = Case(stringValue: name, kind: kind)
        default: print("Not handles: \(name)") //self.notHandledInstances.append(kind)
        }
        
        instruction.offset = offset
        
        if let models = structure["key.substructure"] as? [[String: SourceKitRepresentable]] {
            for model in models {
                
                
                let subInstruction = self.handleInstruction(model)
                instruction.instructions.append(subInstruction)
            }
        }
        
        return instruction
    }
}
// add comments
extension SourceFileIndexAnalysisController {
    func addCommentsToApp(app: App) {
        for classInstance in app.allClasses {
            if let file = File(path: classInstance.path) {
                let comments = handleComments(file.contents)
                classInstance.comments = comments
            }
        }
    }
    
    func handleComments(_ fileContents: String) -> [Comment] {
        let lines = fileContents.components(separatedBy: "\n")
        var comments : [Comment] = []
        
        var lineNumber = 0
        var commentString = ""
        
        for line in lines {
            lineNumber += 1
            
            var slashIndex: String.Index?
            var longCommentIndex: String.Index?
            
            if line.contains("//") {
                if let range = line.range(of: "//") {
                    slashIndex = range.lowerBound
                }
            }
            
            if line.contains("/*") {
                if let range = line.range(of: "/*") {
                    longCommentIndex = range.lowerBound
                }
            }
            
            if let localSlashIndex = slashIndex, longCommentIndex == nil {
                commentString = String(line[localSlashIndex..<line.endIndex])
                comments.append(Comment(lineNumber: lineNumber, string: commentString))
                commentString = ""
                
                slashIndex = nil
                longCommentIndex = nil
            }
            
            if let localLongCommentIndex = longCommentIndex {
                commentString = String(line[localLongCommentIndex..<line.endIndex])
                comments.append(Comment(lineNumber: lineNumber, string: commentString))
                commentString = ""
                
                slashIndex = nil
                longCommentIndex = nil
            }
        }
        
        return comments
    }
}

// Convert to app
extension SourceFileIndexAnalysisController {
    func getModuleName(path: String) -> String {
        let localPath = path.replacingOccurrences(of: self.homeURL.path, with: "")
        let name = localPath.split(separator: "/")[0]
        
        return String(name)
    }
    
//    func getModuleName(path: String, homePath: String) -> String {
//        let localPath = path.replacingOccurrences(of: homePath, with: "")
//        let name = localPath.split(separator: "/")[0]
//
//        return String(name)
//    }
    
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
            
            var module: Module?
            
            if self.useModules {
                if let path = object.path {
                    let name = self.getModuleName(path: path)
                    
                    if let existingModule = self.allModules[name] {
                        module = existingModule
                    } else {
                        let newModule = Module(name: name, appKey: appKey)
                        
                        app.modules.append(newModule)
                        newModule.belongsToApp = app
                        
                        self.allModules[name] = newModule
                        module = newModule
                    }
                }
            }
            
            if module == nil {
                if let existingModule = self.allModules[appKey] {
                    module = existingModule
                } else {
                    let newModule = Module(name: appKey, appKey: appKey)
                    
                    app.modules.append(newModule)
                    newModule.belongsToApp = app
                    
                    self.allModules[appKey] = newModule
                    module = newModule
                }
            }
            
            if object.kind == ClassInstance.kittenKey {
                let classInstanceInstance = ClassInstance(name: object.name, appKey: appKey, modifier: "", module: module!)
                module?.classes.append(classInstanceInstance)
                
                classInstance = classInstanceInstance
            } else if object.kind == Struct.kittenKey {
                let structInstance = Struct(name: object.name, appKey: appKey, modifier: "", module: module!)
                module?.structures.append(structInstance)
                classInstance = structInstance
            } else if object.kind == Protocol.kittenKey {
                let protocolInstance = Protocol(name: object.name, appKey: appKey, modifier: "", module: module!)
                module?.protocols.append(protocolInstance)
                classInstance = protocolInstance
            }
            
            if let classInstance = classInstance {
                self.classDictionary[classInstance.name] = classInstance
            }
            
            if let path = object.path {
                classInstance?.path = path
            }
            
            if let usr = object.usr {
                self.allClasses[usr] = classInstance
                classInstance?.usr = usr
            }
            
            var parents = object.parentsClasses
            parents.append(contentsOf: object.parentStructs)
            
            for parent in parents {
                if let usr = parent.usr {
                    classInstance?.parentUsrs.append(usr)
                }
            }
            
            //TODO: make distinction between instance, class, static
            var methods: [Function] = []
            var variables: [Variable] = []
            
            for entity in object.entities {
                if let name = entity.name {
                    if entity.kind.contains("decl.function.method") {
                        let method = InstanceFunction(name: name, fullName: name, appKey: appKey, modifier: "", returnType: "")
                        method.instructions = entity.instructions
                        method.references = entity.allReferences
                        
                        methods.append(method) //TODO: add stuff into constructor
                        
                        if let usr = object.usr {
                            self.allMethods[usr] = method
                            method.usr = usr
                        }
                        
                        var count = 0
                        for parameter in entity.parameters {
                            let argument = Argument(name: parameter.name, type: parameter.type, position: count, appKey: method.appKey)
                            method.parameters.append(argument)
                            count += 1
                        }
                        
                        
                    } else if entity.kind.contains("decl.var") {
                        let variable = InstanceVariable(name: name, appKey: appKey, modifier: "", type: "", isStatic: false, isFinal: false)
                        
                        if let type = entity.type {
                            variable.type = type
                        }
                        variables.append(variable) //TODO: add stuff into constructor
                        
                        if let usr = object.usr {
                            self.allVariables[usr] = variable
                            variable.usr = usr
                        }
                    }
                } else {
                    print("entity with no name: \(entity.structure) path: \(object.path)")
                }
            }
            
            classInstance?.instanceMethods = methods
            classInstance?.instanceVariables = variables
        }
        
        for classInstance in app.allClasses {
            for variable in classInstance.allVariables {
                if let classType = self.classDictionary[variable.cleanedType] {
                    variable.typeClass = classType
                }
            }
        }
        
        return app
    }
    
    func findReferences(app: App) {
        //TODO: do this also for structs and class and static methods
        print("findReferences for \(app.name)")
        print("Allclasses: \(app.classes)")
        for classInstance in app.classes {
            print("References for class: \(classInstance.name)")
            for instanceMethod in classInstance.instanceMethods {
                for reference in instanceMethod.references {
                    if let method = self.allMethods[reference] {
                        instanceMethod.referencedMethods.append(method)
                        method.methodReferences.append(instanceMethod)
                    }
                    
                    if let variable = self.allVariables[reference] {
                        instanceMethod.referencedVariables.append(variable)
                        variable.methodReferences.append(instanceMethod)
                    }
                }
            }
            
            //Add parents and extendedInterfaces
            print("Fiding references for parentUsrs: \(classInstance.parentUsrs)")
            print("AllClasses: \(self.allClasses)")
            for usr in classInstance.parentUsrs {
                if let object = self.allClasses[usr] {
                    if let parentClass = object as? ClassInstance {
                        classInstance.inheritedClasses.append(parentClass)
                    } else if let parentProtocol = object as? Protocol {
                        classInstance.extendedInterfaces.append(parentProtocol)
                    } else if let parentStruct = object as? Struct {
                        classInstance.inheritedClasses.append(parentStruct)
                    }
                } else if usr.contains("c:objc(cs)") {
                    classInstance.parentName = usr.replacingOccurrences(of: "c:objc(cs)", with: "")
                }
            }
        }
    }
}


// Helper classes
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

class Entity {
    let name: String?
    let kind: String
    let usr: String?
    let structure: [String: SourceKitRepresentable]
    
    var type: String?
    
    var instructions: [Instruction] = []
    var entities: [Entity] = []
    var attributes: [Attribute] = []
    var parameters: [FuncParameter] = []
    
    var relatedObjects:[(name: String, kind: String, usr: String?)] = []
    
    init(name: String?, kind: String, usr: String?, structure: [String:SourceKitRepresentable]) {
        self.name = name
        self.kind = kind
        self.usr = usr
        self.structure = structure
    }
    
//    init(kind: String, usr: String?, structure: [String:SourceKitRepresentable]) {
//        self.name = "-- Undefined"
//        self.kind = kind
//        self.usr = usr
//        self.structure = structure
//    }
    
    var isReference : Bool {
        if let name = self.name {
            if name.contains(".ref.") {
                return true
            }
        }
        return false
    }
    
    var allReferences: [String] {
        var referenceList: [String] = []
        
        for entity in self.entities {
            if let entityUsr = entity.usr {
                referenceList.append(entityUsr)
            }
            referenceList.append(contentsOf: entity.allReferences)
        }
        
        return referenceList
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
//        for instruction in instructions {
//            instruction.printout(filler: "\(filler)\(filler)")
//        }
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

class Comment {
    var lineNumber: Int
    var string: String
    
    init(lineNumber: Int, string: String) {
        self.lineNumber = lineNumber
        self.string = string
    }
}
