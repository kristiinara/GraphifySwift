//
//  SourceFileAnalysisController.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 21/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SourceKit

class SourceFileAnalysisController {
    let dataSyncController = DataSyncController()
    var updatedController: UpdatedSourceFileAnalysisController!
    
    var variableReferences : [String: Variable] = [:]
    var methodReferences : [String: Function] = [:]
    
    let fileSuffix = ".swift"
    
    let supportedKinds = ["source.lang.swift.decl.class", "source.lang.swift.decl.var.instance", "source.lang.swift.decl.function.method.instance",
        "source.lang.swift.decl.struct"]
    
    let substructureKey = "key.substructure"
    let nameKey = "key.name"
    let kindKey = "key.kind"
    let modifierKey = "key.accessibility"
    let ingeritedKey = "key.inheritedtypes"
    let typeKey = "key.typename"
    
    //var instructionsCount = 0
    
    var finished : (() -> Void)?
    var printOutput : Bool = false
    var classSizes : [Int] = []
    
    var fileQueue: [URL] = []
    var filePaths: [String] = []
    
    let supportedFirstLevel = [
        ClassInstance.kittenKey,
        Protocol.kittenKey,
        Struct.kittenKey
    ]
    
    let supportedSecondLevel = [
        ClassVariable.kittenKey,
        InstanceVariable.kittenKey,
        StaticVariable.kittenKey,
        InstanceFunction.kittenKey,
        ClassFunction.kittenKey,
        StaticFunction.kittenKey
    ]
    
    let supportedInMethod = [
        Argument.kittenKey,
        LocalVariable.kittenKey,
        MethodCall.kittenKey,
        For.kittenKey,
        ForEach.kittenKey,
        While.kittenKey,
        RepeatWhile.kittenKey,
        If.kittenKey,
        Guard.kittenKey,
        Switch.kittenKey,
        Case.kittenKey
    ]
    
    var handledClasses: [String:Class] = [:]
    var classes: [Kind] = []
    var notHandledInstances: [String] = []
    var app : App!
    
//    init(appKey: String, targetSdk: String, dateDownload: String, package: String, versionCode: String, verionName: String, developer: String, sdk: String, category: String) {
//        self.targetSdk = targetSdk
//        self.dateDownload = dateDownload
//        self.package = package
//        self.versionCode = versionCode
//        self.versionName = versionName
//        self.appKey = appKey
//        self.developer = developer
//        self.sdk = sdk
//        self.category = categroy
//    }
    
    func analyseFolder(at url: URL, appKey: String, printOutput: Bool, finished: @escaping () -> Void) {
        self.finished = finished
        self.printOutput = printOutput
        let appName = url.lastPathComponent
        
        let sdk = "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk"
        //var dependencyURL = url.appendingPathComponent("Carthage", isDirectory: true)
        
        var dependencyURL = url
        print("original url: \(dependencyURL)")
        //dependencyURL.deleteLastPathComponent()
        //print("removing last component: \(dependencyURL)")
        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)
            
        //TODO: get this data from user, currently using mock data
        self.app = App(
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
        
        
        self.fileQueue = FolderUtility.getFileQueue(for: url, ignore: "Carthage")
        self.filePaths = self.fileQueue.map() { url in return url.path }
        
        self.updatedController = UpdatedSourceFileAnalysisController(homeURL: url, dependencyURL: dependencyURL, sdk: sdk)
        
        self.updatedController.allPaths = self.filePaths
        
        //self.addFilesToQueue(at: url)
        self.app.size = self.classSizes.reduce(0) { (result, size) in
            return result + size
        }
        
        if self.fileQueue.count > 0 {
            self.analyseFiles() {
                self.analyseSpecialSuperClasses()
                self.analyseClassHierarchy()
                
//                self.addCursorInfoTo(app: self.app)
//
//                let files = self.filePaths.reduce("") { res, path in
//                    return res + " " + path
//                }
//                print(files)
                
                self.addUsrAndReferences()
                self.analyseUses()
                //print("\(self.methodReferences)")
                //print("\(self.variableReferences)")
                print("Printing app")
                ObjectPrinter.printApp(self.app)
                //print(self.updatedController.rawAnalysedData)
                //print("\(self.filePaths)")
                print("Starting data sync")
                self.dataSyncController.finished = finished
                self.dataSyncController.sync(app: self.app)
            }
        } else {
            print("Error: No files found!")
            //self.updateData()
            if let finished = self.finished {
                finished()
            }
        }
    }
    
