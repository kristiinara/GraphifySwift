//
//  DataSyncController.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 25/04/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

//import Foundation

class DataSyncController {
    let databaseController = DatabaseController()
    var classes : [Class] = []
    var finished : (([String]) -> ())?
    var addingAdditionalStuff = false
    var addingDuplications = false
    
    func reset() {
        self.classes = []
        self.finished = nil
        self.addingAdditionalStuff = false
        self.addingDuplications = false
        self.databaseController.errorDescription = []
    }
    
    func newApp(_ app: App, completition: @escaping (App, Bool) -> Void) {
        databaseController.runQueryReturnId(transaction: app.createQuery) { id in
            print("Added new app")
            if let id = id {
                app.id = id
                
                completition(app, true)
            } else {
                completition(app, false)
            }
        }
    }
    
    func newModule(_ newModule: Module, to app: App, completition: @escaping (Module, Bool) -> Void) {
        var toAdd = 1
        
        self.databaseController.runQueryReturnId(transaction: newModule.createQuery) { [weak self] id in
            if let self = self {
                guard let id = id else {
                    print("Error: could not add module \(newModule.name)")
                    completition(newModule, false)
                    return
                }
                
                newModule.id = id
                
                self.databaseController.runQueryReturnId(transaction: app.ownsModuleQuery(newModule)) { relId in
                    print("AppOwnsModule relationship added")
                }
                
                toAdd -= 1
                toAdd += newModule.allClasses.count
                print("classes to be added \(newModule.allClasses.map() {module in module.name})")
                
                for classInstance in newModule.allClasses {
                    self.newClass(classInstance, to: newModule) { (newClass, success) in
                        print("NewClass finished \(classInstance.name)")
                        toAdd -= 1
                        print("toAdd \(toAdd)")
                        
                        if toAdd == 0 {
                            completition(newModule, true)
                            return
                        }
                    }
                }
                
                if toAdd == 0 {
                    completition(newModule, true)
                    return
                }
            } else {
                completition(newModule, false)
            }
        }
    }

    func newClass(_ newClass: Class, to module: Module, completition: @escaping (Class, Bool) -> Void) {
        print("addClass: \(newClass.description)")
        print("+")
        var toAdd = 1
        
        self.databaseController.runQueryReturnId(transaction: newClass.createQuery) { [weak self] id in
            guard let self = self else {
                completition(newClass, false)
                return
            }
            
            guard let id = id else {
                print("Error: could not add class \(newClass.name)")
                completition(newClass, false)
                return
            }
            
            toAdd -= 1
            toAdd += newClass.allMethods.count
            toAdd += newClass.allVariables.count
            
            print("adding id to class")
            newClass.id = id
            
            self.databaseController.runQueryReturnId(transaction: module.ownsClassQuery(newClass)) { relId in
                print("Added ModuleOwnsClass \(String(describing: relId))")
            }
            
            
            //self.addParent(newClass)
            
            //print("Added class: \(newClass.name), id: \(id)")
            for method in newClass.allMethods {
                self.databaseController.runQueryReturnId(transaction: method.createQuery) { methodId in
                    method.id = methodId
                    
                    self.databaseController.runQueryReturnId(transaction: newClass.ownsMethodQuery(method)) { relId in
                        print("Added ClassownsMethodQuery \(String(describing: relId))")
                    }
                    
                    toAdd += method.parameters.count
                    for argument in method.parameters {
                        self.databaseController.runQueryReturnId(transaction: argument.createQuery) { argumentId in
                            argument.id = argumentId
                            print("Added argumnet \(argument.name)")
                            print("query: \(method.ownsArgumentQuery(argument))")
                            
                            self.databaseController.runQueryReturnId(transaction: method.ownsArgumentQuery(argument)) { relId2 in
                                print("Added MethodOwnsArgumentQuery \(String(describing: relId2))")
                                
                                toAdd -= 1
                                if toAdd == 0 {
                                    print("newClass \(newClass.name) completition")
                                    completition(newClass, true)
                                    return
                                }
                            }
                        }
                    }
                    
                    toAdd -= 1
                    
                    print("class + method toAdd \(toAdd)")
                    if toAdd == 0 {
                        print("newClass \(newClass.name) completition")
                        completition(newClass, true)
                        return
                    }
                 }
            }
            
            for variable in newClass.allVariables {
                self.databaseController.runQueryReturnId(transaction: variable.createQuery) { variableId in
                    variable.id = variableId
                    
                    self.databaseController.runQueryReturnId(transaction: newClass.ownsVariableQuery(variable)) { relId in
                        print("Added ClassOwnsVariableQuery \(String(describing: relId))")
                    }
                    
                    toAdd -= 1
                    
                    print("class + variable toAdd \(toAdd)")
                    if toAdd == 0 {
                        print("newClass \(newClass.name) completition")
                        completition(newClass, true)
                        return
                    }
                }
            }
            
            if toAdd == 0 {
                completition(newClass, true)
                return
            }
            
           // completition(newClass, true)
        }
    }
    
