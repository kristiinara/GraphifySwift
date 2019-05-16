//
//  Struct.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 21/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

//import Foundation

//class Struct : Kind {
//    var id: Int?
//    var name: String
//    var instanceVariables: [Variable]
//    var instanceMethods: [Function]
//    var appKey: String = "Default"
//    var modifier: String = ""
//    var parentName: String = ""
//    var numberOfImplementedInterfaces: Int = 0
//    var numberOfChildren: Int = 0
//    var classComplexity: Int = 0
//
//    init(name: String, instanceVariables: [Variable], instanceMethods: [Function]) {
//        self.name = name
//        self.instanceVariables = []
//        self.instanceMethods = []
//    }
//
//    init(name: String, appKey: String, modifier: String, parentName: String, instanceVariables: [Variable], instanceMethods: [Function]) {
//        self.name = name
//        self.appKey = appKey
//        self.modifier = modifier
//        self.parentName = parentName
//        self.instanceVariables = instanceVariables
//        self.instanceMethods = instanceMethods
//    }
//
//    var description: String {
//        return """
//        Struct: \(name)
//        instance variables: \(self.instanceVariables)
//        instance methods: \(self.instanceMethods)
//        """
//    }
//
//    var numberOfMethods: Int {
//        return self.instanceMethods.count
//    }
//
//    var numberOfAttributes: Int {
//        return self.instanceVariables.count
//    }
//}
//
//extension Struct: Node4jInsertable {
//    var nodeName: String {
//        return "Struct"
//    }
//
//    var properties: String {
//        return """
//        {
//        name:'\(self.name)',
//        app_key:'\(self.appKey)',
//        modifier:'\(self.modifier)',
//        parent_name:'\(self.parentName)',
//        number_of_methods:\(self.numberOfMethods),
//        number_of_implemented_interfaces:\(self.numberOfImplementedInterfaces),
//        number_of_attributes:\(self.numberOfAttributes),
//        number_of_children:\(self.numberOfChildren),
//        class_complexity:\(self.classComplexity)
//        }
//        """
////        coupling_between_object_classes:\(self.couplingBetweenObjectClasses),
////        lack_of_cohesion_in_methods:\(self.lackOfCohesionInMethods),
////        is_abstract:\(self.isAbstract),
////        is_activity:\(self.isActivity),
////        is_viewController:\(self.isViewController),
////        is_application:\(self.isApplication),
////        is_broadcast_receiver:\(self.isBroadcastReceiver),
////        is_content_provider:\(self.isContentProvider),
////        is_service:\(self.isService),
////        is_final:\(self.isFinal),
////        is_static:\(self.isStatic),
////        is_inner_class:\(self.isInnerClass),
////        is_interface:\(self.isInterface)
////        }
//    }
//
//    var createQuery: String? {
//        return "create (n:\(self.nodeName) \(self.properties)) return id(n)"
//    }
//
//    var deleteQuery: String? {
//        if let id = self.id {
//            return "delete (n:\(self.nodeName) where id(n)=\(id)"
//        }
//        return nil
//    }
//
//    var updateQuery: String? {
//        if let id = self.id {
//            return """
//            match (n:\(self.nodeName)
//            where id(n)=\(id) set n += \(self.properties)
//            """
//        }
//        return nil
//    }
//
//    func ownsMethodQuery(_ method: Function) -> String? {
//        if let classId = self.id, let methodId = method.id {
//            return "match (a:Struct), (c:Method) where id(a) = \(classId) and id(c) = \(methodId) create (a)-[r:CLASS_OWNS_METHOD]->(c) return id(r)"
//        }
//        return nil
//    }
//
//    func ownsVariableQuery(_ variable: Variable) -> String? {
//        if let classId = self.id, let variableId = variable.id {
//            return "match (a:Struct), (c:Variable) where id(a) = \(classId) and id(c) = \(variableId) create (a)-[r:CLASS_OWNS_VARIABLE]->(c) return id(r)"
//        }
//        return nil
//    }
//}

class Struct: Class {
    
}

extension Struct: SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.struct"
    }
}
