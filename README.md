# GraphifySwiftCMD

GraphifySwiftCMD is a command line tool that makes it possible to analyse a lot of iOS applications at once. 

## Usage

Analyse an application:
      
    GraphifySwiftCMD analyse --appkey <applicationKey> <pathToRepository> -m 

Query code smells:

    GraphifySwiftCMD query -q all
    
Display prototype of architecture analysis:

    GraphifySwiftCMD classDiagram <pathToRepository>

## Code smell definitions

Our goal is to analyse 31 code smells in total. We combined the code smells defined by Martin Fowler and 22 OOP code smells that were detected by InFusion in the research article "Understanding code smells in Android".

### Long method

##### Query string

    MATCH (c:Class)-[r:CLASS_OWNS_METHOD]->(m:Method) 
    WHERE m.number_of_instructions > veryHighNumberOfInstructions 
    RETURN 
      	m.name as name, 
      	c.name as class_name, 
      	m.app_key as app_key, 
      	m.number_of_instructions as number_of_instructions
  
##### Parameters  
Query matches all methods where the number of instructions is bigger than a very high number of instructions. 

##### How are parameters determined
All parameters will be determined statistically by the box-blot technique once a big number of applications is analysed. 

Threshold is currently set to 26.

##### Implementation details
Number of instructions is calculated as follows in the Function class

    var numberOfInstructions : Int {
        return self.instructions.reduce(1) { (result, instruction) -> Int in
            return result + instruction.numberOfInstructions
        }
    }
 and as follows in the Instruction class
 
    var numberOfInstructions : Int {
        return self.instructions.reduce(1) { (result, instruction) -> Int in
            return result + instruction.numberOfInstructions
        }
    }

##### Reference
Definition is taken from Paprika.

### Large class / Blob class
##### Query string

    MATCH (cl:Class) 
    WHERE
       cl.lack_of_cohesion_in_methods > veryHighLackOfCohesienInMethods AND
       cl.number_of_methods >  veryHighNumberOfMethods AND
       cl.number_of_attributes > veryHighNumberOfMethods
    RETURN 
      	cl.name as class_name, 
    	cl.app_key as app_key
  
##### Parameters  
Query matches all classes where lack of cohesion in methods is very high, number of methods is very high and number of attributes is very high. 

##### How are parameters determined
All parameters will be determined statistically by the box-blot technique once a big number of applications is analysed. 

Currently thresholds for very high lack of cohesion is set to 40, very high number of attributes is set to 13 and very high number of methods is set to 22.

##### Implementation details

Lack of cohesion in methods is calculated as follows: 

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

##### Reference
Definition taken from Paprika.

### Shotgun surgery
##### Query string

    MATCH (other_m:Method)-[r:CALLS]->(m:Method) with m, 
    COUNT(r) as number_of_callers 
    WHERE number_of_callers > veryHighNumberOfCallers
    RETURN 
    	m.name as name, 
    	m.app_key as app_key, 
    	number_of_callers as number_of_caller
  
##### Parameters  
Queries all methods that are called by more than a very high number of callers.

##### How are parameters determined
All parameters will be determined statistically by the box-blot technique once a big number of applications is analysed. 

Currently thresholds for very high number of callers is set to 2.

##### Implementation details
Number of callers is calculated as follows: 

    var numberOfCallers : Int {
        return self.methodReferences.count + variableReferences.count
    }
NB: it might make sense to query and count the callers in the query instead of using this metric. 

##### Reference
Understanding code smells in android applications: "This smell is evident when you must change lots of pieces of code in different places simply to add a new or extended piece of behaviour. Whenever a method is called by too many other methods, any change to such a method ripples through the design. Such changes are likely to fail when the number of to-be-changed locations exceeds the capacity of human’s short term memory."

Martin Fowlers book: "Shotgun surgery is similar to divergent change but is the opposite. You whiff this when every time you make a kind of change, you have to make a lot of little changes to a lot of different classes. When the changes are all over the place, they are hard to find, and it's easy to miss an important change." .. "Divergent change is one class that suffers many kinds of changes, and shotgun surgery is one change that alters many classes. Either way you want to arrange things so that, ideally, there is a one-to-one link between common changes and classes."

### Switch statements