    func analyseFiles(completition: @escaping () -> Void) {
        if fileQueue.count > 0 {
            let file = self.fileQueue.remove(at: 0)
            analyseFile(at: file) {
                self.analyseFiles(completition: completition)
//                if let update = self.updateData {
//                    update()
//                    self.analyseFiles(completition: completition)
//                }
            }
        } else {
            completition()
        }
    }
    
    func analyseSpecialSuperClasses() {
        let viewControllerClasses = ["NSViewController", "UIViewController", "UITableViewController", "UICollectionViewController"]
        //let viewControllerNameMightInclude = "ViewController"
        
        for classInstance in self.app.classes {
            for kind in classInstance.inheritedTypes {
                if viewControllerClasses.contains(kind) {
                    classInstance.isViewController = true
                }
            }
        }
    }
    
    func addUsrAndReferences() {
        for classInstance in self.app.classes {
            classInstance.usr = self.updatedController.findUsrOf(name: classInstance.name, kind: ClassInstance.kittenKey, path: classInstance.path)
            addUsrToMethodsAndVariablesOfClass(classInstance)
        }
        
        for structInstance in self.app.structures {
            structInstance.usr = self.updatedController.findUsrOf(name: structInstance.name, kind: Struct.kittenKey, path: structInstance.path)
            addUsrToMethodsAndVariablesOfClass(structInstance)
        }
        
        for protocolInstance in self.app.protocols {
            protocolInstance.usr = self.updatedController.findUsrOf(name: protocolInstance.name, kind: Protocol.kittenKey, path: protocolInstance.path)
            addUsrToMethodsAndVariablesOfClass(protocolInstance)
        }
    }
    
    func addUsrToMethodsAndVariablesOfClass(_ classInstance: Class) {
        for classMethod in classInstance.classMethods {
            let usr = self.updatedController.findUsrOf(name: classMethod.name, kind: ClassFunction.kittenKey, path: classInstance.path)
            classMethod.usr = usr
            if let usr = usr {
                self.methodReferences[usr] = classMethod
            }
        }
        
        for instanceMethod in classInstance.instanceMethods {
            let usr = self.updatedController.findUsrOf(name: instanceMethod.name, kind: InstanceFunction.kittenKey, path: classInstance.path)
            instanceMethod.usr = usr
            if let usr = usr {
                self.methodReferences[usr] = instanceMethod
            }
        }
        
        for staticMethod in classInstance.staticMethods {
            let usr = self.updatedController.findUsrOf(name: staticMethod.name, kind: StaticFunction.kittenKey, path: classInstance.path)
            staticMethod.usr = usr
            if let usr = usr {
                self.methodReferences[usr] = staticMethod
            }
        }
        
        for classVariable in classInstance.classVariables {
            let usr = self.updatedController.findUsrOf(name: classVariable.name, kind: ClassVariable.kittenKey, path: classInstance.path)
            classVariable.usr = usr
            if let usr = usr {
                self.variableReferences[usr] = classVariable
            }
        }
        
        for instanceVariable in classInstance.instanceVariables {
            let usr = self.updatedController.findUsrOf(name: instanceVariable.name, kind: InstanceVariable.kittenKey, path: classInstance.path)
            instanceVariable.usr = usr
            if let usr = usr {
                self.variableReferences[usr] = instanceVariable
            }
        }
        
        for staticVariable in classInstance.staticVariables {
            let usr = self.updatedController.findUsrOf(name: staticVariable.name, kind: StaticVariable.kittenKey, path: classInstance.path)
            staticVariable.usr = usr
            if let usr = usr {
                self.variableReferences[usr] = staticVariable
            }
        }
    }
    
