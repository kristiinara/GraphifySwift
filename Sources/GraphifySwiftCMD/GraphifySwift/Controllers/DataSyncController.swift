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
    
    func newApp(_ app: App, completition: @escaping (App, Bool) -> Void) {
        databaseController.runQueryReturnId(transaction: app.createQuery) { id in
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
        
        self.databaseController.runQueryReturnId(transaction: newClass.createQuery) { id in
            guard let id = id else {
                print("Error: could not add class \(newClass.name)")
                completition(newClass, false)
                return
            }
            newClass.id = id
            self.databaseController.runQueryReturnId(transaction: app.ownsClassQuery(newClass)) { relId in
                //print("Added AppOwnsClass \(String(describing: relId))")
            }
            
            //self.addParent(newClass)
            
            //print("Added class: \(newClass.name), id: \(id)")
            for method in newClass.instanceMethods {
                self.databaseController.runQueryReturnId(transaction: method.createQuery) { methodId in
                    method.id = methodId
                    
                    self.databaseController.runQueryReturnId(transaction: newClass.ownsMethodQuery(method)) { relId in
                        //print("Added ClassownsMethodQuery \(String(describing: relId))")
                    }
                }
            }
            
            for variable in newClass.instanceVariables {
                self.databaseController.runQueryReturnId(transaction: variable.createQuery) { variableId in
                    variable.id = variableId
                    
                    self.databaseController.runQueryReturnId(transaction: newClass.ownsVariableQuery(variable)) { relId in
                        //print("Added ClassOwnsVariableQuery \(String(describing: relId))")
                    }
                }
            }
            
            completition(newClass, true)
        }
    }
    
    func nextClassFor(app: App) {
        if self.classes.count > 0 {
            let classInstance = self.classes.remove(at: 0)
            self.newClass(classInstance, to: app) { (newClass, success) in
                //print("\(newClass) added \(success)")
                
                var toAdd = 0
                
                //Add parents
                if self.classes.count == 0 {
                    for classInstance in app.classes {
                        toAdd = toAdd + 1
                        self.addParent(classInstance)  {
                            toAdd = toAdd - 1
                            //print("toAdd classes: \(toAdd)")
                            if(toAdd == 0) {
                                if let finished = self.finished {
                                   finished()
                                    self.finished = nil
                                }
                            }
                        }
                    }
                    
                    for structInstance in app.structures {
                        toAdd = toAdd + 1
                        self.addParent(structInstance) {
                            toAdd = toAdd - 1
                            print("toAdd: struct \(toAdd)")
                            if(toAdd == 0) {
                                if let finished = self.finished {
                                    finished()
                                }
                            }
                        }
                    }
                    
                    for protocolInstance in app.protocols {
                        toAdd = toAdd + 1
                        self.addParent(protocolInstance) {
                            toAdd = toAdd - 1
                            print("toAdd: protocol \(toAdd)")
                            if(toAdd == 0) {
                                if let finished = self.finished {
                                    finished()
                                }
                            }
                            
                        }
                    }
                } else {
                    self.nextClassFor(app: app)
                }
            }
        } else {
            if let finished = self.finished {
                finished()
            }
        }
    }
    
    func sync(app: App) {
        //print("Sync!")
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
        
        if let parent = classInstance.parent {
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