##### Query string

    MATCH (c:Class)-[r:CLASS_OWNS_METHOD]->(m:Method) 
    WHERE m.number_of_switch_statements >= highNumberOfSwitchStatments
    RETURN 
    	m.name as name, 
    	c.name as class_name, 
    	m.app_key as app_key, 
    	m.number_of_switch_statements as number_of_switch_statements
  
##### Parameters  
Queries all methods, where the number of switch statements is higher than high number of switch statements.

##### How are parameters determined
Parameter will either be determined statistically using the box-blot technique or we will go with the definition that all switch statements are considered smells and define it to be 1.

Currently threshold for high number of switch statements is set to 1.

##### Implementation details

Number of switch statements is calculated as follows in the Function class
    
    var numberOfSwitchStatements: Int {
        return self.instructions.reduce(0) { res, statement in
            return res + statement.numberOfSwitchStatements
        }
    }

And as follows in the Instruction class

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

##### References

Martin Fowlers book: "One of the most obvious symptoms of object-oriented code is its comparative lack of switch (or case) statements. The problem with switch statements is essentially that of duplication. Often you find the same switch statement scattered about a program in different places. If you add a new clause to the switch, you have to find all these switch, statements and change them. The object- oriented notion of polymorphism gives you an elegant way to deal with this problem." .. "If you only have a few cases that affect a single method, and you don't expect them to change, then polymorphism is overkill. In this case Replace Parameter with Explicit Methods is a good option."

### Lazy class

##### Query string

    MATCH (c:Class) 
    WHERE 
    	c.number_of_methods = 0 OR 
    	(c.number_of_instructions < mediumNumberOfInstructions AND  
    		c.number_of_weighted_methods/c.number_of_methods <= lowComplexityMethodRatio) OR 
    	(c.coupling_between_object_classes < mediumCouplingBetweenObjectClasses AND 
    		c.depth_of_inheritance > numberOfSomeDepthOfInheritance) 
    RETURN 
    	c.name as name, 
    	c.app_key as app_key
  
##### Parameters  
Queries all methods, where the number of switch statements is higher than high number of switch statements.

##### How are parameters determined
Medium number of instructions and medium coupling between objects is determined statistically. Low complexity method ratio is determined statistically using the box-plot technique. Number of some depth of inheritance is set to be one by definition. 

Currently medium number of instructions is 50, low complexity method ratio is 2, medium coupling between object classes is 20 and number of some depth of inheritance is 1.

##### Implementation details
Number of weighted methods is calculated as follows

    var numberOfWeightedMethods: Int {
        return self.allMethods.reduce(0) { res, method in
            return res + method.cyclomaticComplexity
        }
    }
    
Cyclomatic complexity for a method is calculated as follows

    var cyclomaticComplexity : Int {
        return self.instructions.reduce(1) { result, instruction in
            return result + instruction.complexity
        }
    }
Complexity for an instruction is calculated as follows

    var complexity: Int {
        return self.instructions.reduce(0) { (result, instruction) -> Int in
            if let branch = instruction as? Branch {
                return result + 1 + branch.complexity
            }
            
            return result + instruction.complexity
        }
    }
  
Coupling between object classes is calculated in the App class as follows: 

    func calculateCouplingBetweenClasses() {
        var allClasses: [Class] = []
        allClasses.append(contentsOf: self.classes)
        allClasses.append(contentsOf: self.structures)
        let classCount = allClasses.count
        
        if classCount >= 2 {
            for i in 0...(classCount - 2) {
                let classInstance = allClasses[i]
                var numberOfCoupledClasses = 0
                
                for j in (i+1)...(classCount - 1) {
                    let otherClassInstance = allClasses[j]
                    
                    let allMethods = classInstance.allMethods
                    let allOtherClassMethodUsrs = otherClassInstance.allMethods.map() {method in return method.usr}
                    
                    outerloop: for method in allMethods {
                        for referencedMethod in method.referencedMethods {
                            if allOtherClassMethodUsrs.contains(referencedMethod.usr) {
                                numberOfCoupledClasses += 1
                                break outerloop
                            }
                        }
                    }
                }
                classInstance.couplingBetweenObjectClasses = numberOfCoupledClasses
            }
        }
    }
    
Depth of inheritance is calculated as follows
   
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


