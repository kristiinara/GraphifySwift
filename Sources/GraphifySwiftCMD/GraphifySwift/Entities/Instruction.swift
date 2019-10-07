//
//  Instruction.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 11/04/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

class Instruction {
    let stringValue: String
    let kind: String
    var offset: Int64?
    
    var instructions: [Instruction] = []
    
    var numberOfSwitchStatements: Int {
        var switchStatements = 0
        
        if let _ = self as? Switch {
            switchStatements += 1
        }
        
        switchStatements += self.instructions.reduce(0) { res, statement in
            return res + statement.numberOfSwitchStatements
        }
        
        return switchStatements
    }
    
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
                let newResult = result + methodCall.methodCalls
                return newResult
            } else {
                return result + instruction.methodCalls
            }
        }
        calls.append(contentsOf: additionalCalls)
        
        return calls
    }
    
    var localVariables : [LocalVariable] {
        var variables: [LocalVariable] = []
        if let currentLocalVariable = self as? LocalVariable {
            variables.append(currentLocalVariable)
        }
        
        let additionalVariables = self.instructions.reduce([]) { (result, instruction) -> [LocalVariable] in
            if let localVariable = instruction as? LocalVariable {
                let newResult = result + localVariable.localVariables
                return newResult
            } else {
                return result + instruction.localVariables
            }
        }
        variables.append(contentsOf: additionalVariables)
        
        return variables
    }
    
    var complexity: Int {
        return self.instructions.reduce(0) { (result, instruction) -> Int in
            if let branch = instruction as? Branch {
                return result + 1 + branch.complexity
            }
            
            return result + instruction.complexity
        }
    }
    
    var maxNestingDepth: Int {
        let nestingDepths = self.instructions.map() {instruction in instruction.maxNestingDepth}
        var maxDepth = nestingDepths.max() ?? 0
        
        if let _ = self as? Branch {
            maxDepth += 1
        }
        
        return maxDepth
    }
    
    var chainedMessageCalls: [[MethodCall]] {
        var calls: [[MethodCall]] = []
        
        for instruction in instructions {
            var chainedCalls = instruction.chainedMessageCalls
            
            if let instruction = instruction as? MethodCall {
                if chainedCalls.count > 0 {
                    chainedCalls = chainedCalls.map() { subCalls in
                        var res = [instruction]
                        res.append(contentsOf: subCalls)
                        return res
                    }
                } else {
                    chainedCalls.append([instruction])
                }
            }
            calls.append(contentsOf: chainedCalls)
        }
        return calls
    }
    
    var maxNumberOfChanedMessageCalls: Int {
        let lengthOfMessageCalls = self.chainedMessageCalls.map() { chain in
            return chain.count
        }
        
        return lengthOfMessageCalls.max() ?? 0
    }
    
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
