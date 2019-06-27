//
//  Instruction.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 11/04/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

//import Foundation

//TODO:
//  add to instruction class possibility to calculate method calls for a given method (maybe even a query for a given method name?) or get all method names and go from there to find where these mehods reside.

class Instruction {
    let stringValue: String
    let kind: String
    var instructions: [Instruction] = []
    
    var numberOfInstructions : Int {
        return self.instructions.reduce(1) { (result, instruction) -> Int in
            return result + instruction.numberOfInstructions
        }
    }
    
    var numberOfLocalVariables : Int {
        return self.instructions.reduce(0) { (result, instruction) -> Int in
            if let local = instruction as? LocalVariable {
                return result + local.numberOfInstructions + 1
            } else {
                return result + instruction.numberOfInstructions
            }
        }
    }
    
    var methodCalls : [MethodCall] {
        var calls: [MethodCall] = []
        if let currentMethodCall = self as? MethodCall {
            calls.append(currentMethodCall)
        }
            
        let additionalCalls = self.instructions.reduce([]) { (result, instruction) -> [MethodCall] in
            if let methodCall = instruction as? MethodCall {
                let newResult = result + instruction.methodCalls
                return newResult
            } else {
                return result + instruction.methodCalls
            }
        }
        calls.append(contentsOf: additionalCalls)
        
        return calls
    }
    
    var complexity: Int {
        return self.instructions.reduce(0) { (result, instruction) -> Int in
            if let branch = instruction as? Branch {
                return result + 1 + branch.complexity
            }
            
            return result + instruction.complexity
        }
    }
    
//    //TODO: can we implement this here?
//    func callsMethod(_ method: Function) -> Bool {
//        return false
//    }
    
    init(stringValue: String, kind: String) {
        self.stringValue = stringValue
        self.kind = kind
    }
}

class MethodCall: Instruction, SourceKittenMappable {
    var calledMethod: Function?
    
    static var kittenKey: String {
        return "source.lang.swift.expr.call"
    }
}

class Branch: Instruction {}

class If: Branch, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.stmt.if"
    }
}

class ForEach: Branch, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.stmt.if"
    }
}

class For: Branch, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.stmt.for"
    }
}

class While: Branch, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.stmt.while"
    }
}

class RepeatWhile: Branch, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.stmt.repeatwhile"
    }
}

class Guard: Branch, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.stmt.guard"
    }
}

class Switch: Branch, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.stmt.switch"
    }
}

class Case: Branch, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.stmt.case"
    }
}

class LocalVariable: Branch, SourceKittenMappable {
    var typeName: String?
    
    static var kittenKey: String {
        return "source.lang.swift.decl.var.local"
    }
}
