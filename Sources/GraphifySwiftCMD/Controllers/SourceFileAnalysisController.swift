//
//  SourceFileAnalysisController.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 21/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

import Foundation
import SourceKittenFramework

class SourceFileAnalysisController {
    let dataSyncController = DataSyncController()
    
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
    
    var fileQueue: [URL] = []
    
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
    
    var handledClasses: Set<String> = []
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
    
    func analyseFolder(at url: URL, appKey: String, finished: @escaping () -> Void) {
        self.finished = finished
        let appName = url.lastPathComponent
            
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
        
        
        self.addFilesToQueue(at: url)
        if self.fileQueue.count > 0 {
            self.analyseFiles() {
                self.analyseSpecialSuperClasses()
                self.analyseClassHierarchy()
                self.printApp()
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
    
    func printApp() {
        print("App: \(String(describing: self.app))")
        print("Classes:")
        for classInstance in self.app.classes {
            print("     Class: \(classInstance.name)")
            print("     InstanceMethods: ")
            for method in classInstance.instanceMethods {
                printMethod(method)
            }
            print("     ClassMethods: ")
            for method in classInstance.classMethods {
                printMethod(method)
            }
            print("     InstanceMethods: ")
            for method in classInstance.staticMethods {
                printMethod(method)
            }
        }
    }
    
    func printMethod(_ method: Function) {
        print("               Method: \(method.name)")
        print("                  Stats: inst: \(method.numberOfInstructions), compl: \(method.cyclomaticComplexity)")
        for argument in method.parameters {
            print("                      Argument: \(argument.name)")
        }
        
        for instruction in method.instructions {
            printInstruction(instruction)
        }
    }
    
    func printInstruction(_ instruction: Instruction) {
        print("                      Instruction: \(instruction.stringValue), kind: \(instruction.kind)")
        for subInstruction in instruction.instructions {
            printInstruction(subInstruction)
        }
    }
    
    
    func addFilesToQueue(at url: URL) {
        let resourceKeys : [URLResourceKey] = [
            .creationDateKey,
            .isDirectoryKey,
            .nameKey,
            .fileSizeKey
        ]
        
        let enumerator = FileManager.default.enumerator(
            at:                         url,
            includingPropertiesForKeys: resourceKeys,
            options:                    [.skipsHiddenFiles],
            errorHandler:               { (url, error) -> Bool in
                print("directoryEnumerator error at \(url): ", error)
                return true
        })!
        
        //fileQueue
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
                
                if let name = resourceValues.name {
                    if name.hasSuffix(self.fileSuffix) {
                        let size = resourceValues.fileSize!
                        self.app.size = self.app.size + size
                        
                        fileQueue.append(fileURL)
                    }
                }
            } catch {
                //TODO: do something if an error is thrown!
                print("Error")
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
    
    func analyseClassHierarchy() {
        let classNames = self.app.classes.map() { classInstance in
            return classInstance.name
        }
        
        let structNames = self.app.structures.map() { structInstance in
            return structInstance.name
        }
        
        let protocolNames = self.app.protocols.map() { protocolInstance in
            return protocolInstance.name
        }
        
        for classInstance in self.app.classes {
            print("class: \(classInstance.name), inheritedTypes: \(classInstance.inheritedTypes)")
            for type in classInstance.inheritedTypes {
                if classNames.contains(type) {
                    for secondClass in self.app.classes {
                        if secondClass.name == type {
                            classInstance.parent = secondClass
                            classInstance.parentName = type
                            
                            classInstance.isViewController = secondClass.isViewController
                            continue
                        }
                    }
                }
                
                if protocolNames.contains(type) {
                    for protocolInstance in self.app.protocols {
                        if protocolInstance.name == type {
                            classInstance.extendedInterfaces.append(protocolInstance)
                            continue
                        }
                    }
                }
            }
        }
        
        for structInstance in self.app.structures {
            for type in structInstance.inheritedTypes {
                if structNames.contains(type) {
                    for secondStruct in self.app.structures {
                        if secondStruct.name == type {
                            structInstance.parent = secondStruct
                            structInstance.parentName = type
                            continue
                        }
                    }
                }
                
                if protocolNames.contains(type) {
                    for protocolInstance in self.app.protocols {
                        if protocolInstance.name == type {
                            structInstance.extendedInterfaces.append(protocolInstance)
                            continue
                        }
                    }
                }
            }
        }
    }
    
    func analyseFile(at url: URL, completitionHandler: @escaping () -> Void) {
        //print("analyseFile")
        
        if let file = File(path: url.path) {
            do {
                let structure = try Structure(file: file)
                let res = structure.dictionary as [String: AnyObject]
                self.extractClassStructureNew(from: res)
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
    
    func extractClassStructureNew(from dictionary: [String : AnyObject]) {
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
        
        var arguments: [Argument] = []
        var instructions: [Instruction] = []
        print("     Method: \(name)")
        
        //TODO!
        let fullName = "\(name)#\(className)"
        let function = Function(name: name, fullName: fullName, appKey: self.app.appKey, modifier: modifier, returnType: returnType)
        
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
}
