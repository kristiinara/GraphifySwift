//
//  Class.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 21/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

import Foundation

class Class : Kind {
    weak var module: Module?
    var dataString: String = ""
    
    var id: Int?
    var path: String = ""
    var usr: String?
    var name: String
    var appKey: String = "Default"
    var modifier: String = "" // public, protected, private
    var parentName: String = ""
    //var parent: Class?
    var parentUsrs: [String] = []
    var fileContents = ""
    
    var extendedInterfaces: [Protocol] = []
    
    var instanceVariables: [Variable] = []
    var classVariables: [Variable] = []
    var staticVariables: [Variable] = []
    var instanceMethods: [Function] = []
    var classMethods: [Function] = []
    var staticMethods: [Function] = []
    var inheritedTypes: [String] = []
    
    var inheritedClasses: [Class] = []
    var comments: [Comment] = []
    
    var allMethods: [Function] {
        var methods: [Function] = []
        methods.append(contentsOf: self.classMethods)
        methods.append(contentsOf: self.staticMethods)
        methods.append(contentsOf: self.instanceMethods)
        
        return methods
    }
    
    var allVariables: [Variable] {
        var variables: [Variable] = []
        variables.append(contentsOf: self.classVariables)
        variables.append(contentsOf: self.staticVariables)
        variables.append(contentsOf: self.instanceVariables)
        
        return variables
    }
    
    var depthOfInheritance : Int { // Integer Depth of Inheritance, starting at 1 since classes are at least java.lang.Object. --> which is not true for swift!
        
        var depth = 0
        
        for parent in self.inheritedClasses {
            if let parent = parent as? ClassInstance { //TODO: should we only use classInstances, theoretically implemnting protocols is or is not ineritance?
                depth += 1
                depth += parent.depthOfInheritance
                
            }
        }
        
        // In case superclass is outside of application domain, make depth 1
        if depth == 0 && (self.parentUsrs.count - self.numberOfImplementedInterfaces) > 0 {
            return 1
        }
        
        return depth
    }
    
    var numberOfImplementedInterfaces : Int { // number of protocols implemented
        return self.inheritedTypes.count
    }
    
    var numberOfChildren = 0 // TODO: number of classes extending this class
    var classComplexity : Int { // sum of all methods complexity
        let allMethods = self.classMethods + self.instanceMethods
        return allMethods.reduce(0) { (result, method) in
            return result + method.cyclomaticComplexity
        }
    }
    
    //Set when calculateCouplingBetweenClasses is called in app
    var couplingBetweenObjectClasses = 0 // Type : Integer Also know as CBO. Defined by Chidamber & Kemerer. CBO represents the number of other classes a class is coupled to. This metrics is calculated from the callgraph and it counts the reference to methods, variables or types once for each class.
    
    var lackOfCohesionInMethods: Int {
        var methods = self.classMethods
        methods.append(contentsOf: self.instanceMethods)
        methods.append(contentsOf: self.staticMethods)

        let methodCount = methods.count
        var haveVariableInCommon = 0
        var noVariableInCommon = 0

        if methodCount >= 2 {
            for i in 0...(methodCount - 2) {
                for j in (i+1)...(methodCount - 1) {
                    let method = methods[i]
                    let otherMethod = methods[j]

                    if method.hasVariablesInCommon(otherMethod) {
                        haveVariableInCommon += 1
                    } else {
                        noVariableInCommon += 1
                    }
                }
            }
        }

        let lackOfCohesionInMethods = noVariableInCommon - haveVariableInCommon
        return lackOfCohesionInMethods > 0 ? lackOfCohesionInMethods : 0
    }
    
    var isAbstract: Bool = false // Android specific, cannot be abstract
    var isActivity: Bool {
        return self.isViewController
    } // is viewController
    var isViewController: Bool = false // if is viewController
    var isApplication: Bool = false  // is AppDelegate
    var isBroadcastReceiver: Bool = false// android specific
    var isContentProvider: Bool = false // android specific
    var isService: Bool = false // android specific
    var isFinal: Bool = false
    var isStatic: Bool = false
    var isInnerClass: Bool = false
    var isInterface: Bool = false // Seems that we don't need additional class for Protocol, but can just say that class is interface
    var isStruct: Bool = false

    init(name: String, appKey: String, modifier: String, module: Module) {
        self.name = name
        self.appKey = appKey
        self.modifier = modifier
        self.module = module
    }
    
    var instructionsCount: Int {
        var instructionsCount = 0
        for method in instanceMethods {
            instructionsCount = method.instructions.count
        }
        return instructionsCount
    }
    
    var numberOfMethods: Int {
        return self.instanceMethods.count + self.classMethods.count + self.staticMethods.count
    }
    
    var numberOfAttributes: Int {
        return self.instanceVariables.count + self.classVariables.count + self.staticVariables.count
    }
    
    var description: String {
        return """
        Class: \(name)
        instance variables: \(self.instanceVariables)
        instance methods: \(self.instanceMethods)
        class methods: \(self.classMethods)
        """
    }
    
    // Added variables:
    //TODO: add instrutions from variables as well
    var numberOfInstructions: Int {
        var methodInstructions = self.allMethods.reduce(0) { res, method in
            return res + method.numberOfInstructions
        }
        return methodInstructions + self.allVariables.count
    }
    
    var numberOfComments: Int {
        return self.comments.count
    }
    
