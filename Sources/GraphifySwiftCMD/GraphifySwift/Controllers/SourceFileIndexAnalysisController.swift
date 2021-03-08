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
    let appKey: String
    let appName: String
    let developer: String
    let category: String
    let language: String
    var stars: Int?
    
    var project: Project?
    
    let dependencyController: DependencyController
    //let dataSyncController = DataSyncController()
    var dataSyncController = DataSyncController()
    
    var fileQueue: [URL]
    var allPaths: [String]
    var printOutput = true
    var useModules = false
    var insertToDatabase = true
    
    var allFirstLevel: [String:FirstLevel] = [:]
    var allEntities: [String:Entity] = [:]
    
    var allClasses: [String: Class] = [:] // class.usr --> Class
    var classDictionary: [String: Class] = [:] // class.name --> Class
    
    var allMethods: [String: Function] = [:]
    var allVariables: [String: Variable] = [:]
    
    var allModules: [String: Module] = [:]
    
    var errorDesctiptions: [String] = []
    
    struct AnalysisError: Error {
        let message: String
        public var errorDescription: String? { return self.message }
        
        init(message: String) {
            self.message = message
        }
    }
    
    init(project:Project) throws {
        self.project = project
        
        guard let homeURL = project.localUrl else {
            throw AnalysisError(message: "Missing localURL for \(project.name)")
        }
        
        self.homeURL = homeURL
        var dependencyURL = homeURL
        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)
        
        self.dependencyURL = dependencyURL
        self.appName = project.name
        self.appKey = project.appKey ?? homeURL.lastPathComponent
        self.developer = project.developer
        self.category = "\(project.categories ?? [])"
        self.language = "Swift"
        self.stars = project.stars
        
        //self.sdk = "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk"
        self.sdk = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
        //self.target = "arm64-apple-ios12.1"
        self.target = "arm64-apple-ios14.2"
        
        self.dependencyController = DependencyController(homeURL: dependencyURL)
        
        self.fileQueue = FolderUtility.getFileQueue(for: homeURL, ignore: ["Carthage", "Pods", "Frameworks"])
        self.allPaths = self.fileQueue.map() { url in return url.path }
    }
    
    init(homeURL: URL, dependencyURL: URL) {
        self.homeURL = homeURL
        self.dependencyURL = dependencyURL
        
        //self.sdk = "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk"
        self.sdk = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS13.0.sdk"
        //self.target = "arm64-apple-ios12.1"
        self.target = "arm64-apple-ios13.0"
        
        self.dependencyController = DependencyController(homeURL: dependencyURL)
        
        self.fileQueue = FolderUtility.getFileQueue(for: homeURL, ignore: ["Carthage", "Pods", "Frameworks"])
        self.allPaths = self.fileQueue.map() { url in return url.path }
        
        self.appName = homeURL.lastPathComponent
        self.appKey = appName
        self.developer = "Undefined"
        self.category = "Undefined"
        self.language = "Swift"
    }
    
    
    
    func analyseAllFiles() -> App {
        var allObjects : [FirstLevel] = []
        
        var mixedLanguage = false
        
        while self.fileQueue.count > 0 {
            let fileUrl = self.fileQueue.remove(at: 0)
            if fileUrl.path.hasSuffix(".swift") {
                var path = fileUrl.path
                let result = indexFile(at: fileUrl.path)
                
                let objects = analyseResult(result: result.structure, dataString: result.dataString)
                for object in objects {
                    object.path = fileUrl.path
                    addStructureAnalysis(object: object, path: fileUrl.path)
                }
                
                allObjects.append(contentsOf: objects)
            } else {
                mixedLanguage = true
            }
        }
        
        for object in allObjects {
            object.printout(filler: " -")
        }
        
        let app = translateEntitiesToApp(objects: allObjects)
        app.languageMixed = mixedLanguage
        
        self.findReferences(app: app)
        app.calculateCouplingBetweenClasses()
        
        self.addCommentsToApp(app: app)
        self.calculateSize(app: app)
        
        print("modules: \(self.allModules.keys)")
        
        return app
    }
    
    func analyseAllFilesAndAddToDatabase(finished: @escaping () -> ()) {
        let app = analyseAllFiles()
        
//        let reportPath = self.homeURL.appendingPathComponent("jscpd-report/jscpd-report.json")
//        print("jscpd report: \(reportPath)")
//        let duplicationParser = DuplicationParser(path: reportPath.path) //TODO: maybe pass url instead of String?
        
        let duplicationParser = DuplicationParser(homePath: homeURL.path, ignore: [".build/**","**/Carthage/**", "**/Pods/**"])
        duplicationParser.addDuplicatesToApp(app: app)
        
        ObjectPrinter.printApp(app)
        
        if insertToDatabase == true {
            self.dataSyncController.finished = { [weak self] descriptions in
                if let this = self {
                    this.errorDesctiptions.append(contentsOf: descriptions)
                    this.project?.errorDescriptions = this.errorDesctiptions
                }
                finished()
            }
            self.dataSyncController.sync(app: app)
        } else {
            finished()
        }
    }

    func makeStructureRequest(at path: String, filePaths: [String]) -> [String: SourceKitRepresentable] {
        if let file = File(path: path) {
            do {
                let structure = try Structure(file: file)
                return structure.dictionary
            } catch let error {
                self.errorDesctiptions.append(error.localizedDescription)
                print("Could not get structure of file \(path)")
            }
        }
        return [:]
    }
    
    func docRequest(at path: String, filePaths: [String]) -> [String: SourceKitRepresentable] {
        if let file = File(path: path) {
            var arguments = ["-target", self.target, "-sdk", self.sdk ,"-j4"]
            arguments.append(contentsOf: filePaths)
            
            let structure = SwiftDocs(file: file, arguments: arguments)
             
            if self.printOutput {
                let resultString = "\(String(describing: structure))"
                ResultToFileHandler.writeOther(resultString: resultString, toFile: path)
            }
             
            return structure?.docsDictionary ?? [:]
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
    
    func indexFile(at path: String) -> (structure: [String: SourceKitRepresentable], dataString: String) {
        if self.dependencyController.resolved == false {
            self.resolveDependencies(with: path)
        }
        
        if let file = File(path: path)  {
            do {
                let fileContents = file.contents
                
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
                
                return (structure: result, dataString: fileContents)
            } catch let error {
                self.errorDesctiptions.append(error.localizedDescription)
                print("Could not index file: \(path), error: \(error.localizedDescription)")
            }
        }
        return (structure: [:], dataString: "")
    }
    
    func resolveDependencies(with filePath: String) {
        while dependencyController.resolved == false {
            dependencyController.tryNextDependency() { [weak self] dependencyPaths in
                if let self = self {
                    do {
                        var paths = self.allPaths
                        paths.append(contentsOf: dependencyPaths)
                        
                        let _ = try makeIndexRequest(at: filePath, filePaths: paths)
                        print("Resolving dependency successful")
                        return true
                        
                    } catch let error {
                        self.errorDesctiptions.append(error.localizedDescription)
                        print("Resolving dependency failed")
                        return false
                    }
                }
                return false
            }
        }
    }
}

//Analysis
private extension SourceFileIndexAnalysisController {
    func analyseResult(result: [String: SourceKitRepresentable], dataString: String) -> [FirstLevel] {
        guard let entities = result["key.entities"] as? [[String: SourceKitRepresentable]] else {
            return []
        }
        
        var objects : [FirstLevel] = []
        
        for entity in entities { // for every class/structure definition there should be one entity
            let kind = entity["key.kind"] as? String
            let name = entity["key.name"] as? String
            
            if let kind = kind, let name = name {
                print("Handle entity \(kind), name: \(name)")
                let object = handleFirstLevel(structure: entity, dataString: dataString)
                
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
    
    func findMinLine(structure: [String:SourceKitRepresentable]) -> Int? {
        var minLine: Int? = nil
//        print("findMinLIne form: \(structure)")
//        print("key.line? \(structure["key.line"] as? Int64)")
        
        if let line = structure["key.line"] as? Int64 {
            let intLine = Int(line)
          //  print("key.line: \(line)")
            if minLine == nil || intLine < minLine! {
                minLine = intLine
            }
        }
        
        if let entities = structure["key.entities"] as? [[String: SourceKitRepresentable]] {
            for entity in entities {
                if let line = findMinLine(structure: entity) {
                   // print("key.line: \(line)")
                    if minLine == nil || line < minLine! {
                        minLine = line
                    }
                }
            }
        }
       // print("Res minLine: \(minLine)")
        
        return minLine
    }
    
    func findMaxLine(structure: [String:SourceKitRepresentable]) -> Int? {
        var maxLine: Int? = nil
//        print("findMaxLine form: \(structure)")
//        print("key.line? \(structure["key.line"] as? Int64)")
//
        if let line = structure["key.line"] as? Int64 {
            let intLine = Int(line)
           // print("key.line: \(line)")
            if maxLine == nil || intLine > maxLine! {
                maxLine = intLine
            }
        }
        
        if let entities = structure["key.entities"] as? [[String: SourceKitRepresentable]] {
            for entity in entities {
                if let line = findMaxLine(structure: entity) {
                   // print("key.line: \(line)")
                    if maxLine == nil || line > maxLine! {
                        maxLine = line
                    }
                }
            }
        }
        
        return maxLine
    }
    
    func handleFirstLevel(structure: [String: SourceKitRepresentable], dataString: String) -> FirstLevel {
       // print("handle first level, dataString: \(dataString)")
        let kind = structure["key.kind"] as! String
        let name = structure["key.name"] as! String
        let usr = structure["key.usr"] as? String
        let line = structure["key.line"] as? Int
        let column = structure["key.column"] as? Int
        let startLine = findMinLine(structure: structure)
        let endLine = findMaxLine(structure: structure)
        
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
                } else if kind == "source.lang.swift.ref.struct" {
                    if let name = name {
                        relatedStructures.append((name: name, usr: usr))
                    }
                } else if kind == "source.lang.swift.ref.protocol" {
                    if let name = name {
                        relatedClasses.append((name: name, usr: usr))
                    }
                }
            }
        }
        
        let object = FirstLevel(name: name, kind: kind, usr: usr)
        object.parentStructs = relatedStructures
        object.parentsClasses = relatedClasses
        
        object.startLine = startLine
        object.endLine = endLine
        
        print("FirstLevel startLine: \(startLine), endLine: \(endLine)")
        
        if let startLine = startLine, let endLine = endLine {
            object.dataString = dataStringBetweenLines(startLine: startLine, endLine: endLine, dataString: dataString)
        }
        
        if let entities = structure["key.entities"] as? [[String: SourceKitRepresentable]] {
            for entity in entities {
                if let handledEntity = handleEntity(structure: entity, dataString: dataString) {
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
    
    func dataStringBetweenLines(startLine: Int, endLine: Int, dataString: String) -> String {
       // print("String between startLine: \(startLine), endLine: \(endLine)")
        
        var start = startLine
        var end = endLine
        
        //let allLines = dataString.split { char in char.isNewline }
        let allLines = dataString.components(separatedBy: CharacterSet.newlines)
        
        var count = 0
        for line in allLines {
          //  print("\(count) - \(line)")
            count += 1
        }
        
        
        if start >= allLines.count {
            print("startLine \(start) too big, set to \(allLines.count)")
            start = allLines.count
        }
        
        if end >= allLines.count {
            print("endLine \(end) too big, set to \(allLines.count - 1)")
            end = allLines.count - 1
        }
        
        let lines = allLines[(start - 1)...end]
                    
        let newDataString = lines.reduce("") { res, line in
            if res.count == 0 {
                return String(line)
            } else {
                return "\(res)\n\(line)"
            }
        }
        return newDataString
    }
    
    func handleEntity(structure: [String: SourceKitRepresentable], dataString: String) -> Entity? {
        let name = structure["key.name"] as? String
        
        guard let kind = structure["key.kind"] as? String else {
            return nil
        }
        
        let usr = structure["key.usr"] as? String
        
        //let object = (name != nil) ? Entity(name: name!, kind: kind, usr: usr, structure: structure) : Entity(kind: kind, usr: usr, structure: structure)
        let object = Entity(name: name, kind: kind, usr: usr, structure: structure)
        let startLine = findMinLine(structure: structure)
        let endLine = findMaxLine(structure: structure)
        object.startLine = startLine
        object.endLine = endLine
        
        if let startLine = startLine, let endLine = endLine {
         //   print("Entity - name: \(name) startLine: \(startLine), endLine: \(endLine), structure: \(structure)")
            
            object.dataString = dataStringBetweenLines(startLine: startLine, endLine: endLine, dataString: dataString)
        }
        
        
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
                if let handledEntity = handleEntity(structure: entity, dataString: dataString) {
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
        var paths = self.allPaths
        paths.append(contentsOf: self.dependencyController.successfullPaths)
        
        let result = makeStructureRequest(at: path, filePaths: paths)
//        print("Structure analysis: \(result)")
        
        guard let substructure = result["key.substructure"] as? [[String: SourceKitRepresentable]] else {
            return
        }
        
        guard substructure.count > 0 else {
            return
        }
        
        for structure in substructure {
            let kind = structure["key.kind"] as? String
            let name = structure["key.name"] as? String
            
            //print("First level: \(kind) - \(name)")
            
            //we found the correct object
            if kind == object.kind && name == object.name {
                //print("-- match with object!")
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
        let accessModifier = structure["key.accessibility"] as? String
        
        if let accessModifier = accessModifier {
            if accessModifier.hasPrefix("source.lang.swift.accessibility.") {
                entity.accessModifier = String(accessModifier.dropFirst("source.lang.swift.accessibility.".count))
            } else {
                entity.accessModifier = accessModifier
            }
        }
        
//        print("handle substructure of kind: \(kind) type: \(type)")
//        print("structure: \(structure)")
//
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
            
            if substructures.count == entity.parameters.count {
                if (kind?.starts(with: "source.lang.swift.decl.function.method") ?? false) == true {
                    //method and no substructure --> must be abstract method
                    //somethimes fails when only one line in method
                    entity.isAbstract = true
                }
            }
        } else {
            if (kind?.starts(with: "source.lang.swift.decl.function.method") ?? false) == true {
                //method and no substructure --> must be abstract method
                entity.isAbstract = true
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
        //TODO: fix this with correct app info
        let app = App(
            name: appName,
            targetSdk: self.sdk,
            dateDownload: "2019-11-14 14:35:10",
            package: appName,
            versionCode: 1,
            versionName: "1",
            appKey: appKey,
            developer: self.developer,
            sdk: self.sdk,
            categroy: self.category,
            language: self.language,
            languageMixed: false,
            platform: "iOS"
        )
        if let stars = self.stars {
            app.stars = stars
        }
        
        if let project = self.project {
            if project.appstoreLink != nil {
                app.inAppStore = true
            }
        }
        
        let tests = FolderUtility.getNumberOfTests(for: homeURL, ignore: ["Carthage", "Pods", "Frameworks"])
        app.numberOfTests = tests.tests
        app.numberOfUITests = tests.uitests
        
        let floatingExtensions = self.addObjectsToApp(objects: objects, app: app)
        // try to add floating extensions again, in the hope that corresponding classes were already added
        let stillFloating = self.addObjectsToApp(objects: floatingExtensions, app: app)
        
        print("floatingExtensions: \(floatingExtensions.map() { object in object.name } )")
        print("stillFloating: \(stillFloating.map() { object in object.name } )")
        
        let names = stillFloating.map() { object in object.name }
        
        app.numberOfExtensions = (Set(names)).count
        
        return app
    }
    
    func addObjectsToApp(objects: [FirstLevel], app: App) -> [FirstLevel] {
        var floatingExtensions: [FirstLevel] = []
        var classesWithEmptyType: [String: Class] = [:]
        
        for object in objects {
            var classInstance: Class?
            
            var module: Module?
            
            if self.useModules {
                if let path = object.path {
                    let name = self.getModuleName(path: path)
                    
                    if let existingModule = self.allModules[name] {
                        module = existingModule
                    } else {
                        let newModule = Module(name: name, appKey: app.appKey)
                        
                        app.modules.append(newModule)
                        newModule.belongsToApp = app
                        
                        self.allModules[name] = newModule
                        module = newModule
                    }
                }
            }
            
            if module == nil {
                if let existingModule = self.allModules[app.appKey] {
                    module = existingModule
                } else {
                    let newModule = Module(name: app.appKey, appKey: app.appKey)
                    
                    app.modules.append(newModule)
                    newModule.belongsToApp = app
                    
                    self.allModules[app.appKey] = newModule
                    module = newModule
                }
            }
            
            var newInstance = true
            if object.kind == ClassInstance.kittenKey {
                let classInstanceInstance = ClassInstance(name: object.name, appKey: app.appKey, modifier: "", module: module!)
                module?.classes.append(classInstanceInstance)
                
                classInstance = classInstanceInstance
            } else if object.kind == Struct.kittenKey {
                let structInstance = Struct(name: object.name, appKey: app.appKey, modifier: "", module: module!)
                module?.structures.append(structInstance)
                classInstance = structInstance
            } else if object.kind == Protocol.kittenKey {
                let protocolInstance = Protocol(name: object.name, appKey: app.appKey, modifier: "", module: module!)
                module?.protocols.append(protocolInstance)
                classInstance = protocolInstance
            } else if object.kind == "source.lang.swift.decl.extension.class" {
                if let classInstanceInstance = self.classDictionary[object.name] as? ClassInstance {
                    newInstance = false
                    classInstance = classInstanceInstance
                } else {
                    floatingExtensions.append(object)
                    newInstance = false
                }
                //TODO: handle cases where extension is found before class itself??
            } else if object.kind == "source.lang.swift.decl.extension.struct" {
                if let structInstance = self.classDictionary[object.name] as? Struct {
                    newInstance = false
                    classInstance = structInstance
                } else {
                    floatingExtensions.append(object)
                    newInstance = false
                }
            } else if object.kind == "source.lang.swift.decl.extension.protocol" {
                if let protocolInstance = self.classDictionary[object.name] as? Struct {
                    newInstance = false
                    classInstance = protocolInstance
                } else {
                    floatingExtensions.append(object)
                    newInstance = false
                }
            }
            
            if newInstance == true {
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
                
                //TODO: should we also somehow add stuff about extensions?
                if let dataString = object.dataString {
                    //print("Class entity.dataString: \(dataString)")
                    classInstance?.dataString = dataString
                }
            }
            
            if let classInstance = classInstance {
                var parents = object.parentsClasses
                parents.append(contentsOf: object.parentStructs)
                
                for parent in parents {
                    if let usr = parent.usr {
                        classInstance.parentUsrs.append(usr)
                    }
                }
                
                var methods: [Function] = []
                var variables: [Variable] = []
                
                for entity in object.entities {
                    if let name = entity.name {
                        if entity.kind.contains("decl.function") {
                            var method: Function?
                            
                            if entity.kind == InstanceFunction.kittenKey {
                                method = InstanceFunction(name: name, fullName: name, appKey: app.appKey, modifier: entity.accessModifier ?? "", returnType: entity.type ?? "")
                            } else if entity.kind == ClassFunction.kittenKey {
                                method = ClassFunction(name: name, fullName: name, appKey: app.appKey, modifier: entity.accessModifier ?? "", returnType: entity.type ?? "")
                            } else if entity.kind == StaticFunction.kittenKey {
                                method = StaticFunction(name: name, fullName: name, appKey: app.appKey, modifier: entity.accessModifier ?? "", returnType: entity.type ?? "")
                            }
                            
                            if let method = method {
                                method.instructions = entity.instructions
                                method.references = entity.allReferences
                                if classInstance.isInterface {
                                    //can only be abstract, if classInstance itself is interface
                                    method.isAbstract = entity.isAbstract
                                }
                                
                                if let dataString = entity.dataString {
                                  //  print("Method entity.dataString: \(dataString)")
                                    method.dataString = dataString
                                }
                                
                                methods.append(method) //TODO: add stuff into constructor
                                
                                if let usr = entity.usr {
                                    self.allMethods[usr] = method
                                    method.usr = usr
                                }
                                
                                var count = 0
                                for parameter in entity.parameters {
                                    let argument = Argument(name: parameter.name, type: parameter.type, position: count, appKey: method.appKey)
                                    method.parameters.append(argument)
                                    count += 1
                                }
                                
                                if let type = entity.type {
                                    method.returnType = type
                                } else {
                                    classesWithEmptyType[classInstance.name] = classInstance
                                }
                            }
                        }
                        if entity.kind.contains("decl.var") {
                            var variable: Variable?
                            
                            if entity.kind == InstanceVariable.kittenKey {
                                variable = InstanceVariable(name: name, appKey: app.appKey, modifier: entity.accessModifier ?? "", type: entity.type ?? "", isStatic: false, isFinal: false)
                            } else if entity.kind == ClassVariable.kittenKey {
                                variable = ClassVariable(name: name, appKey: app.appKey, modifier: entity.accessModifier ?? "", type: entity.type ?? "", isStatic: true, isFinal: false)
                            } else if entity.kind == StaticVariable.kittenKey {
                                variable = StaticVariable(name: name, appKey: app.appKey, modifier: entity.accessModifier ?? "", type: entity.type ?? "", isStatic: true, isFinal: false)
                            }
                            
                            if let variable = variable {
                                if let type = entity.type {
                                    variable.type = type
                                } else {
                                    classesWithEmptyType[classInstance.name] = classInstance
                                }
                                
                                variables.append(variable) //TODO: add stuff into constructor
                                
                                if let dataString = entity.dataString {
                                   // print("Variable entity.dataString: \(dataString)")
                                    variable.dataString = dataString
                                }
                                
                                if let usr = entity.usr {
                                    self.allVariables[usr] = variable
                                    variable.usr = usr
                                }
                            }
                        }
                    } else {
                        print("entity with no name: \(entity.structure) path: \(object.path)")
                    }
                }
                
                classInstance.instanceMethods.append(contentsOf: methods)
                classInstance.instanceVariables.append(contentsOf: variables)
            } else {
                print("Classinstance = NIL! Extension found before class declaration?")
            }
        }
        
        for classInstancePair in classesWithEmptyType {
            let classInstance = classInstancePair.value
            //print("emtpy type in \(classInstance.name)")
            //TODO: make doc request --> extract type info (maybe something additional as well?
            var paths = self.allPaths
            paths.append(contentsOf: self.dependencyController.successfullPaths)
            
            let result = self.docRequest(at: classInstance.path, filePaths: paths)
            self.addInfoFromDocResult(classInstance: classInstance, result: result)
        }
        print("Finished hangling empty types")
        
        for classInstance in app.allClasses {
            for variable in classInstance.allVariables {
                if let classType = self.classDictionary[variable.cleanedType] {
                    variable.typeClass = classType
                }
            }
            
            for method in classInstance.allMethods {
                for argument in method.parameters {
                    if let classType = self.classDictionary[argument.cleanedType] {
                        argument.typeClass = classType
                    }
                }
            }
        }
        
        return floatingExtensions
    }
    
    func addInfoFromDocResult(classInstance: Class, result: [String: SourceKitRepresentable]) {
        if let children = result["key.substructure"] as? [[String: SourceKitRepresentable]] {
            for substructure in children {
                //print("substructure")
                //let kind = substructure["key.kind"] as? String
                if let name = substructure["key.name"] as? String {
                    //print("name: \(name)")
                    if name == classInstance.name {
                        if let entities = substructure["key.substructure"] as? [[String: SourceKitRepresentable]] {
                            outerloop: for entity in entities {
                                if let entityName = entity["key.name"] as? String,
                                    let kind = entity["key.kind"] as? String,
                                    let entityType = entity["key.typename"] as? String {
                                    //print("entityName: \(entityName)")
                                    //print("entityType: \(entityType)")
                                    
                                    let variableKinds = [ClassVariable.kittenKey,
                                        LocalVariable.kittenKey,
                                        StaticVariable.kittenKey,
                                        InstanceVariable.kittenKey,
                                        GlobalVariable.kittenKey]
                                    
                                    let methodKinds = [ClassFunction.kittenKey,
                                                       StaticFunction.kittenKey,
                                                       InstanceFunction.kittenKey]
                                    
                                    if variableKinds.contains(kind) {
                                        for variable in classInstance.allVariables {
                                            if variable.name == entityName && variable.type == "" {
                                                variable.type = entityType
                                                //print("found variable")
                                                continue outerloop
                                            }
                                        }
                                    }
                                    
                                    if methodKinds.contains(kind) {
                                        for method in classInstance.allMethods {
                                            if method.name == entityName && method.returnType == "" {
                                                method.returnType = entityType
                                                //print("found variable")
                                                continue outerloop
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func findReferences(app: App) {
        //TODO: do this also for structs and class and static methods
        //print("findReferences for \(app.name)")
        //print("Allclasses: \(app.classes)")
        for classInstance in app.allClasses {
            //print("References for class: \(classInstance.name)")
            for instanceMethod in classInstance.allMethods {
                //print("References for method: \(instanceMethod.name)")
                for reference in instanceMethod.references {
                    if let method = self.allMethods[reference] {
                        instanceMethod.referencedMethods.append(method)
                        method.methodReferences.append(instanceMethod)
                        //print("Found method: \(method.name) - usr: \(reference)")
                    }
                    
                    if let variable = self.allVariables[reference] {
                        instanceMethod.referencedVariables.append(variable)
                        variable.methodReferences.append(instanceMethod)
                        //print("Found variable: \(variable.name) - usr: \(reference)")
                    }
                }
            }
            
            //Add parents and extendedInterfaces
            //print("Fiding references for parentUsrs: \(classInstance.parentUsrs)")
            //print("AllClasses: \(self.allClasses)")
            for usr in classInstance.parentUsrs {
                if let object = self.allClasses[usr] {
                    if let parentClass = object as? ClassInstance {
                        //print("class \(parentClass.name) is classInstance")
                        classInstance.inheritedClasses.append(parentClass)
                    } else if let parentProtocol = object as? Protocol {
                        //print("class \(parentProtocol.name) is protocol")
                        classInstance.extendedInterfaces.append(parentProtocol)
                    } else if let parentStruct = object as? Struct {
                        //print("class \(parentStruct.name) is struct")
                        classInstance.inheritedClasses.append(parentStruct)
                    }
                } else if usr.contains("c:objc(cs)") {
                    classInstance.parentName = usr.replacingOccurrences(of: "c:objc(cs)", with: "")
                }
            }
        }
    }
}

// Handle app size stuff
extension SourceFileIndexAnalysisController {
    func calculateSize(app: App) {
        var analysedFiles: [String] = []
        
        for classInstance in app.allClasses {
            if !analysedFiles.contains(classInstance.path) {
                do {
                    let attr = try FileManager.default.attributesOfItem(atPath: classInstance.path)
                    let fileSize = attr[FileAttributeKey.size] as! UInt64
                    app.size += Int(fileSize)
                    
                    analysedFiles.append(classInstance.path)
                } catch let error {
                    self.errorDesctiptions.append(error.localizedDescription)
                    print("Error: \(error.localizedDescription)")
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
    
    var startLine: Int?
    var endLine: Int?
    var dataString: String?
    
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
    
    var startLine: Int?
    var endLine: Int?
    var dataString: String?
    var isAbstract = false
    var accessModifier: String?
    
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