##### References
"Product Metrics for Automatic Identification of “Bad Smell” Design Problems in Java Source-Code" - under: "Automatic detection fo bad smells"

##### Metric definitions
weighted\_methods\_per\_class = sum of all method complexities in a class

### Message chains

##### Query string

    MATCH (c:Class)-[CLASS_OWNS_METHOD]-(m:Method) 
    WHERE m.max_number_of_chaned_message_calls > veryHighNumberOfChainedMessages 
    RETURN 
    	m.name as name, 
    	c.name as class_name, 
    	m.app_key as app_key, 
    	m.max_number_of_chaned_message_calls as max_number_of_chaned_message_calls
  
##### Parameters  
Queries all methods, where the maximum number of chained message calls is larger than very high. 

##### How are parameters determined
All parameters will be determined statistically by the box-blot technique once a big number of applications is analysed. 

Currently very high number of chained messages is set to 3. 

##### Implementation details
SourceKitten: methods consist of a lot of instructions. There can be instructions inside instructions (for example if there is a method call inside a method call). One type of instructions are method calls. We define message chains as chains of method calls inside each other.

Maximum number of chained method calls for a Function is calculated as follows

    var maxNumberOfChanedMessageCalls: Int {
        var biggestChangedMessageCall = 0
        
        for instruction in self.instructions {
            if instruction.maxNumberOfChanedMessageCalls > biggestChangedMessageCall {
                biggestChangedMessageCall = instruction.maxNumberOfChanedMessageCalls
            }
        }
        return biggestChangedMessageCall
    }

Chained method calls is determined in the Instruction class as follows

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

##### References 
 Article "The Inconsistent Measurement of Message Chains David"
 

### Data class

##### Query string

    MATCH (c:Class) 
    WHERE c.number_of_methods = 0 
    RETURN 
    	c.name as name, 
    	c.app_key as app_key, 
    	c.number_of_attributes as number_of_attributes
  
##### Parameters  
Queries all classes where number of methods is 0.

##### How are parameters determined
No parameters.

##### Implementation details

\-

##### References 

Article "Understanding Code Smells in Android Applications": "Data Classes are "dumb" data holders, without complex functionality, but which are usually heavily relied upon by other classes in the system. Data classes are the manifestation of a lacking encapsulation of data, and of a poor data-functionality proximity. By allowing other modules or classes to access their internal data, data classes contribute to a brittle, and harder to maintain design [12,19,24,37]." 

Martin Fowlers book: "These are classes that have fields, getting and setting methods for the fields, and nothing else.".

### Refused bequest / refused parent bequest

Not applicable for swift since swift does not have the keyword protected. 

##### Definition

    (number_of_protected_members > few) and 
    (base_class_usage_ratio < a_third) or 
    (base_class_overriding_ratio < third) and 
    (((average_method_weight > average) or 
    	(weighted_method_count > average)) and 
    	(number_of_methods > average))

##### Parameters
number\_of\_protected\_members - is the number of protected members in a class, this means members that cannot be called from outside of the class. 

base\_class\_usage\_ratio - is used to measure how much is the child class using inherited members from the base class

base\_class\_overriding_ration - is used to measure how much is the child class overriding members from the base class

average\_method\_weight - is used to measure the average complexity of all methods of a class

weighted\_method\_count - adding together complexity of all methods


##### Implementation details

The only way to define something similar to protected in a swift class would be to use fileprivate, but then the subclass would need to be in the same file as the parent class. 

Since swift classes don't have protected members there is no way to know if the members in the parent class are meant to be overridden or if they are not overridden simply because it makes more sense to use them directly. 

Therefore this code smell is not implemented in our program. 

##### References 

Definition taken from https://www.simpleorientedarchitecture.com/how-to-identify-refused-parent-bequest-using-ndepend/

### Comments

##### Query string

    MATCH (c:Class) 
    WHERE c.number_of_comments highNumberOfComments 
    RETURN 
    	c.name, 
    	c.number_of_comments
  
##### Parameters  
Queries all classes where number of comments is high. 

##### How are parameters determined
High number of comments will either be determined statistically using the box-plot technique or will be set to 1.

Currently high number of comments is set to 20.

##### Implementation details 

We simply search for "//" and "/*" in a file and identify this as a comment. Currently it could happen that we count a "//" inside a long comment, but since there is still a comment we accept this mistake. But there is room for improvement. 