    func analyseUses() {
//        var allClasses: [Class] = []
//        allClasses.append(contentsOf: self.app.classes)
//        allClasses.append(contentsOf: self.app.protocols)
//        allClasses.append(contentsOf: self.app.structures)
//        
//        for classInstance in allClasses {
//            var allMethods: [Function] = []
//            allMethods.append(contentsOf:classInstance.classMethods)
//            allMethods.append(contentsOf:classInstance.staticMethods)
//            allMethods.append(contentsOf:classInstance.instanceMethods)
//            
//            for method in allMethods {
//                if let usr = method.usr {
//                    let uses = self.updatedController.findUsesOfUsr(usr: usr)
////                    print("method: \(method.name)")
////                    print("uses: \(uses)")
//                    
//                    for key in uses.keys {
//                        if let classInstance = self.handledClasses[key], let lines = uses[key] {
//                            for line in lines {
//                                if let usedInMethod = classInstance.findMethodWithLineNumber(line.line) {
//                                    //print("usedIn: \(usedInMethod.name)")
//                                    usedInMethod.methodReferences.append(method)
//                                    method.numberOfCallers += 1
//                                }
//                            }
//                        }
//                    }
//                }
//                
////                self.findAllUsesOfMethod(method: method, path: classInstance.path)
////                if let uses = method.uses {
////                    print("method: \(method.name) - uses: \(uses)")
////                    for use in uses {
////                        print("use: \(use)")
////                        if let usedInMethod = classInstance.findMethodWithLineNumber(use) {
////                            print("usedIn: \(usedInMethod.name)")
////                            usedInMethod.methodReferences.append(method)
////                            method.numberOfCallers += 1
////                        }
////                    }
////                }
//            }
//            
//            var allVariables: [Variable] = []
//            allVariables.append(contentsOf:classInstance.classVariables)
//            allVariables.append(contentsOf:classInstance.staticVariables)
//            allVariables.append(contentsOf:classInstance.instanceVariables)
//            
//            for variable in allVariables {
////                self.findAllUsesOfVariable(variable: variable, path: classInstance.path)
////                if let uses = variable.uses {
////                    print("variable: \(variable.name) - uses: \(uses)")
////                    for use in uses {
////                        print("use: \(use)")
////                        if let usedInMethod = classInstance.findMethodWithLineNumber(use) {
////                            print("usedIn: \(usedInMethod.name)")
////                            usedInMethod.variableReferences.append(variable)
////                        }
////                    }
////                }
//                if let usr = variable.usr {
//                    let uses = self.updatedController.findUsesOfUsr(usr: usr)
////                    print("variable: \(variable.name)")
////                    print("uses: \(uses)")
//                    
//                    for key in uses.keys {
//                        if let classInstance = self.handledClasses[key], let lines = uses[key] {
//                            for line in lines {
//                                if let usedInMethod = classInstance.findMethodWithLineNumber(line.line) {
//                                    //print("usedIn: \(usedInMethod.name)")
//                                    usedInMethod.variableReferences.append(variable)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
        
//        for classInstance in allClasses {
//            for method in classInstance.classMethods {
//                findAndAddUses(method: method, kittenKind: ClassFunction.kittenKey, path: classInstance.path)
//            }
//
//            for method in classInstance.instanceMethods {
//                findAndAddUses(method: method, kittenKind: InstanceFunction.kittenKey, path: classInstance.path)
//            }
//
//            for method in classInstance.staticMethods {
//                findAndAddUses(method: method, kittenKind: StaticFunction.kittenKey, path: classInstance.path)
//            }
//
//            for variable in classInstance.instanceVariables {
//                 findAndAddUsesForVariable(variable: variable, kittenKind: StaticFunction.kittenKey, path: classInstance.path)
//            }
//        }
    }
    
//    func findAndAddUses(method: Function, kittenKind: String, path: String) {
//        let usrs = updatedController.allUsrsForObject(objectName: method.name, objectKind: kittenKind, path: path)
//
//        print("usrs for \(method.name): \(usrs)")
//        for usr in usrs {
//            if usr == method.usr { continue }
//
//            if let referencedMethod = self.methodReferences[usr] {
//                method.methodReferences.append(referencedMethod)
//            } else if let variable = self.variableReferences[usr] {
//                method.variableReferences.append(variable)
//            } else {
//                print("unknown usr: \(usr)")
//            }
//        }
//    }
    
//    func findAndAddUsesForVariable(variable: Variable, kittenKind: String, path: String) {
//        let usrs = updatedController.allUsrsForObject(objectName: variable.name, objectKind: kittenKind, path: path)
//        
//        for usr in usrs {
//            if usr == variable.usr { continue }
//            
//            if let method = self.methodReferences[usr] {
//                variable.methodReferences.append(method)
//            } else if let variable = self.variableReferences[usr] {
//                variable.variableReferences.append(variable)
//            } else {
//                print("unknown usr: \(usr)")
//            }
//        }
//    }
    
//    func findAllUsesOfMethod(method: Function, path: String) {
//        if let usr = method.usr {
//            let uses = updatedController.usesOfUSR(usr: usr, path: path)
//            method.uses = uses
//        }
//    }
//
//    func findAllUsesOfVariable(variable: Variable, path: String) {
//        if let usr = variable.usr {
//            let uses = updatedController.usesOfUSR(usr: usr, path: path)
//            variable.uses = uses
//        }
//    }
    
