# GraphifySwiftCMD

GraphifySwiftCMD is a command line tool that makes it possible to analyse a lot of iOS applications at once. 

## Usage

Analyse an application:
      
    GraphifySwiftCMD analyse --appkey <applicationKey> <pathToRepository> -m 

Query code smells:

    GraphifySwiftCMD query -q all
    
Display prototype of architecture analysis:

    GraphifySwiftCMD classDiagram <pathToRepository>
    
    
## Additional queries

### Information

Information query is not a code smell, but provides basic information for each application for overview purposes. Might make sense to add such information also for each module or class in the future. 

##### Query string

    MATCH 
    	(a:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(c:Class) 
   	OPTIONAL MATCH 
    	(c)-[:CLASS_OWNS_METHOD]->(m:Method) 
  	OPTIONAL MATCH 
  		(c)-[:CLASS_OWNS_VARIABLE]->(v:Variable) 
  	WITH 
  		a, 
  		count(distinct c) as number, 
  		count(distinct m) as methods, 
  		count(distinct v) as variables, 
  		count(distinct module) as modules 
  	RETURN 
  		a.app_key as app_key, 
  		a.name as name, 
  		modules as number_of_modules, 
  		a.number_of_classes as number_of_classes, 
  		a.number_of_interfaces as number_of_interfaces, 
  		number as number_of_types, 
  		methods as number_of_methods, 
  		variables as number_of_variables, 
  		a.date_download as date_download, 
  		a.developer as developer

## Code smell definitions

Our goal is to analyse 31 code smells in total. We combined the code smells defined by Martin Fowler and 22 OOP code smells that were detected by InFusion in the research article "Understanding code smells in Android".

### Long method

##### Query string

    MATCH (c:Class)-[r:CLASS_OWNS_METHOD]->(m:Method) 
    WHERE m.number_of_instructions > veryHighNumberOfInstructions 
    RETURN 
      	m.app_key as app_key, 
      	c.name as class_name,
      	m.name as method_name, 
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
      	cl.app_key as app_key, 
      	cl.name as class_name, 
      	cl.lack_of_cohesion_in_methods as lack_of_cohesion_in_methods, 
      	cl.number_of_methods as number_of_methods, 
      	cl.number_of_attributes as number_of_attributes
  
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

    MATCH (other_m:Method)-[r:CALLS]->(m:Method)<-[:CLASS_OWNS_METHOD]-(c:Class) 
    WITH
    	c, 
    	m, 
    	COUNT(r) as number_of_callers 
    WHERE number_of_callers > veryHighNumberOfCallers
    RETURN 
    	m.app_key as app_key, 
    	c.name as class_name, 
    	m.name as method_name, 
    	number_of_callers as number_of_callers
  
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
    	m.app_key as app_key, 
    	c.name as class_name, 
    	m.name as method_name, 
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
    	c.app_key as app_key, 
    	c.name as class_name
  
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
    	m.app_key as app_key, 
    	c.name as class_name, 
    	m.name as method_name, 
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
    	c.app_key as app_key, 
    	c.name as class_name, 
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
    	c.app_key as app_key, 
    	c.name as class_name, 
    	c.number_of_comments as number_of_comments
  
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
    RETURN 
    	c.app_key as app_key, 
    	c.name as class_name
  
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
    	c.name as class_name, 
    	m1.name as method_name
  
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
    	c.app_key as app_key, 
    	c.name as class_name, 
    	c.depth_of_inheritance as dept_of_inheritance
  
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
    	c.name as class_name, 
    	parent.name as parent_class_name
  
##### Parameters  
Queries classes that do not have any subclasses, where number of methods and attributes is low and where they inherit from a class whose number of methods and attributes is high. 

##### How are parameters determined
High number of methods and attributes and low number of methods and attributes both need to be determined statistically using the box-plot technique. 

Currently high number of attributes and methods is set to 20 and low number of attributes and methods is set to 5.

##### Implementation details 
\-
    
##### References 

There are different definition for this code smell. We tried to implement the definition used by decor/ptidej-5 (https://wiki.ptidej.net/doku.php?id=sad): "A class that inherits from a large parent class but that provides little behaviour and without subclasses". The given rule card (although a little bit confusing considering the textual description) is as follows
  
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
    	firstClass.name as class_name, 
    	secondClass.name as second_class_name, 
    	parent.name as parent_class_name
  
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
    	(firstClass:Class)-[r:DUPLICATES]->(secondClass:Class), 
    	(module:Module)-[:MODULE_OWNS_CLASS]->(firstClass), 
    	(module:Module)-[:MODULE_OWNS_CLASS]->(secondClass) 
    RETURN 
    	firstClass.app_key as app_key, 
    	firstClass.name as class_name, 
    	secondClass.name as second_class_name, 
    	module.name as module_name, 
    	r.fragment as text_fragment
  
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
    	firstClass.name as class_name, 
    	secondClass.name as second_class_name, 
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

### Divergent Change/Schizophrenic Class

##### Query string

    MATCH 
    	(c:Class)-[:CLASS_OWNS_METHOD]->(m:Method)-[r:CALLS]->(other_method:Method) 
    WITH 
    	c,
    	m, 
    	COUNT(r) as number_of_called_methods 
    WHERE 
    	number_of_called_methods > veryHighNumberOfCalledMethods
    RETURN 
    	m.app_key as app_key, 
    	c.name as class_name, 
    	m.name as method_name, 
    	number_of_called_methods as number_of_called_methods
  
##### Parameters  
Query methods that call a very high number of methods. 

##### How are parameters determined
Very high number of methods has to be determined statistically using the box-plot technique. Value currently set to 20. 

##### Implementation details 
\-

##### References 
- "Understanding code smells in android applications": ""A "schizophrenic class" is a class that captures two or more key abstractions. It negatively affects the ability to understand and change in isolation the individual abstractions that it captures. [12,37]"
- "Towards a Principle-based Classification of Structural Design Smells": "This design smell arises when an abstraction has more than one responsibility assigned to it"
- Fowler's book: "We structure our software to make change easier; after all, software is meant to be soft. When we make a change we want to be able to jump to a single clear point in the system and make the change. When you can't do this you are smelling one of two closely related pungencies. Divergent change occurs when one class is commonly changed in different ways for different reasons. If you look at a class and say, "Well, I will have to change these three methods every time I get a new database; I have to change these four methods every time there is a new financial instrument," you likely have a situation in which two objects are better than one. That way each object is changed only as a result of one kind of change. Of course, you often discover this only after you've added a few databases or financial instruments. Any change to handle a variation should change a single class, and all the typing in the new class should express the variation. To clean this up you identify everything that changes for a particular cause and use Extract Class to put them all together."
- opposite of shotgun surgery (based on Fowler's book)
- shotgun surgery: methods that are called from more than n other methods

### Long parameter list

##### Query string

    MATCH 
    	(c:Class)-[:CLASS_OWNS_METHOD]->(m:Method)-[r:METHOD_OWNS_ARGUMENT]->(a:Argument) 
    WITH 
    	c, 
    	m, 
    	count(a) as argument_count 
    WHERE argument_count > veryHighNumberOfParameters 
    RETURN 
    	m.app_key as app_key, 
    	c.name as class_name, 
    	m.name as method_name, 
    	argument_count as argument_count
  
##### Parameters  
Query methods that have a very long parameter list. 

##### How are parameters determined
Very high number of parameters either has to be determined statistically using the box-plot technique or it should be the threshold that a person can reasonably handle when reading the function description. 

##### Implementation details 
\-

##### References 
Fowler's book: "In our early programming days we were taught to pass in as parameters everything needed by a routine. This was understandable because the alternative was global data, and global data is evil and usually painful. Objects change this situation because if you don't have something you need, you can always ask another object to get it for you. Thus with objects you don't pass in everything the method needs; instead you pass enough so that the method can get to everything it needs. A lot of what a method needs is available on the method's host class. In object-oriented programs parameter lists tend to be much smaller than in traditional programs.
This is good because long parameter lists are hard to understand, because they become inconsistent and difficult to use, and because you are forever changing them as you need more data. Most changes are removed by passing objects because you are much more likely to need to make only a couple of requests to get at a new piece of data."

### Feature envy

##### Query string

    MATCH 
    	(c:Class)-[:CLASS_OWNS_METHOD]->(m:Method)-[r:CALLS]->(other_method:Method) 
    WITH 
    	c,
    	m, 
    	COUNT(r) as number_of_called_methods 
    WHERE 
    	number_of_called_methods > veryHighNumberOfCalledMethods
    RETURN 
    	m.app_key as app_key, 
    	c.name as class_name, 
    	m.name as method_name, 
    	number_of_called_methods as number_of_called_methods
  
##### Parameters  
Query methods that call a very high number of methods. 

##### How are parameters determined
Very high number of methods has to be determined statistically using the box-plot technique. Value currently set to 20. 

##### Implementation details 
\-

##### References 
- "Understanding code smells in android applications": ""A "schizophrenic class" is a class that captures two or more key abstractions. It negatively affects the ability to understand and change in isolation the individual abstractions that it captures. [12,37]"
- "Towards a Principle-based Classification of Structural Design Smells": "This design smell arises when an abstraction has more than one responsibility assigned to it"
- Fowler's book: "We structure our software to make change easier; after all, software is meant to be soft. When we make a change we want to be able to jump to a single clear point in the system and make the change. When you can't do this you are smelling one of two closely related pungencies. Divergent change occurs when one class is commonly changed in different ways for different reasons. If you look at a class and say, "Well, I will have to change these three methods every time I get a new database; I have to change these four methods every time there is a new financial instrument," you likely have a situation in which two objects are better than one. That way each object is changed only as a result of one kind of change. Of course, you often discover this only after you've added a few databases or financial instruments. Any change to handle a variation should change a single class, and all the typing in the new class should express the variation. To clean this up you identify everything that changes for a particular cause and use Extract Class to put them all together."
- opposite of shotgun surgery (based on Fowler's book)
- shotgun surgery: methods that are called from more than n other methods

### Long parameter list

##### Query string

    MATCH  
    	(class:Class)-[:CLASS_OWNS_METHOD]->(m:Method)-[:USES]->(v:Variable)<-[:CLASS_OWNS_VARIABLE]-(other_class:Class)
    WHERE 
    	class <> other_class
    WITH
       class, 
       m,
       count(distinct v) as variable_count,
       collect(distinct v.name) as names,
       collect(distinct other_class.name) as class_names,
       count(distinct other_class) as class_count
    MATCH 
    	(class)-[:CLASS_OWNS_METHOD]->(m)-[:USES]->(v:Variable)<-[:CLASS_OWNS_VARIABLE]-(class)
    WITH
        class, 
        m, 
        variable_count, 
        class_names, 
        names,
        count(distinct v) as local_variable_count,
        collect(distinct v.name) as local_names,
        class_count
    WHERE
    	local_variable_count + variable_count > 0
    WITH 
    	class, 
    	m, 
    	variable_count, 
    	class_names, 
    	names, 
    	local_variable_count, 
    	local_names, 
    	class_count,
    	local_variable_count*1.0/(local_variable_count+variable_count) as locality
    WHERE
       variable_count > fewAccessToForeignVariables and 
       locality < localityFraction and 
       class_count <= fewAccessToForeignClasses
    RETURN
       class.app_key as app_key, 
       class.name as class_name, 
       m.name as method_name, 
       variable_count,
       class_count,
       names as foreign_variable_names, 
       class_names, 
       local_variable_count, 
       local_names as local_variable_names, 
       locality
  
##### Parameters  
Query methods that access more variables outside of the class than inside of the class. 

##### How are parameters determined
Few access to foreign variables and few access to foreign classes use generally accepted thresholds, view is normally between 2 and 5, both currently set to 2. Locality fraction is a common threshold set to 0.33.

##### Implementation details 
\-

##### References 
"Understanding code smells in android applications": "The Feature Envy design flaw refers to functions or methods that seem more interested in the data of other Classes and modules than the data of those in which they reside. These "envious operations" access either directly or via accessor methods. This situation is a strong indication that the affected method was probably misplaced and that it should be moved to the capsule that defines the "envied data" [12,19,24,37]."

Exact definition from: https://www.simpleorientedarchitecture.com/how-to-identify-feature-envy-using-ndepend/

### Data clumps (class variables)

##### Query string

    MATCH 
    	(app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
    MATCH
        (app)-[:APP_OWNS_MODULE]->(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_VARIABLE]->(other_variable:Variable)
    WHERE 
    	class <> other_class and 
    	variable.type = other_variable.type and 
    	variable.name = other_variable.name
    WITH 
    	app, 
    	class, 
    	other_class, 
    	variable order by variable.name 	WITH 
		app, 
		class, 
		other_class, 
		collect(distinct variable.name) as variable_names, 		count(DISTINCT variable) as variable_count
    WITH 
    	app, 
    	class, 
    	other_class, 
    	variable_names, 
    	variable_count order by id(class)
    WITH 
    	app, 
    	collect(distinct id(other_class)) + id(class) as class_ids, 
    	variable_names, 
    	variable_count
    WHERE 
    	variable_count >= highNumberOfRepeatingVariables
    MATCH 
    	(app)-[:APP_OWNS_MODULE]->(:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
    WHERE 
    	id(class) in class_ids and 
    	variable.name in variable_names
    WITH 
    	app, 
    	class, 
    	variable, 
    	variable_count, 
    	variable_names order by variable.name
    WITH 
    	app, 
    	class, 
    	collect(distinct variable.name) as new_variable_names, 
    	variable_count, 
    	variable_names
    WITH 
    	app, 
    	collect(distinct class.name) as new_class_names, 
    	new_variable_names, 
    	variable_count
    RETURN 
    	distinct app.app_key as app_key,  
    	new_class_names as class_names, 
    	new_variable_names as variable_names, 
    	variable_count
  
##### Parameters  
Query classes that have at least a high number of variables with the same name and type. Second part of query gets rid of duplicates in results. 

##### How are parameters determined
High number of variables is set to 3 as given in the definition. 

##### Implementation details 
\-

##### References 
From article "Improving the Precision of Fowler’s Definitions of Bad Smells": 
definition for data clumps: 
            
  - Situation 1: 
      - 1. More than three data fields stay together in more than one class. 
      - 2. These data fields should have same signatures (same names, same data types, and same access modifiers). 
      - 3. These data fields may not group together in the same order. 
 - Situation 2: 
      - 1. More than three input parameters stay together in more than one methods’ declaration. 
      - 2. These parameters should have same signatures (same names, same data types). 
      - 3. These parameters may not group together in the same order. 

### Data clumps (function arguments)

##### Query string

    MATCH        
    	(app:App)-[:APP_OWNS_MODULE]->(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
    MATCH
        (app)-[:APP_OWNS_MODULE]->(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)-[:METHOD_OWNS_ARGUMENT]->(other_argument:Argument)
    WHERE 
    	method <> other_method and 
    	argument.name = other_argument.name and 
    	argument.type = other_argument.type
    WITH 
    	app, 
    	class, 
    	other_class, 
    	method, 
    	other_method, 
    	argument order by other_method.name
    WITH 
    	app, 
    	class, 
    	other_class, 
    	method, 
    	other_method, 
    	argument  order by argument.name
    WITH 
    	collect(argument.name) as argument_names, 
    	count(argument.name) as argument_count, 
    	method, 
    	other_method, 
    	app, 
    	class
    WHERE 
    	argument_count >= highNumberOfRepeatingArguments
    WITH 
    	collect(other_method.name) + method.name as method_names,
    	collect(id(other_method)) + id(method) as method_ids, 
    	count(distinct other_method) as method_count,  
    	method, 
    	app, 
    	argument_names, 
    	argument_count, 
    	class
    WITH 
    	collect(class.name) as class_names, 
    	method_names, 
    	app, 
    	argument_names, 
    	argument_count, 
    	method_ids, 
    	method_count
    MATCH        
        (app)-[:APP_OWNS_MODULE]->(:Module)-[:MODULE_OWNS_CLASS]->(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:METHOD_OWNS_ARGUMENT]->(argument:Argument)
    WHERE 
    	id(method) in method_ids and 
    	argument.name in argument_names
    WITH 
    	argument, 
    	app, 
    	method, 
    	argument_names, 
    	argument_count, 
    	class order by argument.name
    WITH 
    	collect(distinct argument.name) as new_argument_names, 
    	app, 
    	method, 
    	argument_names, 
    	argument_count, 
    	class
    WITH 
    	collect(method.name) as new_method_names, 
    	collect(class.name) as class_names, 
    	new_argument_names, 
    	app, 
    	argument_names, 
    	argument_count
    RETURN 
    	app.app_key as app_key, 
    	class_names, 
    	new_method_names as method_names, 
    	new_argument_names as argument_names, 
    	argument_count
  
##### Parameters  
Query methods that have at least a high number of arguments with the same name and type. Second part of query gets rid of duplicates in results. 

##### How are parameters determined
High number of arguments is set to 3 as given in the definition. 

##### Implementation details 
\-

##### References 
From article "Improving the Precision of Fowler’s Definitions of Bad Smells": 
definition for data clumps: 
            
  - Situation 1: 
      - 1. More than three data fields stay together in more than one class. 
      - 2. These data fields should have same signatures (same names, same data types, and same access modifiers). 
      - 3. These data fields may not group together in the same order. 
 - Situation 2: 
      - 1. More than three input parameters stay together in more than one methods’ declaration. 
      - 2. These parameters should have same signatures (same names, same data types). 
      - 3. These parameters may not group together in the same order. 

### Speculative generality (interfaces)

##### Query string

    MATCH 
    	(class:Class) 
    WHERE NOT 
    	()-[:IMPLEMENTS|EXTENDS]->(class) and  
    	class.is_interface = true 
    RETURN 
    	class.app_key as app_key, 
    	class.name as class_name
  
##### Parameters  
Query interfaces that are not implemented or extended. 

##### How are parameters determined
\-

##### Implementation details 
\-

##### References 
From article "Improving the Precision of Fowler’s Definitions of Bad Smells": 
definition for data clumps: 
            
- Situation 1:
	1. A class is an abstract class or interface.
	2. This class has not been inherited or is only inherited by one class.
- Situation 2:
	1. A class contains at least one method which contains at least one parameter which is unused. 

### Speculative generality (methods)

##### Query string

    MATCH  
    	(class)-[:CLASS_OWNS_METHOD]->(m:Method)
    		-[:METHOD_OWNS_ARGUMENT]->(p:Argument)
    		-[:IS_OF_TYPE]->(other_class:Class) 
    WHERE 
    	NOT (m)-[:CALLS|USES]->()
    		<-[:CLASS_OWNS_VARIABLE|CLASS_OWNS_METHOD]-(other_class) AND 
    	NOT m.data_string contains (\"=\" + p.name) AND 
    	NOT m.data_string contains (\"= \" + p.name) AND 
    	NOT m.data_string contains (\":\" + p.name) AND 
    	NOT m.data_string contains (\": \" + p.name) AND 
    	class.is_interface = false 
    RETURN 
    	class.app_key as app_key, 
    	class.name as class_name, 
    	m.name as method_name, 
    	p.name as argument_name, 
    	m.data_string as main_text, 
    	p.name as affected_text
  
##### Parameters  
Query methods that have unused parameters. Unused paramater is defined by there being no relationship of USES or CALLS between the origin class and the type class of the parameter. Parameters are also excluded if they are cointained in the method text as "= parameter\_name" or ": parameter\_name". The idea behing this is to exclude methods where a parameter is used to set antoher parameter all used as a parameter in a function call. 

##### How are parameters determined
\-

##### Implementation details 
\-

##### References 
From article "Improving the Precision of Fowler’s Definitions of Bad Smells": 
definition for data clumps: 
            
- Situation 1:
	1. A class is an abstract class or interface.
	2. This class has not been inherited or is only inherited by one class.
- Situation 2:
	1. A class contains at least one method which contains at least one parameter which is unused. 

### Middle man

##### Query string

    MATCH 
    	(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)-[:USES|CALLS]->(ref)<-[:CLASS_OWNS_VARIABLE|CLASS_OWNS_METHOD]-(other_class:Class) 
    WHERE 
    	class <> other_class and 
    	method.number_of_instructions < smallNumberOfLines 
    WITH 
    	class, 
    	method, 
    	collect(ref.name) as referenced_names, 
    	collect(other_class.name) as class_names 
    WITH 
    	collect(method.name) as method_names, 
    	collect(referenced_names) as references, 
    	collect(class_names) as classes, 
    	collect(method.number_of_instructions) as 
    	numbers_of_instructions, 
    	class, 
    	count(method) as method_count, 
    	count(method)*1.0/class.number_of_methods as method_ratio 
    WHERE 
    	method_ratio > delegationToAllMethodsRatioHalf  
    return 
    	class.app_key as app_key, 
    	class.name as class_name, 
    	method_names, 
    	classes, 
    	numbers_of_instructions, 
    	method_ratio
  
##### Parameters  
Querying all classes where more than half of the methods are delegation methods.  Delegation methods are methods that have at least one reference (uses/calles) to another class but have less than a small number of lines.

##### How are parameters determined
Small number of lines should be determined statistically using the box-plot technique, currently set to 5. Delegation to all methods ratio is set to 0.5.

##### Implementation details 
\-

##### References 
From article "Improving the Precision of Fowler’s Definitions of Bad Smells": 
definition for data clumps: 
            
  1. Half of a class’s methods are delegation methods. 
  2. A delegation method is a method that: 
       - Contains at least one reference to another Class. 
       - Contains less than a threshold value of LOC. 
	
### Parallel inheritance hiearchies

##### Query string

    MATCH 
    	(parent:Class)<-[:MODULE_OWNS_CLASS]-(:Module)<-[:APP_OWNS_MODULE]-(app:App)
    MATCH 
    	(other_app:App)-[:APP_OWNS_MODULE]->(:Module)-[:MODULE_OWNS_CLASS]->(other_parent:Class)
	WHERE 
		app = other_app
	MATCH 
		path = (class:Class)-[:EXTENDS*]->(parent) 
	MATCH 
		other_path = (other_class:Class)-[:EXTENDS*]->(other_parent)
	WHERE 
		parent <> other_parent and 
		length(path) = length(other_path) and 
		length(path) > 0 and 
		class.name starts with substring(other_class.name, 0, prefixLength) and 
		parent.name starts with substring(other_parent.name, 0, prefixLength) 
	WITH 
		collect(distinct [n in nodes(path) | n.name ]) as first, 
		collect(distinct [n in nodes(other_path) | n.name]) as second, 
		parent, 
		other_parent
	WITH 
		REDUCE(output = [], r IN first | output + r) as first_names, 
		REDUCE(output = [], r IN second | output + r) as second_names, 
		parent, 
		other_parent
	UNWIND first_names as first_name
	WITH 
		collect(distinct first_name) as first_names, 
		second_names, 
		parent, 
		other_parent
	UNWIND 
		second_names as second_name
	WITH 
		collect(distinct second_name) as second_names, 
		first_names, 
		parent, 
		other_parent
	WHERE 
		size(first_names) >= minimumNumberOfClassesInHierarchy
	RETURN 
		parent.app_key as app_key, 
		parent.name as parent_class_name, 
		other_parent.name as other_parent_class_name , 
		first_names as first_class_names, 
		second_names as second_class_names, 
		size(first_names) as number_of_classes
  
##### Parameters  
Queries parallel hierarchy trees for classes that start with the same prefixes. Prefix length currently set to 1, minimumNumberOfClassesInHierarchy set to 5.

##### How are parameters determined
For prefix length we should try this query out on a big number of projects and check for false positives, 1 might be an acceptable number. Minimum number of classes in hierarchy is currently set to 5, we should follow the same process as for prefix length. 

##### Implementation details 
It is mostly a historical smell, meaning that it relies on how the code evolves, but it has been suggested that detection should also be possible without historical data if we also look at class prefixes. 

##### References 
From article "Towards a Principle-based Classification of Structural Design Smells": "This design smell arises when there are two structurally similar (symmetrical) class hierarchies with same class name prefixes [Fow99]."

Fowler: "Making a new subclass of one class means that we need to make the same kind of subclass of another class"

### Inappropriate intimacy

##### Query string

    MATCH 
    	(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
	MATCH 
		(other_class:Class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
	MATCH 
		(method)-[r:CALLS]-(other_method)
	WHERE  
		class <> other_class
	WITH 
		count(distinct r) as number_of_calls, 
		collect(distinct method.name) as method_names, 
		collect(distinct other_method.name) as other_method_names, 
		class, 
		other_class
	WHERE 
		number_of_calls > highNumberOfCallsBetweenClasses
	RETURN 
		class.app_key as app_key, 
		class.name as class_name, 
		other_class.name as other_class_name, 
		method_names, 
		other_method_names, 
		number_of_calls
  
##### Parameters  
Queries pairs of classes that have more method calls between them than a high number of calls between classes.

##### How are parameters determined
High number of calls between classes needs to be determined statistically using the box-plot technique. Currently set to 4.

##### Implementation details 
\-

##### References 
Def. from article "On the diffuseness and the impact on maintainability of code smells: a large scale empirical investigation".
Def: "All pairs of classes having a number of method’s calls between them higher than the average number of calls between all pairs of classes."

Fowler: "when a class knows too much of the internals of another class"

### Brain method

##### Query string

    MATCH 
    	(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
    MATCH 
    	(method)-[:USES]->(variable:Variable)
    WITH 
    	class, 
    	method, 
    	count(distinct variable) as number_of_variables, 
    	collect(distinct variable.name) as variable_names
    WHERE 
    	class.number_of_instructions > highNumberOfInstructionsForClass and 
    	method.cyclomatic_complexity >= highCyclomaticComplexity and 
    	method.max_nesting_depth >= severalMaximalNestingDepth and 
    	number_of_variables > manyAccessedVariables
    RETURN 
    	class.app_key as app_key,
    	class.name as class_name, 
    	method.name as method_name, 
    	method.cyclomatic_complexity as cyclomatic_complexity, 
    	method.max_nesting_depth as max_nesting_depth, 
    	number_of_variables, 
    	variable_names, 
    	class.data_string as main_text, 
    	method.data_string as affected_tex
  
##### Parameters  
Queries methods with high cyclomatic complexity, a max nesting depth of several, many accessed variables that belong to classes with high number of instructions. 

##### How are parameters determined
High number of instructions for class and high cyclomatic complexity should be determined statistically using the boxplot technique. Nesting depth of several is a generally accepted meaning threshold between 2 and 5 and many accessed variables is the short term memory capacity between 7 and 8. High number of instructions is currently set to 130, high cyclomatic complexity to 3.1, nesting depth of several to 3 and many accessed variables to 7.

##### Implementation details 
\-

##### References 
Def. from https://www.simpleorientedarchitecture.com/how-to-identify-brain-method-using-ndepend/.

### God class

##### Query string

   	MATCH 
   		(class:Class)-[:CLASS_OWNS_METHOD]->(method:Method)
   	MATCH 
   		(class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
   	WHERE 
   		method <> other_method
   	WITH 
   		count(DISTINCT [method, other_method]) as pair_count, 
   		class
   	MATCH 
   		(class)-[:CLASS_OWNS_METHOD]->(method:Method)
   	MATCH 
   		(class)-[:CLASS_OWNS_METHOD]->(other_method:Method)
   	MATCH 
   		(class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
   	WHERE 
   		method <> other_method and 
   		(method)-[:USES]->(variable)<-[:USES]-(other_method)
   	WITH 
   		class, 
   		pair_count, 
   		method, 
   		other_method, 
   		collect(distinct variable.name) as variable_names, 
   		count(distinct variable) as variable_count
    WHERE 
    	variable_count >= 1
    WITH 
    	class, 
    	pair_count, 
    	count(distinct [method, other_method]) as connected_method_count
    WITH 
    	class, 
    	connected_method_count*0.1/pair_count as class_cohesion, 
    	connected_method_count, 
    	pair_count
   	WHERE 
    	class_cohesion < tightClassCohesionFraction and
    	class.number_of_weighted_methods >= veryHighWeightedMethodCount
   	OPTIONAL MATCH 
   		(class)-[:CLASS_OWNS_METHOD]->(m:Method)-[:USES]
   			->(variable:Variable)<-[:CLASS_OWNS_VARIABLE]-(other_class:Class)
    WHERE class <> other_class
        with class, 
        class_cohesion, 
        connected_method_count, 
        pair_count, 
        count(distinct variable) as foreign_variable_count
    WHERE 
    	foreign_variable_count >= fewAccessToForeignData
    RETURN 
    	class.app_key as app_key, 
    	class.name as class_name, 
    	pair_count, 
    	connected_method_count, 
    	class_cohesion, 
    	class.number_of_weighted_methods as number_of_weighted_method, 
    	foreign_variable_count, 
    	class.data_string as main_text
  
##### Parameters  
Queries classes whose tight class cohesion is lower than 0.3, number of weighted mehtods is very high ad access to foreign data is at least view.

##### How are parameters determined
Fraction for tight class cohesion is set to 0.3. Very high number of weighted mehtods should be determined statistically using the box-plot technique. At least view access to foreign data variables is a generally accepted threshold 2-5.

##### Implementation details 
\-

##### References 
Def. from https://www.simpleorientedarchitecture.com/how-to-identify-god-class-using-ndepend/.

### SAP Breaker

##### Query string

    MATCH (class:Class)
    MATCH (other_class:Class)
    WHERE 
    	(other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()
    		<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class)
    WITH 
    	count(distinct other_class) as number_of_dependant_classes, class
    WITH 
    class, number_of_dependant_classes as efferent_coupling_number

    MATCH (class:Class)
    MATCH (other_class:Class)
    WHERE 
    	(class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()
    		<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class)
    WITH 
    	count(distinct other_class) as afferent_coupling_number, 
    	class, efferent_coupling_number
    WITH 
    	efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, 
    	class, 
    	afferent_coupling_number, 
    	efferent_coupling_number

    OPTIONAL MATCH 
    	(class)-[:CLASS_OWNS_METHOD]->(method:Method)
    WHERE 
    	method.is_abstract
    WITH 
    	count(distinct method)/class.number_of_methods as abstractness_number, 
    	instability_number, 
    	afferent_coupling_number, 
    	efferent_coupling_number, 
    	class
    WITH 
    	1 - (abstractness_number + instability_number)^2 as difference_from_main, 
    	instability_number, 
    	abstractness_number, 
    	class

    WHERE 
    	difference_from_main < - allowedDistanceFromMain or 
    	difference_from_main > allowedDistanceFromMain
    RETURN 
    	class.app_key as app_key, 
    	class.name as class_name, 
    	instability_number, 
    	abstractness_number, 
    	difference_from_main
  
##### Parameters  
Queries classes where class abstractness + instability is far from the 1-x mainline. AllowedDistanceFromMain is currently set to 0.5.

##### How are parameters determined


##### Implementation details 
\-

##### References 
More detailed def from https://javadepend.com/Blog/?p=585

From "understanding code smells in android applications": "Stable Abstraction Breaker is a subsystem (component) for which its stability level is not proportional with its abstractness. This design flaw is inspired by Robert Martin's stable abstractions principle, which states that for well-designed software there should be a specific relationship between two subsystem measures: the abstractness of a subsystem, which shall express the portion of contained abstract types, and its stability, which indicates whether the subsystem is mainly used by other client subsystems (stable) or if it mainly depends on other subsystems (unstable). For short, "a subsystem should be as abstract as it is stable". The problem with subsystems that are heavily used by other subsystems and at the same time are not abstract is that if they change (and they are likely to), potentially all clients must also change. This in turn leads to systems that are hard to maintain. [26 and 19] "


### SAP Breaker for Modules

##### Query string

    MATCH 
    	(module:Module)
    MATCH 
    	(module)-[:MODULE_OWNS_CLASS]->(class:Class)
    MATCH 
    	(other_module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
    WHERE 
    	(other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()
    		<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and 
    	module <> other_module
    WITH 
    	count(distinct other_class) as number_of_dependant_classes, 
    	module
    WITH 
    	module, 
    	number_of_dependant_classes as efferent_coupling_number

    MATCH 
    	(module:Module)-[:MODULE_OWNS_CLASS]->(class:Class)
    MATCH 
    	(other_module:Module)-[:MODULE_OWNS_CLASS]->(other_class:Class)
    WHERE 
    	(class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()
    		<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and 
    	module <> other_module
    WITH 
    	count(distinct other_class) as afferent_coupling_number, 
    	module, 
    	efferent_coupling_number
    WITH 
    	efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, 
    	afferent_coupling_number, 
    	efferent_coupling_number, 
    	module

    OPTIONAL MATCH 
    	(module)-[:MODULE_OWNS_CLASS]->(class:Class)
    WHERE 
    	class.is_interface
    WITH 
    	count(distinct class)/module.number_of_classes as abstractness_number, 
    	instability_number, 
    	afferent_coupling_number, 
    	efferent_coupling_number, 
    	module
    WITH 
    	1 - (abstractness_number + instability_number)^2 as difference_from_main, 
    	instability_number, 
    	abstractness_number, 
    	module

    WHERE 
    	difference_from_main < - allowedDistanceFromMain or 
    	difference_from_main > allowedDistanceFromMain
   	RETURN 
   		module.app_key as app_key, 
   		module.name as module_name, 
   		instability_number, 
   		abstractness_number, 
   		difference_from_main
  
##### Parameters  
Queries modules where module abstractness + instability is far from the 1-x mainline. AllowedDistanceFromMain is currently set to 0.5.

##### How are parameters determined


##### Implementation details 
\-

##### References 
More detailed def from https://javadepend.com/Blog/?p=585

From "understanding code smells in android applications": "Stable Abstraction Breaker is a subsystem (component) for which its stability level is not proportional with its abstractness. This design flaw is inspired by Robert Martin's stable abstractions principle, which states that for well-designed software there should be a specific relationship between two subsystem measures: the abstractness of a subsystem, which shall express the portion of contained abstract types, and its stability, which indicates whether the subsystem is mainly used by other client subsystems (stable) or if it mainly depends on other subsystems (unstable). For short, "a subsystem should be as abstract as it is stable". The problem with subsystems that are heavily used by other subsystems and at the same time are not abstract is that if they change (and they are likely to), potentially all clients must also change. This in turn leads to systems that are hard to maintain. [26 and 19] "
        

### Unstable dependencies

##### Query string

   	MATCH 
    	(class:Class)
   	MATCH 
   		(other_class:Class)
   	WHERE 
   		(other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()
   			<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and 
   		class <> other_class
   	WITH 
   		count(distinct other_class) as number_of_dependant_classes, 
   		class
   	WITH 
   		class, 
   		number_of_dependant_classes as efferent_coupling_number

   	MATCH 
   		(class:Class)
   	MATCH 
   		(other_class:Class)
   	WHERE 
   		(class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()
   			<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and 
   		class <> other_class
   	WITH 
   		count(distinct other_class) as afferent_coupling_number, 
   		class, 
   		efferent_coupling_number
   	WITH 
   		efferent_coupling_number*1.0/(efferent_coupling_number + afferent_coupling_number) as instability_number, 
   		class, 
   		afferent_coupling_number, 
   		efferent_coupling_number

   	MATCH 
   		(comparison_class:Class)
   	WHERE 
   		(comparison_class)-[:CLASS_OWNS_METHOD]->(:Method)-[:USES|:CALLS]->()
   			<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(class) and 
   		comparison_class <> class

   	MATCH 
   		(other_class:Class)
   	WHERE 
   		(other_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()
   			<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(comparison_class) and 
   		comparison_class <> other_class
   	WITH 
   		count(distinct other_class) as number_of_dependant_classes2, 
   		comparison_class, 
   		class, 
   		instability_number
   	WITH 
   		comparison_class, 
   		number_of_dependant_classes2 as efferent_coupling_number2, 
   		class, 
   		instability_number

   	MATCH 
   		(comparison_class:Class)
   	MATCH 
   		(other_class:Class)
   	WHERE 
   		(comparison_class)-[:CLASS_OWNS_METHOD]->()-[:USES|:CALLS]->()
   			<-[:CLASS_OWNS_METHOD|:CLASS_OWNS_VARIABLE]-(other_class) and 
   		comparison_class <> other_class
   	WITH 
   		count(distinct other_class) as afferent_coupling_number2, 
   		comparison_class, 
   		efferent_coupling_number2, 
   		class, 
   		instability_number
  	WITH 
  		efferent_coupling_number2*1.0/(efferent_coupling_number2 + afferent_coupling_number2) as 
  		instability_number2, 
  		comparison_class, 
  		afferent_coupling_number2, 
  		efferent_coupling_number2, 
  		class, 
  		instability_number
                
   	WHERE 
   		instability_number2 < instability_number

   	RETURN 
   		comparison_class.app_key as app_key, 
   		comparison_class.name as class_name, 
   		class.name as referenced_class_name, 
   		instability_number2 as instability_number, 
   		instability_number as referenced_instability_number
  
##### Parameters  
\-

##### How are parameters determined
\-

##### Implementation details 
\-

##### References 
From "Understanding code smells in Android applications": "Unstable Dependencies are violations of Robert Martin's Stable Dependencies Principle (SDP)[26]. The SDP affirms that "the dependencies between subsystems in a design should be in the direction of the stability of the subsystems. A subsystem should only depend upon subsystems that are more or at least as stable as it is". Stability is defined in terms of number of reasons to change and number of reasons not to change for a given subsystem. A subsystem that does not depend on many other subsystems but is depended upon by other subsystems, has few reasons to change and respectively many reasons not to change. [26]"

Used instability definition from here: https://javadepend.com/Blog/?p=585

### Primitive obsession

##### Query string

   	MATCH 
   		(class:Class)
   	MATCH 
   		(class)-[:CLASS_OWNS_VARIABLE]->(variable:Variable)
   	MATCH 
   		(method:Method)-[use:USES]->(variable)
   	WHERE 
   		not (variable)-[:IS_OF_TYPE]->()
   	WITH 
   		collect(distinct method.name) as uses, 
   		count(distinct method) as use_count, 
   		variable, 
   		class
   	WHERE 
   		use_count > primitiveVariableUsedTooManyTimes

  	RETURN 
  		class.app_key as app_key, 
  		class.name as class_name, 
  		variable.name as variable_name, 
  		variable.type as variable_type, 
  		uses, 
  		use_count, 
  		class.data_string as main_text, 
  		variable.data_string as affected_text
  
##### Parameters  
Queries variables whoese type is not a type defined in this application and that are used by multiple methods. 

##### How are parameters determined
primitiveVariableUsedTooManyTimes should probably be determined statistically. Currently set to 3. 

##### Implementation details 
\-

##### References 
def "Primitive Obsession. Primitive Obsession is the situation in which objects should have been used instead of primitives. It is further divided into three subcategories: Simple Primitive Obsession, Simple Type Code, and Complex Type Code [3]." from (https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=5680918)

def "Primitive types are building blocks; Overuse of this type can cause this smell" from (https://www.researchgate.net/profile/Sanjay_Misra2/publication/318435921_A_Systematic_Literature_Review_Code_Bad_Smells_in_Java_Source_Code/links/59ce24c4a6fdcce3b34b8531/A-Systematic-Literature-Review-Code-Bad-Smells-in-Java-Source-Code.pdf)

long blog post on primitive obsession (https://dzone.com/articles/code-quality-fighting-primitive-obsession-code-sme-1)

Our definition: 
  
  - none of the above provided an implementation
  - idea behind our implementation: we define as primitives all classes/structs that are not defined in our application
  - problem with this definition: a lot of these types are not really primitives, but they are not specifically defined for domain they are used in
  - just identifying all variables with such a types does not make sense, makes more sense to look for such variables that are also accessed often by methods

This literature review claims that primitive obsession cannot be detected with any tools in java (https://www.researchgate.net/profile/Sanjay_Misra2/publication/318435921_A_Systematic_Literature_Review_Code_Bad_Smells_in_Java_Source_Code/links/59ce24c4a6fdcce3b34b8531/A-Systematic-Literature-Review-Code-Bad-Smells-in-Java-Source-Code.pdf)
   
   - might mean that detection is not possible
   - or it has simply not yet been implemented
   - there has been a tool before that did it, but not available anymore