    func calculateLines() {
        var allMethods: [Function] = []
        allMethods.append(contentsOf: self.classMethods)
        allMethods.append(contentsOf: self.staticMethods)
        allMethods.append(contentsOf: self.instanceMethods)
        
        let nsContent = NSString(string: self.fileContents)
        
        for method in allMethods {
            if let offset = method.characterOffset {
                let res = nsContent.lineAndCharacter(forCharacterOffset: offset)
                method.lineNumber = res?.line
                
                if let length = method.length {
                    let res = nsContent.lineAndCharacter(forCharacterOffset: offset + length)
                    method.endLineNumber = res?.line
                }
            }
        }
    }
    
    func findMethodWithLineNumber(_ line: Int) -> Function? {
        var allMethods: [Function] = []
        allMethods.append(contentsOf: self.classMethods)
        allMethods.append(contentsOf: self.staticMethods)
        allMethods.append(contentsOf: self.instanceMethods)
        
        for method in allMethods {
            if let isInMethod = method.lineInFunction(line) {
                if isInMethod == true {
                    return method
                }
            } else {
                print("\(method.name) without lineNumber")
            }
        }
        
        return nil
    }
    
    func setReverseRelationshipsToVariablesAndMethods() {
        for variable in self.allVariables {
            variable.classInstance = self
        }
        
        for method in self.allMethods {
            method.classInstance = self
        }
    }
}

extension Class: Node4jInsertable {
    var nodeName: String {
        return "Class"
    }
    
    var properties: String {
        var dataString = self.dataString.replacingOccurrences(of: "\"", with: "'")
        dataString = dataString.replacingOccurrences(of: "\\", with: "\\\\")
        
        var optionalProperties = ""
        if let usr = self.usr {
            optionalProperties = ", usr:'\(usr)'"
        }
        
        return """
        {
        name:'\(self.name)',
        app_key:'\(self.appKey)',
        modifier:'\(self.modifier)',
        parent_name:'\(self.parentName)',
        number_of_methods:\(self.numberOfMethods),
        number_of_implemented_interfaces:\(self.numberOfImplementedInterfaces),
        number_of_attributes:\(self.numberOfAttributes),
        number_of_children:\(self.numberOfChildren),
        class_complexity:\(self.classComplexity),
        coupling_between_object_classes:\(self.couplingBetweenObjectClasses),
        lack_of_cohesion_in_methods:\(self.lackOfCohesionInMethods),
        is_abstract:\(self.isAbstract),
        is_activity:\(self.isActivity),
        is_viewController:\(self.isViewController),
        is_application:\(self.isApplication),
        is_broadcast_receiver:\(self.isBroadcastReceiver),
        is_content_provider:\(self.isContentProvider),
        is_service:\(self.isService),
        is_final:\(self.isFinal),
        is_static:\(self.isStatic),
        is_inner_class:\(self.isInnerClass),
        is_interface:\(self.isInterface),
        is_view_controller:\(self.isViewController),
        number_of_instructions:\(self.numberOfInstructions),
        depth_of_inheritance:\(self.depthOfInheritance),
        number_of_comments:\(self.numberOfComments),
        data_string:\"\(dataString)\"\(optionalProperties)
        }
        """
    }
    
    var createQuery: String? {
        let query = "create (n:\(self.nodeName) \(self.properties)) return id(n)"
        print("query: \(query)")
        return query
    }
    
    var deleteQuery: String? {
        if let id = self.id {
            return "delete (n:\(self.nodeName) where id(n)=\(id)"
        }
        return nil
    }
    
    var updateQuery: String? {
        if let id = self.id {
            return """
            match (n:\(self.nodeName)
            where id(n)=\(id) set n += \(self.properties)
            """
        }
        return nil
    }
    
    func ownsMethodQuery(_ method: Function) -> String? {
        if let classId = self.id, let methodId = method.id {
            return "match (a:Class), (c:Method) where id(a) = \(classId) and id(c) = \(methodId) create (a)-[r:CLASS_OWNS_METHOD]->(c) return id(r)"
        }
        return nil
    }
    
    func ownsVariableQuery(_ variable: Variable) -> String? {
        if let classId = self.id, let variableId = variable.id {
            return "match (a:Class), (c:Variable) where id(a) = \(classId) and id(c) = \(variableId) create (a)-[r:CLASS_OWNS_VARIABLE]->(c) return id(r)"
        }
        return nil
    }
    
    func extendsQuery(_ someClass: Class) -> String? {
        if let selfId = self.id, let classId = someClass.id {
            return "match (a:Class), (c:Class) where id(a) = \(selfId) and id(c) = \(classId) create (a)-[r:EXTENDS]->(c) return id(r)"
        }
        return nil
    }
    
    func implementsQuery(_ someClass: Class) -> String? {
        if let selfId = self.id, let classId = someClass.id {
            return "match (a:Class), (c:Class) where id(a) = \(selfId) and id(c) = \(classId) create (a)-[r:IMPLEMENTS]->(c) return id(r)"
        }
        return nil
    }
}

class ClassInstance: Class, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.class"
    }
}

class Protocol: Class, SourceKittenMappable {
    override init(name: String, appKey: String, modifier: String, module: Module) {
        super.init(name: name, appKey: appKey, modifier: modifier, module: module)
        self.isInterface = true
    }
    
    static var kittenKey: String {
        return "source.lang.swift.decl.protocol"
    }
}