Comments are found as follows:

    func handleComments(_ fileContents: String) -> [Comment] {
        let lines = fileContents.components(separatedBy: "\n")
        var comments : [Comment] = []
        
        var lineNumber = 0
        var commentString = ""
        
        for line in lines {
            lineNumber += 1
            
            var slashIndex: String.Index?
            var longCommentIndex: String.Index?
            
            if line.contains("//") {
                if let range = line.range(of: "//") {
                    slashIndex = range.lowerBound
                }
            }
            
            if line.contains("/*") {
                if let range = line.range(of: "/*") {
                    longCommentIndex = range.lowerBound
                }
            }
            
            if let localSlashIndex = slashIndex, longCommentIndex == nil {
                commentString = String(line[localSlashIndex..<line.endIndex])
                comments.append(Comment(lineNumber: lineNumber, string: commentString))
                commentString = ""
                
                slashIndex = nil
                longCommentIndex = nil
            }
            
            if let localLongCommentIndex = longCommentIndex {
                commentString = String(line[localLongCommentIndex..<line.endIndex])
                comments.append(Comment(lineNumber: lineNumber, string: commentString))
                commentString = ""
                
                slashIndex = nil
                longCommentIndex = nil
            }
        }
        
        return comments
    }

##### References 

Martin Fowlers book: "Don't worry, we aren't saying that people shouldn't write comments. In our olfactory analogy, comments aren't a bad smell; indeed they are a sweet smell. The reason we mention comments
here is that comments often are used as a deodorant. It's surprising how often you look at thickly commented code and notice that the comments are there because the code is bad.

Comments lead us to bad code that has all the rotten whiffs we've discussed in the rest of this chapter. Our first action is to remove the bad smells by refactoring. When we're finished, we often find that the comments are superfluous.

If you need a comment to explain what a block of code does, try Extract Method. If the method is already extracted but you still need a comment to explain what it does, use Rename Method. If you need to state some rules about the required state of the system, use Introduce Assertion.

A good time to use a comment is when you don't know what to do. In addition to describing what is going on, comments can indicate areas in which you aren't sure. A comment is a good place to say why you did something. This kind of information helps future modifiers, especially forgetful ones."

### Cyclic dependencies (dependencies between classes)

##### Query string

    MATCH 
    	(c:Class)-[:CLASS_OWNS_VARIABLE]->(v:Variable)-[:IS_OF_TYPE]->(c2:Class), 
    	cyclePath=shortestPath((c2)-[*]->(c)) 
    WITH 
    	c, 
    	v, 
    	[n in nodes(cyclePath) | n.name ] as names, 
    	filter(n in nodes(cyclePath) where not n:Variable) as classes 
    UNWIND classes as node 
    WITH max(id(node)) as max 
    MATCH (c:Class) 
    WHERE id(c)=max 
    RETURN c.name, c.app_key
  
##### Parameters  
Queries all cycles between Class-Variable-Class, finds the shortest cycle and returns the name of the class and app_key with the biggest id in this cycle as the beginning point.

##### How are parameters determined
No parameters.

##### Implementation details 

Cyclic dependencies are found through relationships in the neo4j database. We search for Class-Variable-Class-Variable-..-Class chains that form a cycle. Neo4j database has native support to find these kind of cycles and can find the shortest existing cycle. 

##### References 

Article "Understanding Code Smells in Android Applications": "Cyclic Dependencies are violations of the Acyclic Dependencies Principle formulated by Robert Martin [26] as "The dependency structure between packages must be a Directed Acyclic Graph (DAG). That is, there must be no cycles in the dependency structure". The design flaw applies to dependencies between subsystems of a system. If two or more subsystems are involved in a cycle, maintaining or reusing any one of those subsystems in isolation will be harder or impossible [19,24]."

