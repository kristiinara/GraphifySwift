//
//  InstanceMethod.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 21/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

//import Foundation

class Function: Kind {
    var id: Int?
    var name: String
    var appKey: String = "Default"
    var instructions: [Instruction] = []
    var parameters: [Argument] = []
    var modifier: String = ""
    var returnType: String = ""
    var fullName: String = "" // "name#class_name"
    
    //var numberOfDeclaredLocals = 0
    var numberOfDeclaredLocals : Int {
        return self.instructions.reduce(0) { result, instruction in
            return result + instruction.numberOfLocalVariables
        }
    }
    
    var isAbstract = false
    var isFinal = false
    var isStatic = false
    var isGetter = false // android specific? or look how get, set is displayed for swift
    var isSetter = false // same
    var isSyncronized = false // android specific?
    
    //TODO: stuff that we cannot set at the beginning
    var numberOfCallers = 0 // number of callers of this method
    //var numberOfDirectCalls = 0 // number of calls to other methods
    var numberOfDirectCalls : Int {
        return self.instructions.reduce(0) { result, instruction in
            return result + instruction.methodCalls.count
        }
    }
    
    //var cyclomaticComplexity = 0 // McCabe cyclomatic complexity. Represents the number of execution path inside a method. Minimum is one, the number is incremented for each branche detected in the body of a method. Type : Integer
    var cyclomaticComplexity : Int {
        return self.instructions.reduce(1) { result, instruction in
            return result + instruction.complexity
        }
    }
    
//    init(name: String) {
//        self.name = name
//    }
    
    init(name: String, fullName: String, appKey: String, modifier: String, returnType: String) {
        self.name = name
        self.fullName = fullName
        self.appKey = appKey
        self.modifier = modifier
        self.returnType = returnType
    }
    
    init(name: String, fullName: String, appKey: String, modifier: String, returnType: String, instructions: [Instruction], parameters: [Argument]) {
        self.name = name
        self.fullName = fullName
        self.appKey = appKey
        self.modifier = modifier
        self.returnType = returnType
        self.instructions = instructions
        self.parameters = parameters
    }
    
    public var description: String {
        return "Method: \(name) "
    }
    
    
    
    var isInit: Bool {
        return self.name.contains("init") //TODO: maybe not the best way to distinguish?
    }
    
    var numberOfInstructions : Int {
        return self.instructions.reduce(1) { (result, instruction) -> Int in
            return result + instruction.numberOfInstructions
        }
    }
    
    var numberOfParameters: Int {
        return self.parameters.count
    }
}

extension Function: Node4jInsertable {
    var nodeName: String {
        return "Method"
    }
    
    var properties: String {
        return """
        {
            name:'\(self.name)',
            app_key:'\(self.appKey)',
            modifier:'\(self.modifier)',
            full_name:'\(self.fullName)',
            return_type:'\(self.returnType)',
            number_of_parameters:\(self.numberOfParameters),
            number_of_declared_locals:\(self.numberOfDeclaredLocals),
            number_of_instructions:\(self.numberOfInstructions),
            number_of_direct_calls:\(self.numberOfDirectCalls),
            number_of_callers:\(self.numberOfCallers),
            cyclomatic_complexity:\(self.cyclomaticComplexity),
            is_abstract:\(self.isAbstract),
            is_final:\(self.isFinal),
            is_static:\(self.isStatic),
            is_getter:\(self.isGetter),
            is_setter:\(self.isSetter),
            is_synchronized:\(self.isSyncronized)
        }
        """
    }
    
    var createQuery: String? {
        return "create (n:\(self.nodeName) \(self.properties)) return id(n)"
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
    
    func ownsArgumentQuery(_ argument: Argument) -> String? {
        if let methodId = self.id, let  argumnetId = argument.id {
            return "match (a:Method), (c:Argument) where id(a) = \(methodId) and id(c) = \(argumnetId) create (a)-[r:METHOD_OWNS_ARGUMENT]->(c) return id(r)"
        }
        return nil
    }
    
    func usesQuery(_ variable: Variable) -> String? {
        if let methodId = self.id, let  variableId = variable.id {
            return "match (a:Method), (c:Variable) where id(a) = \(methodId) and id(c) = \(variableId) create (a)-[r:USES]->(c) return id(r)"
        }
        return nil
    }
    
    func callsQuery(_ method: Function) -> String? {
        if let selfid = self.id, let  methodId = method.id {
            return "match (a:Method), (c:Method) where id(a) = \(selfid) and id(c) = \(methodId) create (a)-[r:CALLS]->(c) return id(r)"
        }
        return nil
    }
}

class ClassFunction: Function, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.function.method.class"
    }
}

class StaticFunction: Function, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.function.method.static"
    }
}

class InstanceFunction: Function, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.function.method.instance"
    }
}
