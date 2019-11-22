//
//  InstanceMethod.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 21/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

class Function: Kind {
    var id: Int?
    var usr: String?
    var name: String
    var appKey: String = "Default"
    var instructions: [Instruction] = []
    var parameters: [Argument] = []
    var modifier: String = ""
    var returnType: String = ""
    var fullName: String = "" // "name#class_name"
    var characterOffset: Int?
    var length: Int?
    var lineNumber: Int?
    var endLineNumber: Int?
    var dataString: String = ""
    
    weak var classInstance: Class?
    
    var uses: [Int]?
    
    var references: [String] = []
    
    var methodReferences: [Function] = [] // when called from other functions
    var variableReferences: [Variable] = []
    
    var referencedMethods: [Function] = [] // when other functions are called
    var referencedVariables: [Variable] = []
    
    //var numberOfDeclaredLocals = 0
    var numberOfDeclaredLocals : Int {
        return self.instructions.reduce(0) { result, instruction in
            return result + instruction.numberOfLocalVariables
        }
    }
    
    var isAbstract = false
    var isFinal = false
    var isStatic = false
    var isGetter = false //TODO:  android specific? or look how get, set is displayed for swift
    var isSetter = false // same
    var isSyncronized = false // android specific?
    
    //stuff that we cannot set at the beginning
    var numberOfCallers : Int {
        return self.methodReferences.count + variableReferences.count
    }
    
    var numberOfDirectCalls : Int {
        return self.referencedMethods.count
    }
    
    //TODO: figure out if it's ok that we only list methods in the scope of the project (we could also add method calls to foundation, UIKit etc
    var directCalls : [String] {
        return self.referencedMethods.reduce([] as [String]) { result, method in
            var methods = result
            methods.append(method.name)
            
            return methods
        }
    }
    
    var methodReferenceNames: [String] {
        return self.methodReferences.map() { method in
            return method.name
        }
    }
    
    var variableReferenceNames: [String] {
        return self.referencedVariables.map() { variable in
            return variable.name
        }
    }
    
    // McCabe cyclomatic complexity. Represents the number of execution path inside a method. Minimum is one, the number is incremented for each branche detected in the body of a method. Type : Integer
    var cyclomaticComplexity : Int {
        return self.instructions.reduce(1) { result, instruction in
            return result + instruction.complexity
        }
    }
    
    var maxNestingDepth: Int {
        let nestingDepths = self.instructions.map() {instruction in instruction.maxNestingDepth}
        return nestingDepths.max() ?? 0
    }
    
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
    
    //TODO: implement + possibly change String to Variable
    var usedVariables: [String] {
        return self.referencedVariables.map() {variable in return variable.name}
    }
    
    var localVariableNames: [String] {
        let instructions = self.instructions.reduce([] as [LocalVariable]) { result, instruction in
            var list: [LocalVariable] = []
            list.append(contentsOf: result)
            list.append(contentsOf: instruction.localVariables)
            return list
        }
        
        return instructions.map() { instruction in
            return instruction.stringValue
        }
    }
    
    // Added variables:
    var numberOfSwitchStatements: Int {
        return self.instructions.reduce(0) { res, statement in
            return res + statement.numberOfSwitchStatements
        }
    }
    
    var maxNumberOfChanedMessageCalls: Int {
        var biggestChangedMessageCall = 0
        
        for instruction in self.instructions {
            if instruction.maxNumberOfChanedMessageCalls > biggestChangedMessageCall {
                biggestChangedMessageCall = instruction.maxNumberOfChanedMessageCalls
            }
        }
        return biggestChangedMessageCall
    }
    
    func variablesInCommon(_ otherMethod: Function) -> Set<String> {
        let variableSet = Set(self.usedVariables)
        return variableSet.intersection(otherMethod.usedVariables)
    }
    
    func hasVariablesInCommon(_ otherMethod: Function) -> Bool {
        return self.variablesInCommon(otherMethod).count > 0
    }
    
    func lineInFunction(_ line: Int) -> Bool? {
        guard let startLine = self.lineNumber else {
            return nil
        }
        
        guard let endLine = self.endLineNumber else {
            return nil
        }
        
        if line < startLine {
            return false
        }
        
        if line > endLine {
            return false
        }
        
        return true
    }
}

extension Function: Node4jInsertable {
    var nodeName: String {
        return "Method"
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
            is_synchronized:\(self.isSyncronized),
            number_of_switch_statements:\(self.numberOfSwitchStatements),
            max_number_of_chaned_message_calls:\(self.maxNumberOfChanedMessageCalls),
            max_nesting_depth:\(self.maxNestingDepth),
            data_string:\"\(dataString)\"\(optionalProperties)
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