Article "Architectural Smells Detected by Tools: a Catalogue Proposal": "Detection Comparison: The tools usually (Designite, Massey Architecture Explorer, Sonargraph, STAN, Struc- ture 101) detect this smell only at the class level, then analyse this smell at package level through the general- isation of the dependency graph at class level obtained using the quite standard rule: if a class a, contained in package A, depends on class b, contained in package B, then the package A depends on package B. This type of analysis is useful for a visual representation because it allows to start with a high level view and then expand the most relevant packages. The detection approach pre- viously mentioned is also used by others tools (Arcan, Hotspot Detector), however, they treat the packages and the classes as distinct elements and perform a two layers analysis. The possibility of considering these two layers individually during the architecture quality assessment can be very useful for many reasons, as for example the prioritisation of the refactoring, in fact the intra-package cycles are usually considered less problematic compared to the inter-package cycles. Finally, AI Reviewer and ARCADE"

### Cyclic dependencies (dependencies between modules)
Normally when discussing cyclic dependencies the dependencies between modules are meant. Dependencies between modules are not possible in swift as the build of such projects fails.

##### Implementation details 

In swift when we want to create a new module it means that we have to create a new target in the Xcode project. This target can be for example in its simplest form a static library. When we now import these static libraries in a way that creates a dependency graph then the build will fail. Therefore it does not make sense to find cyclic dependencies between modules. 

In the future we might consider adding the possibility to find cyclic dependencies between categories of classes. For example between view classes, controller classes and module classes.

##### References 

Article "Architectural Smells Detected by Tools: a Catalogue Proposal": "Detection Comparison: The tools usually (Designite, Massey Architecture Explorer, Sonargraph, STAN, Struc- ture 101) detect this smell only at the class level, then analyse this smell at package level through the general- isation of the dependency graph at class level obtained using the quite standard rule: if a class a, contained in package A, depends on class b, contained in package B, then the package A depends on package B. This type of analysis is useful for a visual representation because it allows to start with a high level view and then expand the most relevant packages. The detection approach pre- viously mentioned is also used by others tools (Arcan, Hotspot Detector), however, they treat the packages and the classes as distinct elements and perform a two layers analysis. The possibility of considering these two layers individually during the architecture quality assessment can be very useful for many reasons, as for example the prioritisation of the refactoring, in fact the intra-package cycles are usually considered less problematic compared to the inter-package cycles. Finally, AI Reviewer and ARCADE"

### Intensive coupling

##### Query string

    MATCH 
    	(c:Class)-[r:CLASS_OWNS_METHOD]->(m1:Method)-[s:CALLS]->(m2:Method), 
    	(c2:Class)-[r2:CLASS_OWNS_METHOD]->(m2) 
    WHERE id(c) <> id(c2) 
    WITH 
    	c,
    	m1, 
    	count(distinct m2) as method_count, 
    	collect(distinct m2.name) as names, 
    	collect(distinct c2.name) as class_names, 
    	count(distinct c2) as class_count  
    WHERE 
    	((method_count >= maxNumberOfShortMemoryCap and 
    		class_count/method_count <= halfCouplingDispersion) or 
    	(method_count >= fewCouplingIntensity 
    		and class_count/method_count <= quarterCouplingDispersion)) and 
    	m1.max_nesting_depth >= shallowMaximumNestingDepth
    RETURN 
    	m1.app_key as app_key, 
    	m1.name as method_name, 
    	c.name as class_name
  
##### Parameters  
Queries methods that are intensively coupled with methods in other classes. A method is defined as intensely coupled if the number of methods it calls is larger than the short memory cap and coupling dispersion is lower than half or if the number of methods it calls is larger than few and coupling dispersion is smaller than few and the maximum nesting depth of the method is larger than shallow. 

##### How are parameters determined
Maximum number of short memory cap is agreed to be 7-8. Half coupling dispersion is 0.5 and quarter coupling dispersion is 0.25. Shallow number of nesting depth is generally accepted to be 1. Few is generally accepted to be 2-5. 

Currently values are set as follows: 
maximum number of short memory cap is set to 7, few coupling intensity is set to 2, shallow maximum nesting depth is set to 1. 

It is probably necessary to test different values for these. 

##### Implementation details 

The maximum nesting depth for a method is calculated as follows

    var maxNestingDepth: Int {
        let nestingDepths = self.instructions.map() {instruction in instruction.maxNestingDepth}
        return nestingDepths.max() ?? 0
    }
    
The maximum nesting depth for instructions is found as follows

    var maxNestingDepth: Int {
        let nestingDepths = self.instructions.map() {instruction in instruction.maxNestingDepth}
        var maxDepth = nestingDepths.max() ?? 0
        
        if let _ = self as? Branch {
            maxDepth += 1
        }
        
        return maxDepth
    }

