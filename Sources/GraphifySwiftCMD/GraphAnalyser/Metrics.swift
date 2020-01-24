//
//  Metrics.swift
//  Basic
//
//  Created by Kristiina Rahkema on 30/11/2019.
//

import Foundation

struct Metrics {
    /*
    // ALL old apps
    // class related
    static let veryHighNumberOfAttributes = 11
    static let veryLowNumberOfAttributes = 0
    static let veryHighNumberOfMethods = 13.5
    static let veryLowNumberOfMethods = 0
    static let veryHighNumberOfInstructionsClass = 157.5
    static let medianNumberOfInstructionsClass = 21
    static let veryHighNumberOfComments = 32.625
    static let veryHighClassComplexity = 36
    static let LowComplexityMethodRatio = 1
    static let medianCouplingBetweenObjectClasses = 0
    static let veryHighNumberOfMethodsAndAttributes = 22
    static let lowNumberOfMethodsAndAttributes = 2
    static let veryHighLackOfCohesionInMethods = 22.5
    
    // method related
    static let veryHighCyclomaticComplexity = 6
    static let highCyclomaticComplexity = 3
    static let veryHighNumberOfCalledMethods = 2.5
    static let veryHighNumberOfCallers = 0
    static let veryHighNumberOfInstructionsMethod = 33
    static let highNumberOfInstructionsMethod = 15
    static let lowNumberOfInstructionsMethod = 3
    static let veryHighNumberOfParameters = 2.5
    static let veryHighNumberOfChainedMessages = 0 // will not work!
    static let veryHighNumberOfSwitchStatements = 0 // will not work!
    
    // interface related
    static let veryHighNumberOfMethodsInterface = 3.5
    */
    
    /*
    // MATCHING old apps
    // class related
    static let veryHighNumberOfAttributes = 11
    static let veryLowNumberOfAttributes = 0
    static let veryHighNumberOfMethods = 13.5
    static let veryLowNumberOfMethods = 0
    static let veryHighNumberOfInstructionsClass = 167.5 // small difference
    static let medianNumberOfInstructionsClass = 22 // small difference
    static let veryHighNumberOfComments = 29.5 // small diffference
    static let veryHighClassComplexity = 36
    static let LowComplexityMethodRatio = 1
    static let medianCouplingBetweenObjectClasses = 0
    static let veryHighNumberOfMethodsAndAttributes = 24.5 // small difference
    static let lowNumberOfMethodsAndAttributes = 2
    static let veryHighLackOfCohesionInMethods = 22.5
    
    // method related
    static let veryHighCyclomaticComplexity = 6
    static let highCyclomaticComplexity = 3
    static let veryHighNumberOfCalledMethods = 2.5
    static let veryHighNumberOfCallers = 0
    static let veryHighNumberOfInstructionsMethod = 33
     static let lowNumberOfInstructionsMethod = 3
    static let highNumberOfInstructionsMethod = 15
    static let veryHighNumberOfParameters = 2.5
    static let veryHighNumberOfChainedMessages = 5 // different to all apps
    static let veryHighNumberOfSwitchStatements = 0
       
    // interface related
    static let veryHighNumberOfMethodsInterface = 5 // different, vs 3.5
    */
    /*
    
    // IN APP STORE
    static let veryHighNumberOfAttributes = 11
    static let veryLowNumberOfAttributes = 0
    static let veryHighNumberOfMethods = 13.5
    static let veryLowNumberOfMethods = 0
    static let veryHighNumberOfInstructionsClass = 165.0 // small difference
    static let medianNumberOfInstructionsClass = 20 // small difference
    static let veryHighNumberOfComments = 29.5 // small diffference to all
    static let veryHighClassComplexity = 36
    static let LowComplexityMethodRatio = 1
    static let medianCouplingBetweenObjectClasses = 0
    static let veryHighNumberOfMethodsAndAttributes = 22 // small difference to matching
    static let lowNumberOfMethodsAndAttributes = 2
    static let veryHighLackOfCohesionInMethods = 20 // small difference
    
    // method related
    static let veryHighCyclomaticComplexity = 6
    static let highCyclomaticComplexity = 3
    static let veryHighNumberOfCalledMethods = 2.5
    static let veryHighNumberOfCallers = 2.5 // difference vs 0
    static let veryHighNumberOfInstructionsMethod = 33
    static let lowNumberOfInstructionsMethod = 3
    static let highNumberOfInstructionsMethod = 15
    static let veryHighNumberOfParameters = 2.5
    static let veryHighNumberOfChainedMessages = 5 // different to all apps
    static let veryHighNumberOfSwitchStatements = 0
       
    // interface related
    static let veryHighNumberOfMethodsInterface = 3.5 // different, vs 3.5 to matching
    */
    
