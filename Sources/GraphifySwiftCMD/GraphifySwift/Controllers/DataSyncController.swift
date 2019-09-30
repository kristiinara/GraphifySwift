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
    var finished : (() -> Void)?
    var addingAdditionalStuff = false
    
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

    func newClass(_ newClass: Class, to app: App, completition: @escaping (Class, Bool) -> Void) {
        print("addClass: \(newClass.description)")
        print("+")
        var toAdd = 1
        
        self.databaseController.runQueryReturnId(transaction: newClass.createQuery) { id in
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
            self.databaseController.runQueryReturnId(transaction: app.ownsClassQuery(newClass)) { relId in
                //print("Added AppOwnsClass \(String(describing: relId))")
            }
            
            //self.addParent(newClass)
            
            //print("Added class: \(newClass.name), id: \(id)")
            for method in newClass.allMethods {
                self.databaseController.runQueryReturnId(transaction: method.createQuery) { methodId in
                    method.id = methodId
                    
                    self.databaseController.runQueryReturnId(transaction: newClass.ownsMethodQuery(method)) { relId in
                        print("Added ClassownsMethodQuery \(String(describing: relId))")
                    }
                    
                    toAdd -= 1
                    if toAdd == 0 {
                        print("newClass \(newClass.name) completition")
                        completition(newClass, true)
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
                    if toAdd == 0 {
                        print("newClass \(newClass.name) completition")
                        completition(newClass, true)
                    }
                }
            }
           // completition(newClass, true)
        }
    }
    
    func doAdditionalStuffAfterAppAdded(app: App) {
        print("doAdditionalStuffAfterAppAdded")
        if addingAdditionalStuff == false {
            addingAdditionalStuff = true
            addMethodRelationships(app: app)
        } else {
            print("do nothing")
        }
    }
    
    func addMethodRelationships(app: App) {
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
                        if let finished = self.finished {
                            finished()
                            self.finished = nil
                        }
                    }
                }
            }
            
            for referencedVariable in method.referencedVariables {
                self.databaseController.runQueryReturnId(transaction: method.usesQuery(referencedVariable)) { relId in
                    print("Added MethodUsesVariableQuery \(String(describing: relId))")
                    queryCount -= 1
                    if queryCount == 0 {
                        if let finished = self.finished {
                            finished()
                            self.finished = nil
                        }
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
                    if let finished = self.finished {
                        finished()
                        self.finished = nil
                    }
                }
            }
        }
        
        if queryCount == 0 {
            if let finished = self.finished {
                finished()
                self.finished = nil
            }
        }
    }
    
    func nextClassFor(app: App) {
        print("nextClassFor")
        if self.classes.count > 0 {
            let classInstance = self.classes.remove(at: 0)
            print("Next class: \(classInstance.name)")
            self.newClass(classInstance, to: app) { (newClass, success) in
                print("\(newClass) added \(success)")
                
                var toAdd = 0
                
                //Add parents
                if self.classes.count == 0 {
                    for classInstance in app.classes {
                        toAdd = toAdd + 1
                        self.addParent(classInstance)  {
                            toAdd = toAdd - 1
                            print("toAdd classes: \(toAdd)")
                            if(toAdd == 0) {
                                self.doAdditionalStuffAfterAppAdded(app: app)
                            }
                        }
                    }
                    
                    for structInstance in app.structures {
                        toAdd = toAdd + 1
                        self.addParent(structInstance) {
                            toAdd = toAdd - 1
                            print("toAdd: struct \(toAdd)")
                            if(toAdd == 0) {
                                self.doAdditionalStuffAfterAppAdded(app: app)
                            }
                        }
                    }
                    
                    for protocolInstance in app.protocols {
                        toAdd = toAdd + 1
                        self.addParent(protocolInstance) {
                            toAdd = toAdd - 1
                            print("toAdd: protocol \(toAdd)")
                            if(toAdd == 0) {
                                self.doAdditionalStuffAfterAppAdded(app: app)
                            }
                            
                        }
                    }
                } else {
                    self.nextClassFor(app: app)
                }
            }
        } else {
            self.doAdditionalStuffAfterAppAdded(app: app)
        }
    }
    
    func sync(app: App) {
        print("Sync!")
        self.classes.append(contentsOf: app.classes)
        self.classes.append(contentsOf: app.structures)
        self.classes.append(contentsOf: app.protocols)
        
        self.newApp(app) { app, success in
            //print("Adding app: \(app.name), success? \(success)")
            self.nextClassFor(app: app)
        }
    }
    
    func addParent(_ classInstance: Class, completition: @escaping () -> Void) {
        var toAdd = 0
        
        for parent in classInstance.inheritedClasses {
            toAdd = toAdd + 1
            self.databaseController.runQueryReturnId(transaction: classInstance.extendsQuery(parent)) { relId in
                //print("Added AppExtendsParent \(String(describing: relId))")
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
                //print("Added AppImplements \(String(describing: relId))")
                toAdd = toAdd - 1
                if(toAdd == 0) {
                    //  print("toAdd: \(toAdd)")
                    completition()
                }
            }
        }
        
        if(toAdd == 0) {
            completition()
        }
    }
}