##### References 

This definition for intensive coupling comes from https://www.simpleorientedarchitecture.com/identify-efferent-coupling-code-smells-using-ndepend/

### Distorted hierarchy

##### Query string

    MATCH (c:Class) 
    WHERE c.depth_of_inheritance > shortTermMemoryCap  
    RETURN 
    	c.app_key, 
    	c.name, 
    	c.depth_of_inheritance
  
##### Parameters  
Queries classes that have an unusually deep inheritance tree. Finds classes with depth of inheritance larger than the short term memory cap.

##### How are parameters determined
Short term memory cap is currently set to 6. Referenced article says that this is commonly agreed on. Probably needs additional investigation or trying out different values. 

##### Implementation details 

Depth of inheritance is determined as follows

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
    
##### References 

Definition is taken form Article "Understanding Code Smells in Android Applications": "A Distorted Hierarchy is an inheritance hierarchy that is unusually narrow and deep. This design flaw is inspired by one of Arthur Riel's [37] heuristics, which says that "in practice, inheritance hierarchies should be no deeper than an average person can keep in his or her short-term memory. A popular value for this depth is six". Having an inheritance hierarchy that is too deep may cause maintainers "to get lost" in the hierarchy making the system in general harder to maintain.[37]"

Might make sense to also look into if inheritance hierarchy is narrow, but there is no reference that quantifies that. 

### Tradition Breaker

##### Query string

    MATCH (c:Class)-[r:EXTENDS]->(parent:Class) 
    WHERE 
    	NOT ()-[:EXTENDS]->(c) AND 	
    	c.number_of_methods + c.number_of_attributes < lowNumberOfmethodsAndAttributes AND 
    	parent.number_of_methods + parent.number_of_attributes >= highNumberOfMethodsAndAttributes 
    RETURN 
    	c.app_key as app_key, 
    	c.name as child_name, 
    	parent.name as parent_name
  
##### Parameters  
Queries classes that do not have any subclasses, where number of methods and attributes is low and where they inherit from a class whose number of methods and attributes is high. 

##### How are parameters determined
High number of methods and attributes and low number of methods and attributes both need to be determined statistically using the boxplot technique. 

Qurrently high number of attributes and methods is set to 20 and low number of attributes and methods is set to 5.

##### Implementation details 
\-
    
##### References 