    func analyseClassHierarchy() {
//        let classNames = self.app.classes.map() { classInstance in
//            return classInstance.name
//        }
//        
//        let structNames = self.app.structures.map() { structInstance in
//            return structInstance.name
//        }
//        
//        let protocolNames = self.app.protocols.map() { protocolInstance in
//            return protocolInstance.name
//        }
//        
//        for classInstance in self.app.classes {
//            //print("class: \(classInstance.name), inheritedTypes: \(classInstance.inheritedTypes)")
//           // print("usr: \(classInstance.usr)")
//            for type in classInstance.inheritedTypes {
//                if classNames.contains(type) {
//                    for secondClass in self.app.classes {
//                        if secondClass.name == type {
//                            classInstance.parent = secondClass
//                            classInstance.parentName = type
//                            
//                            classInstance.isViewController = secondClass.isViewController
//                            continue
//                        }
//                    }
//                }
//                
//                if protocolNames.contains(type) {
//                    for protocolInstance in self.app.protocols {
//                        if protocolInstance.name == type {
//                            classInstance.extendedInterfaces.append(protocolInstance)
//                            continue
//                        }
//                    }
//                }
//            }
//        }
//        
//        for structInstance in self.app.structures {
//            for type in structInstance.inheritedTypes {
//                if structNames.contains(type) {
//                    for secondStruct in self.app.structures {
//                        if secondStruct.name == type {
//                            //structInstance.parent = secondStruct
//                            structInstance.parentName = type
//                            continue
//                        }
//                    }
//                }
//                
//                if protocolNames.contains(type) {
//                    for protocolInstance in self.app.protocols {
//                        if protocolInstance.name == type {
//                            structInstance.extendedInterfaces.append(protocolInstance)
//                            continue
//                        }
//                    }
//                }
//            }
//        }
    }
    
