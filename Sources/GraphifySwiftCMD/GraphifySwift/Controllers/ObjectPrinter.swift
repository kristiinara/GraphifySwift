//
//  ObjectPrinter.swift
//  Basic
//
//  Created by Kristiina Rahkema on 27/06/2019.
//

import Foundation

class ObjectPrinter {
    
    static func printApp(_ app: App) {
        print("App: \(String(describing: app))")
        print("Classes:")
        for classInstance in app.classes {
            print("     Class: \(classInstance.name) - \(classInstance.usr)")
            print("     LackOfCohesion: \(classInstance.lackOfCohesionInMethods)")
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
            
            print("     InstanceVariables: ")
            for variable in classInstance.instanceVariables {
                printVariable(variable)
            }
            print("     ClassVariables: ")
            for variable in classInstance.classVariables {
                printVariable(variable)
            }
            print("     InstanceVariables: ")
            for variable in classInstance.staticVariables {
                printVariable(variable)
            }
            print("     ------------")
            print("     DataString: ")
            print("     \(classInstance.dataString): ")
            print("     ------------")
        }
        
//        print("Duplicates: ")
//        for duplicate in app.duplicates {
//            print("firstClass: \(String(describing: duplicate.firstClass?.name))")
//            print("secondClass: \(String(describing: duplicate.secondClass?.name))")
//            print("fragment: \(duplicate.fragment)")
//            print("")
//        }
    }
    
    static func printMethod(_ method: Function) {
        print("               Method: \(method.name) - \(method.characterOffset) - \(method.lineNumber) - \(method.endLineNumber) - \(method.usr)")
        print("                  Stats: inst: \(method.numberOfInstructions), compl: \(method.cyclomaticComplexity), directCalls: \(method.numberOfDirectCalls), refMethods: \(method.referencedMethods.count), refVariables: \(method.referencedVariables.count)")
        print("                           direct: \(method.directCalls)")
        print("                           ref: \(method.methodReferenceNames)")
        print("                           refVar: \(method.variableReferenceNames)")
        print("                           refLocalVar: \(method.localVariableNames)")
        print("                           dataString: \(method.dataString)")
        
        for argument in method.parameters {
            print("                      Argument: \(argument.name)")
        }
        
//        print("                     referenced methods: ")
//        for refMethod in method.methodReferences {
//            print(refMethod.name)
//        }
//
//        print("                     referenced variables: ")
//        for refVariable in method.variableReferences {
//            print(refVariable.name)
//        }
        
        for instruction in method.instructions {
            //printInstruction(instruction)
        }
    }
    
    static func printVariable(_ variable: Variable) {
        print("               Variable: \(variable.name) - \(variable.usr)")
//        print("                  Stats: refMethods: \(variable.methodReferences.count), refVariables: \(variable.variableReferences.count)")
    }
    
    static func printInstruction(_ instruction: Instruction) {
        print("                      Instruction: \(instruction.stringValue), kind: \(instruction.kind)")
        for subInstruction in instruction.instructions {
            printInstruction(subInstruction)
        }
    }
}