There are different definition for this code smell. We tried to implement the defintion used by decor/ptidej-5 (https://wiki.ptidej.net/doku.php?id=sad): "A class that inherits from a large parent class but that provides little behaviour and without subclasses". The given rule card (although a little bit confusing considering the textual description) is as follows
  
    RULE_CARD : TraditionBreaker { 
   		RULE : TraditionBreaker {INHERIT: inherited FROM: LargeParentClass ONE TO: ChildClass ONE } ; 
   		RULE : LargeParentClass { INTER LargeClass ParentClass } ; 
   		RULE : LargeClass { (METRIC: NMD + NAD, LOW, 10) } ; 
   		RULE : ParentClass {INTER NoInheritance HasChildren };
   		RULE : NoInheritance {(METRIC: DIT, SUP_EQ, 1, 0) };
   		RULE : HasChildren {(METRIC: NOC, SUP_EQ, 1, 0) };
   		RULE : ChildClass { (METRIC: NMD + NAD, HIGH, 10) } ;
	};
	
Here NMD = number of methods declared, NAD = number of attributes declared, DIT = depth of inheritance, NOC = number of children. 

Another definition is given here (https://www.simpleorientedarchitecture.com/how-to-identify-a-tradition-breaker-using-ndepend/): "class suffers from Tradition Breaker when it doesn’t use the protected members of its parent". With this definition it would probably not make sense to apply this code smell for swift. The first definition seems to work. 

### Sibling Duplication 

##### Query string

    MATCH 
    	(firstClass:Class)-[:EXTENDS*]-> (parent:Class) <-[:EXTENDS*]-(secondClass:Class), 
    	(firstClass:Class)-[:DUPLICATES]->(secondClass:Class) 
    RETURN 
    	firstClass.app_key as app_key, 
    	firstClass.name as first_class, 
    	secondClass.name as second_class, 
    	parent.name as parent_class
  
##### Parameters  
Query classes that have a common parent class (somewhere in the hierarchy) and that share duplicated code. 

##### How are parameters determined
\-

##### Implementation details 
To find duplicated code we are using the program jscpd https://github.com/kucherenko/jscpd#getting-started . It has to be installed on the system and is called automatically by the code analysis tool. 

For installation on Mac OS:

- brew update
- brew install node
- npm install -g jscpd

After that jscpd can be used from the command line. 

We get the jscpd analysis for a project with as follows

        var path = homePath
        if !path.hasSuffix("/") {
            path = "\(path)/"
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = [
            "jscpd",
            homePath,
            "--min-tokens", "10",
            "--format", "swift",
            "--reporters", "json",
            "--absolute",
            "--output", "\(homePath)jscpd-report/",
            "--ignore ", ignore.joined(separator: ",")
        ]
        task.launch()
        task.waitUntilExit()
        
        self.json = self.jsonFromPath(path:"\(homePath)jscpd-report/jscpd-report.json")
        
When we have the result json, then we go through the duplication results, which are in form: 

       "duplicates": [
		{
			"format": "swift",
			"lines": 15,
			"fragment": ".......",
			"tokens": 0,
			"firstFile": {
				"name": "Sources/GraphifySwiftCMD/Application.swift",
				"start": 95,
				"end": 109,
				"startLoc": {
					"line": 95,
					"column": 82
				},
				"endLoc": {
					"line": 109,
					"column": 21
				}
			},
			"secondFile": {
				"name": "Sources/GraphifySwiftCMD/Application.swift",
				"start": 60,
				"end": 75,
				"startLoc": {
					"line": 60,
					"column": 84
				},
				"endLoc": {
					"line": 75,
					"column": 20
				}
			} 		
		},
		...
		]

We then match these duplications with class instances through the file paths. 

All found duplications are recorded in the database as relationships between classes i.e. (:Class)-[:DUPLICATES]->(:Class). In reality the direction of the relationship has no meaning, but it is not possible to add relationships without directions. It is on the other hand possible to query relationships without specifying the direction.

NB: it is possible to change the threshold for the duplication level, minimum number of tokens etc. It would make sense to play around with these values to see if we can find the most appropriate ones for the current context. 

##### References 

From "Understanding Code Smells in Android Applications": "Sibling Duplication means duplication between siblings in an inheritance hierarchy. Two or more siblings that define a similar functionality make it much harder to locate errors [4,12,18,19].".


### Internal Duplication 

##### Query string

    MATCH 
    	(firstClass:Class)-[:DUPLICATES]->(secondClass:Class), 
    	(module:Module)-[:MODULE_OWNS_CLASS]->(firstClass), 
    	(module:Module)-[:MODULE_OWNS_CLASS]->(secondClass) 
    RETURN 
    	firstClass.app_key as app_key, 
    	firstClass.name as first_class, 
    	secondClass.name as second_class, 
    	module.name as module_name
  
##### Parameters  
Query classes that belong to the same module and that share duplicated code. 

##### How are parameters determined
\-

##### Implementation details 
See Sibling Duplication.

##### References 

From "Understanding Code Smells in Android Applications": "Internal Duplication means duplication between portions of the same class or module. Thus, the presence of code duplication bloats the class or module and all the clones do not evolve the same way [4,12,18,19].".

### External Duplication 

##### Query string

    MATCH 
    	(firstClass:Class)-[:DUPLICATES]->(secondClass:Class), 
    	(module:Module)-[:MODULE_OWNS_CLASS]->(firstClass), 
    	(secondModule:Module)-[:MODULE_OWNS_CLASS]->(secondClass) 
    WHERE 
    	id(module) <> id(secondModule) 
    RETURN 
    	firstClass.app_key as app_key, 
    	firstClass.name as first_class, 
    	secondClass.name as second_class, 
    	module.name as module_name, 
    	secondModule.name as second_module_name
  
##### Parameters  
Query classes that belong to different modules and that share duplicated code. 

##### How are parameters determined
\-

##### Implementation details 
See Sibling Duplication.

##### References 

From "Understanding Code Smells in Android Applications": External Duplication means duplication between unrelated capsules of the system [4,12,18,19].".