    func doAdditionalStuffAfterAppAdded(app: App) {
        print("doAdditionalStuffAfterAppAdded")
        if addingAdditionalStuff == false {
            addingAdditionalStuff = true
            addMethodRelationships(app: app) { [weak self] in
                if let self = self {
                    if self.addingDuplications == false {
                        self.addingDuplications = true
                        self.addDuplications(app: app) {
                            if let finished = self.finished {
                                finished(self.databaseController.errorDescription)
                                self.finished = nil
                            }
                        }
                    }
                }
            }
        } else {
            print("do nothing")
        }
    }
    
    func addDuplications(app: App, completition: @escaping (()->())) {
        var queryCount = app.duplicates.count
        for duplicate in app.duplicates {
            self.databaseController.runQueryReturnId(transaction: duplicate.addDuplicationQuery) { relId in
                print("Added duplicate \(String(describing: relId))")
                queryCount -= 1
                
                if queryCount == 0 {
                    completition()
                    return
                }
            }
        }
        
        if queryCount == 0 {
            completition()
            return
        }
    }
    
    func addMethodRelationships(app: App, completition: @escaping (()->())) {
        print("addMethodRelationships")
        var allClasses: [Class] = []
        allClasses.append(contentsOf: app.classes)
        allClasses.append(contentsOf: app.structures)
        allClasses.append(contentsOf: app.protocols)
        
        var allMethods: [Function] = []
        var allVariables: [Variable] = []
        var queryCount = 0
        
        for classInstance in allClasses {
            let methods = classInstance.allMethods
            
            print("classname: \(classInstance.name)")
            print("static methods: \(classInstance.staticMethods)")
            print("static methods: \(classInstance.classMethods)")
            print("static methods: \(classInstance.instanceMethods)")
            
            allMethods.append(contentsOf: methods)
            
            for method in methods {
                queryCount += method.referencedMethods.count
                queryCount += method.referencedVariables.count
                queryCount += method.parameters.count
            }
            
            let variables = classInstance.allVariables
            allVariables.append(contentsOf: variables)
            
            queryCount += variables.count
        }
        
        print("allClasses: \(allClasses)")
        print("allmethods: \(allMethods)")
        print("Query count: \(queryCount)")
        
        for method in allMethods {
            for referencedMethod in method.referencedMethods {
                print("ReferencedMethod: \(method.callsQuery(referencedMethod))")
                self.databaseController.runQueryReturnId(transaction: method.callsQuery(referencedMethod)) { relId in
                    print("Added MethodCallsMethodQuery \(String(describing: relId))")
                    queryCount -= 1
                    if queryCount == 0 {
//                        if let finished = self.finished {
//                            finished()
//                            self.finished = nil
//                        }
                        completition()
                        return
                    }
                }
            }
            
            for referencedVariable in method.referencedVariables {
                self.databaseController.runQueryReturnId(transaction: method.usesQuery(referencedVariable)) { relId in
                    print("Added MethodUsesVariableQuery \(String(describing: relId))")
                    queryCount -= 1
                    if queryCount == 0 {
//                        if let finished = self.finished {
//                            finished()
//                            self.finished = nil
//                        }
                        completition()
                        return
                    }
                }
            }
        }
        
        for variable in allVariables {
            print("Run query variable is of type \(variable.cleanedType) - \(variable.typeClass?.name)")
            self.databaseController.runQueryReturnId(transaction: variable.isTypeQuery) { relId in
                print("Added VariableIsOfTypeQuery \(String(describing: relId))")
                queryCount -= 1
                if queryCount == 0 {
//                    if let finished = self.finished {
//                        finished()
//                        self.finished = nil
//                    }
                    completition()
                    return
                }
            }
        }
        
        for method in allMethods {
            for argument in method.parameters {
                self.databaseController.runQueryReturnId(transaction: argument.isTypeQuery) { relId in
                    print("Added VariableIsOfTypeQuery \(String(describing: relId))")
                    queryCount -= 1
                    if queryCount == 0 {completition()
                        return
                    }
                }
            }
        }
        
        if queryCount == 0 {
//            if let finished = self.finished {
//                finished()
//                self.finished = nil
//            }
            completition()
            return
        }
    }
    
//    func nextClassFor(app: App) {
//        print("nextClassFor")
//        if self.classes.count > 0 {
//            let classInstance = self.classes.remove(at: 0)
//            print("Next class: \(classInstance.name)")
//            self.newClass(classInstance, to: app) { (newClass, success) in
//                print("\(newClass) added \(success)")
//
//                var toAdd = 0
//
//                //Add parents
//                if self.classes.count == 0 {
//                    for classInstance in app.classes {
//                        toAdd = toAdd + 1
//                        self.addParent(classInstance)  {
//                            toAdd = toAdd - 1
//                            print("toAdd classes: \(toAdd)")
//                            if(toAdd == 0) {
//                                self.doAdditionalStuffAfterAppAdded(app: app)
//                            }
//                        }
//                    }
//
//                    for structInstance in app.structures {
//                        toAdd = toAdd + 1
//                        self.addParent(structInstance) {
//                            toAdd = toAdd - 1
//                            print("toAdd: struct \(toAdd)")
//                            if(toAdd == 0) {
//                                self.doAdditionalStuffAfterAppAdded(app: app)
//                            }
//                        }
//                    }
//
//                    for protocolInstance in app.protocols {
//                        toAdd = toAdd + 1
//                        self.addParent(protocolInstance) {
//                            toAdd = toAdd - 1
//                            print("toAdd: protocol \(toAdd)")
//                            if(toAdd == 0) {
//                                self.doAdditionalStuffAfterAppAdded(app: app)
//                            }
//
//                        }
//                    }
//                } else {
//                    self.nextClassFor(app: app)
//                }
//            }
//        } else {
//            self.doAdditionalStuffAfterAppAdded(app: app)
//        }
//    }
    