    func analyseFile(at url: URL, completitionHandler: @escaping () -> Void) {
        //print("analyseFile")
        
        if let file = File(path: url.path) {
            do {
                let structure = try Structure(file: file)
               // let request = SourceKittenFramework.Request.syntaxTree(file: file, byteTree: false)
//                let request = SourceKittenFramework.Request.cursorInfo(file: url.path, offset: 1960, arguments: [url.path])
//
//                let response = try request.send()
                //print("file: \(url)")
                //print("\(response)")
                
                let resultString = "\(structure)"
                if self.printOutput {
                    ResultToFileHandler.write(resultString: resultString, toFile: url.path)
                }
                
                let res = structure.dictionary as [String: AnyObject]
                self.extractClassStructureNew(from: res, path: url.path)
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
    
    func extractClassStructureNew(from dictionary: [String : AnyObject], path: String) {
        //print("All data:")
        //print(dictionary)
        
        let models = dictionary[self.substructureKey] as! [[String : AnyObject]]
        
        for model in models {
            //print("model: \(model)")
            
            let kind = model[self.kindKey] as! String
            
            if !self.supportedFirstLevel.contains(kind) {
                self.notHandledInstances.append(kind)
                continue
            } else {
                let classInstance = self.handleFirstLevelModel(model)
                classInstance.path = path
                self.handledClasses[path] = classInstance
                
                if let file = File(path: classInstance.path) {
                    classInstance.fileContents = file.contents
                }
                classInstance.calculateLines()
                
                if let classInstance = classInstance as? ClassInstance {
                    self.app.classes.append(classInstance)
                } else if let structInstance = classInstance as? Struct {
                    self.app.structures.append(structInstance)
                } else if let protocolInstance = classInstance as? Protocol {
                    self.app.protocols.append(protocolInstance)
                }
            }
        }
    }
    
    func handleFirstLevelModel(_ model: [String : AnyObject]) -> Class {
        let name = model[self.nameKey] as! String
        let kind = model[self.kindKey] as! String
        let modifier = model[self.modifierKey] as? String ?? "No modifier"
        let inheritedDict = model[self.ingeritedKey] as? [[String: AnyObject]] ?? []
        var inheritedTypes: [String] = []
        
        for inherited in inheritedDict {
            let inheritedName = inherited[self.nameKey] as! String
            inheritedTypes.append(inheritedName)
        }
        
        var instanceVariables: [Variable] = []
        var classVariables: [Variable] = []
        var staticVariables: [Variable] = []
        
        var instanceMethods: [Function] = []
        var classMethods: [Function] = []
        var staticMethods: [Function] = []
        
        let substructures = model[self.substructureKey] as? [[String: AnyObject]] ?? []
        for substructure in substructures {
            let subKind = substructure[self.kindKey] as! String
            
            //For inner classes:
            if !self.supportedSecondLevel.contains(subKind) {
                if self.supportedFirstLevel.contains(subKind) {
                    //Handling inner classes
                    let classInstance = self.handleFirstLevelModel(substructure)
                    classInstance.isInnerClass = true
                    
                    if let classInstance = classInstance as? ClassInstance {
                        self.app.classes.append(classInstance)
                    } else if let structInstance = classInstance as? Struct {
                        self.app.structures.append(structInstance)
                    } else if let protocolInstance = classInstance as? Protocol {
                        self.app.protocols.append(protocolInstance)
                    }
                } else {
                    self.notHandledInstances.append(subKind)
                }
                continue
            } else {
                // handle instance variables
                if subKind == InstanceVariable.kittenKey {
                    instanceVariables.append(handleVariable(substructure))
                } else if subKind == ClassVariable.kittenKey {
                    classVariables.append(handleVariable(substructure))
                } else if subKind == StaticVariable.kittenKey {
                    staticVariables.append(handleVariable(substructure))
                }
                
                // handle methods
                if subKind == InstanceFunction.kittenKey {
                    instanceMethods.append(handleMethod(substructure, className: name))
                } else if subKind == ClassFunction.kittenKey {
                    classMethods.append(handleMethod(substructure, className: name))
                } else if subKind == StaticFunction.kittenKey {
                    staticMethods.append(handleMethod(substructure, className: name))
                }
            }
        }
        
        var classInstance: Class!
        switch kind {
        case ClassInstance.kittenKey:
            classInstance = ClassInstance(name: name, appKey: self.app.appKey, modifier: modifier)
        case Struct.kittenKey:
            classInstance = Struct(name: name, appKey: self.app.appKey, modifier: modifier)
        case Protocol.kittenKey:
            classInstance = Protocol(name: name, appKey: self.app.appKey, modifier: modifier)
        default:
            print("none of them")
        }
        //print("New class: \(classInstance!)")
        
        classInstance.classMethods = classMethods
        classInstance.staticMethods = staticMethods
        classInstance.instanceMethods = instanceMethods
        classInstance.classVariables = classVariables
        classInstance.staticVariables = staticVariables
        classInstance.instanceVariables = instanceVariables
        classInstance.inheritedTypes = inheritedTypes
        
        return classInstance
    }
    
    func handleMethod(_ structure: [String : AnyObject], className: String) -> Function {
        //let kind = model[self.nameKey]
        let name = structure[self.nameKey] as! String
        let modifier = structure[self.modifierKey] as! String
        let returnType = structure[self.typeKey] as? String ?? ""
        let characterOffset = structure["key.offset"] as? Int
        let length = structure["key.length"] as? Int
        
        var arguments: [Argument] = []
        var instructions: [Instruction] = []
        print("     Method: \(name)")
        
        //TODO!
        let fullName = "\(name)#\(className)"
        let function = Function(name: name, fullName: fullName, appKey: self.app.appKey, modifier: modifier, returnType: returnType)
        
        function.characterOffset = characterOffset
        function.length = length
        
        if let models = structure[self.substructureKey] as? [[String: AnyObject]] {
            for model in models {
                let kind = model[self.kindKey] as! String
                var argumentCount = 0
                
                switch kind {
                case Argument.kittenKey:
                    argumentCount += 1
                    let type = (model[self.typeKey] as? String) ?? "No type"
                    let name = (model[self.nameKey] as? String) ?? "No name"
                    let position = argumentCount
                    
                    let argument = Argument(name: name, type: type, position: position, appKey: self.app.appKey)
                    arguments.append(argument)
                default: instructions.append(handleInstruction(model))
                }
                
//                if !self.supportedInMethod.contains(kind) {
//                    self.notHandledInstances.append(kind)
//                } else {
//                    switch kind {
//                    case Argument.kittenKey:
//                        argumentCount += 1
//                        let type = (model[self.typeKey] as? String) ?? "No type"
//                        let name = (model[self.nameKey] as? String) ?? "No name"
//                        let position = argumentCount
//
//                        let argument = Argument(name: name, type: type, position: position, appKey: self.app.appKey)
//                        arguments.append(argument)
//                    default: instructions.append(handleInstruction(model))
//                    }
//                }
            }
        }
        function.instructions = instructions
        
        return function
    }
    
    func handleInstruction(_ structure: [String: AnyObject]) -> Instruction {
        let kind = structure[self.kindKey] as! String
        let name = (structure[self.nameKey] as? String) ?? ""
        let offset = structure["key.offset"] as? Int64
        var instruction = Instruction(stringValue: name, kind: kind)
        
        switch kind {
        case LocalVariable.kittenKey:
            let localVariable = LocalVariable(stringValue: name, kind: kind)
            localVariable.typeName = structure[self.typeKey] as? String
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
        default: self.notHandledInstances.append(kind)
        }
        
        instruction.offset = offset
        
        //let classType = type(of: instruction)
        
        //instructionsCount = instructionsCount + 1
        //print("             \(instructionsCount) - \(name), \(classType)")
        
        if let models = structure[self.substructureKey] as? [[String: AnyObject]] {
            for model in models {
                
                
                let subInstruction = self.handleInstruction(model)
                instruction.instructions.append(subInstruction)
            }
        }
        
        return instruction
    }
    
    func handleVariable(_ structure: [String : AnyObject]) -> Variable {
        //let kind = structure[self.nameKey]
        let name = structure[self.nameKey] as! String
        let type = structure[self.typeKey] as? String ?? "No name"
        let modifier = structure[self.modifierKey] as? String ?? ""
        //print("     Variable: \(name)")
        
        let variable = Variable(name: name, appKey: self.app.appKey, modifier: modifier, type: type, isStatic: false, isFinal: false)
        
        return variable
    }
    
    func addCursorInfoTo(app: App) {
        var allClasses: [Class] = []
        allClasses.append(contentsOf: app.classes)
        allClasses.append(contentsOf: app.structures)
        allClasses.append(contentsOf: app.protocols)
        
        for classInstance in allClasses {
            var allMethods: [Function] = []
            allMethods.append(contentsOf: classInstance.instanceMethods)
            allMethods.append(contentsOf: classInstance.classMethods)
            allMethods.append(contentsOf: classInstance.staticMethods)
            
            for method in allMethods {
                for instruction in method.instructions {
                    addCursorInfoTo(instruction: instruction, path: classInstance.path)
                }
            }
        }
    }
    
    func addCursorInfoTo(instruction: Instruction, path: String) {
        if let offset = instruction.offset {
            /*
             
             
             -sdk /Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk
 
            */
            //var arguments = ["-sdk /Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk", path]
            //arguments.append(contentsOf: self.filePaths)
            var arguments = [path, "-sdk", "/Applications/Xcode101.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk"]
            //arguments.append(contentsOf: self.filePaths)
            
            let request = Request.cursorInfo(file: path, offset: offset, arguments: arguments)
            do {
                let response = try request.send()
                print("\(instruction.stringValue) - \(response)")
            } catch {
                print("Failed cursorInfo request for: \(instruction.stringValue)")
            }
        }
        
        for subInstruction in instruction.instructions {
            addCursorInfoTo(instruction: subInstruction, path: path)
        }
    }
}