    /*
    
    // all + metrics from article
    // class related
    static let veryHighNumberOfAttributes = 2.5
    static let veryLowNumberOfAttributes = 0
    static let veryHighNumberOfMethods = 7.5
    static let veryLowNumberOfMethods = 0
    static let veryHighNumberOfInstructionsClass = 100
    static let medianNumberOfInstructionsClass = 17
    static let veryHighNumberOfComments = 32.625
    static let veryHighClassComplexity = 12.5
    static let LowComplexityMethodRatio = 1
    static let medianCouplingBetweenObjectClasses = 0
    static let veryHighNumberOfMethodsAndAttributes = 22
    static let lowNumberOfMethodsAndAttributes = 2
    static let veryHighLackOfCohesionInMethods = 22.5
    
    // method related
    static let veryHighCyclomaticComplexity = 6
    static let highCyclomaticComplexity = 3
    static let veryHighNumberOfCalledMethods = 2.5
    static let veryHighNumberOfCallers = 0
    static let veryHighNumberOfInstructionsMethod = 33
    static let highNumberOfInstructionsMethod = 24.6
    static let lowNumberOfInstructionsMethod = 3
    static let veryHighNumberOfParameters = 2
    static let veryHighNumberOfChainedMessages = 0 // will not work!
    static let veryHighNumberOfSwitchStatements = 0 // will not work!
    
    // interface related
    static let veryHighNumberOfMethodsInterface = 5
     
    */
    /*
    
    // all + actual metrics from article
    // MATCHING old apps
    // class related
    static let veryHighNumberOfAttributes = 15 // article code
    static let veryLowNumberOfAttributes = 0
    static let veryHighNumberOfMethods = 18.5 // article code
    static let veryLowNumberOfMethods = 0
    static let veryHighNumberOfInstructionsClass = 375 // article code
    static let medianNumberOfInstructionsClass = 22
    static let veryHighNumberOfComments = 29.5
    static let veryHighClassComplexity = 41.5 // article code
    static let LowComplexityMethodRatio = 1
    static let medianCouplingBetweenObjectClasses = 0
    static let veryHighNumberOfMethodsAndAttributes = 24.5
    static let lowNumberOfMethodsAndAttributes = 2
    static let veryHighLackOfCohesionInMethods = 22.5
    
    // method related
    static let veryHighCyclomaticComplexity = 6
    static let highCyclomaticComplexity = 3
    static let veryHighNumberOfCalledMethods = 2.5
    static let veryHighNumberOfCallers = 0
    static let veryHighNumberOfInstructionsMethod = 30.5 // article code
     static let lowNumberOfInstructionsMethod = 3
    static let highNumberOfInstructionsMethod = 15
    static let veryHighNumberOfParameters = 2.5
    static let veryHighNumberOfChainedMessages = 5
    static let veryHighNumberOfSwitchStatements = 0
       
    // interface related
    static let veryHighNumberOfMethodsInterface = 6 // article code
    
    */
    
    // Metrics new apps
    // class related
    static let veryHighNumberOfAttributes = 13.5
    static let veryLowNumberOfAttributes = 0
    static let veryHighNumberOfMethods = 13.5
    static let veryLowNumberOfMethods = 0
    static let veryHighNumberOfInstructionsClass = 147.5
    static let medianNumberOfInstructionsClass = 20
    static let veryHighNumberOfComments = 29.5
    static let veryHighClassComplexity = 33.5
    static let LowComplexityMethodRatio = 1
    static let medianCouplingBetweenObjectClasses = 0
    static let veryHighNumberOfMethodsAndAttributes = 24.5
    static let lowNumberOfMethodsAndAttributes = 2
    static let veryHighLackOfCohesionInMethods = 17.5
    static let highNumberOfCallsBetweenClasses = 5
    
    // method related
    static let veryHighCyclomaticComplexity = 6
    static let highCyclomaticComplexity = 3
    static let veryHighNumberOfCalledMethods = 2.5
    static let veryHighNumberOfCallers = 2.5
    static let veryHighNumberOfInstructionsMethod = 30.5
    static let highNumberOfInstructionsMethod = 14
    static let lowNumberOfInstructionsMethod = 3
    static let veryHighNumberOfParameters = 2.5
    static let veryHighNumberOfChainedMessages = 2.5
    static let veryHighNumberOfSwitchStatements = 0 // will not work!
    
    // variable related
    static let veryHighPrimitiveVariableUse = 6
    
    // interface related
    static let veryHighNumberOfMethodsInterface = 5 
    
    
    // other metrics
    static let shorTermMemoryCap = 7
}


/*
 metric&   very\_low&  Q1&  median&  Q3&  very\_high \\
 number\_of\_attribues&  0&  0&  0&  1&  2.5\\
 number\_of\_methods&  0&  0&  1&  3&  7.5\\
 number\_of\_lines_class&  0&  5&  17&  43&  100\\
 class\_complexity&  0&  0&  2&  5&  12.5\\
 number\_of\_lines_method&  0&  2&  5&  11&  24.5\\
 number\_of\_methods_interface&  0&  0&  1&  2&  5\\
 */