    func sync(app: App) {
        print("Sync!")
//        self.classes.append(contentsOf: app.classes)
//        self.classes.append(contentsOf: app.structures)
//        self.classes.append(contentsOf: app.protocols)
        
        var toAdd = 1
        
        self.newApp(app) { [weak self] app, success in
            guard let self = self else {
                return
            }
            
            //print("Adding app: \(app.name), success? \(success)")
            //self.nextClassFor(app: app)
            
            if success {
                toAdd += app.modules.count
                toAdd -= 1
                
                
                for module in app.modules {
                    self.newModule(module, to: app) { newModule, success in
                        toAdd -= 1
                        
                        print("Module added \(module.name)")
                        print("toAdd: \(toAdd)")
                        
                        if toAdd == 0 {
                            self.addParents(app: app)
                        }
                    }
                }
            } else {
                if let finished = self.finished {
                    finished(self.databaseController.errorDescription)
                }
            }
        }
    }
    
    func addParents(app: App) {
        var toAdd = app.allClasses.count
        
        for classInstance in app.allClasses {
            self.addParent(classInstance) {
                toAdd -= 1
                
                if toAdd == 0 {
                    self.doAdditionalStuffAfterAppAdded(app: app)
                }
            }
        }
    }
    
    func addParent(_ classInstance: Class, completition: @escaping () -> Void) {
        var toAdd = 0
        
        for parent in classInstance.inheritedClasses {
            toAdd = toAdd + 1
            self.databaseController.runQueryReturnId(transaction: classInstance.extendsQuery(parent)) { relId in
                print("Added AppExtendsParent \(String(describing: relId))")
                toAdd = toAdd - 1
                //print("toAdd: \(toAdd)")
                if(toAdd == 0) {
                    completition()
                }
            }
        }
        
        for protocolInstance in classInstance.extendedInterfaces {
            toAdd = toAdd + 1
            self.databaseController.runQueryReturnId(transaction: classInstance.implementsQuery(protocolInstance)) { relId in
                print("Added AppImplements \(String(describing: relId))")
                toAdd = toAdd - 1
                if(toAdd == 0) {
                    //print("toAdd: \(toAdd)")
                    completition()
                }
            }
        }
        
        if(toAdd == 0) {
            completition()
        }
    }
}
