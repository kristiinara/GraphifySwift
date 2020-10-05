# DB Structure

## Variables and properties

### Variable	

* __app\_key__ - unique key to identify application
* __data\_string__ - snippet of code where given variable is defined 
* __is\_final__ - defines if variable is final
* __is\_static__ - defines if variable is static
* __modifier__ - private/public/internal/fileprivate/open
* __name__ - name of variable
* __type__ - type of variable, f.ex. String, [Int]?, App 
* __usr__ - unique identifier of variable inside app (provided by SourceKit)  

### Method

* __app\_key__ - unique key to identify application
* __cyclomatic\_complexity__ - cyclomatic complexity of method
* __data\_string__ - snippet of code where given method is defined 
* __full\_name__ - name of method (currently same as __name__)
* __is\_abstract__ - defines if method is abstract (in swift only methods in protocols are abstract)
* _is\_final_ - defines if method is final (not yet implemented)
* _is\_getter_ - defines if method is a getter method (not yet implemented)
* _is\_setter_ - defines if method is a setter method (not yet implemented)
* _is\_static_ - defines if method is static (not yet implemented)
* _is\_synchronized_ - defines if method is synchronized (not yet implemented)
* __max\_nesting\_depth__ - maximal nesting depth of if/else/while/for/etc in a method
* __max\_number\_of\_chaned\_message\_calls__ - maximal number of chained message calls, for example: test.values().findFirst().doSomething() is 3 chained message calls
* __modifier__ - modifier of method one of the following private/public/internal/fileprivate/open
* __name__ - name of method
* __number\_of\_callers__ - number of methods that call this method
* __number\_of\_declared\_locals__ - number of local variables declared inside method (currently includes method arguments -- should it?
* __number\_of\_direct\_calls__ - number of methods called from this method
* __number\_of\_instructions__ - number of instructions in method
* __number\_of\_parameters__ - number of parameters
* __number\_of\_switch\_statements__ - number of switch statements
* __return\_type__ - return type of function
* __usr__ - unique identifier of method inside this application

### Argument

* __app\_key__ - unique key to identify application
* __name__ - name of argument
* __position__ - position of argument
* __type__ - type of argument 

### App

* __app\_key__ - unique key to identify application
* __category__ - app category, information taken from .json file for bulk analysis
* _date\_download_ - date of download, not set correctly
* __developer__ - app developer, information taken from .json file for bulk analysis
* __in\_app\_store__ - specifies if app is in the app store, information taken from .json file for bulk analysis
* __language__ - currently either "swift" or "c++"
* __language\_mixed__ - set to true if there are other than "swift files" 
* __name__ - name of application, information taken from .json file for bulk analysis
* _nb\_download_ - number of downloads, currently not implemented
* __number\_of\_abstract\_classes__ - number of abstract classes, for swift projects set to 0 as there are no abstract classes
* __number\_of\_activities__ - number of viewControllers (used, so that Android results from Paprika and results from swift can be compared)
* __number\_of\_broadcast\_receivers__ - set to 0 for swift projects, Android specific
* __number\_of\_classes__ - number of classes, currently contains only classes (e.g. no structures)
* __number\_of\_content\_providers__ - set to 0 for swift projects, Android specific
* __number\_of\_extensions__ - number of extensions declared in app
* __number\_of\_interfaces__ - number of protocols (protocol in swift = interface in Java)
* __number\_of\_services__ - set to 0 for swift projects, Android specific
* __number\_of\_tests__ - number of tests in application, counted as number of asserts in all test files combined
* __number\_of\_ui\_tests__ - number of ui tests in application, counted as number of asserts in all test files in the UI tests folder
* _number\_of\_view\_controllers_ - number of viewControllers, currently not implemented
* _package_ - currently not implemented correctly, set as app name
* __platform__ - platform of app, currently for all swift apps set as "iOS"
* _price_ - price of app, not implemented correctly
* _rating_ - rating of app, not implemented correctly
* __size__ - app size, sum of sizes of all files in app
* __stars__ - number of app repository stars,  information taken from .json file for bulk analysis

### Class

* __app\_key__ - unique key to identify application
* __class\_complexity__ - class complexity, sum of all methods cyclomatic complexities
* __coupling\_between\_object\_classes__ - CBO represents the number of other classes a class is coupled to. This metrics is calculated from the callgraph and it counts the reference to methods, variables or types once for each class.
* __data\_string__ - source code of class
* __depth\_of\_inheritance__ - number of parents a class has
* __is\_abstract__ - set to false for swift classes, as they cannot be abstract
* __is\_activity__ - same as isViewController
* _is\_application_ - not implemented, should indicate if class is AppDelegate
* _is\_broadcast\_receiver_ - set to false, Android specific
* _is\_content\_provider_ - set to false, Android specific
* _is\_final_ - not yet implemented
* _is\_inner\_class_ - not yet implemented
* __is\_interface__ - specifies if class is a protocol (or interface in Java)
* _is\_service_ - set to false, Android specific
* _is\_static_ - not yet implemented
* _is\_view\_controller_ - not yet implemented
* __lack\_of\_cohesion\_in\_methods__ - lack of cohesion in methods is calculated as lackOfCohesionInMethods = noOfMethodsWith\_noVariableInCommon - noOfMethodsThat\_haveVariableInCommon or 0 if previous value is negative
* _modifier_ - not implemented
* __name__ - name of class
* __number\_of\_attributes__ - number of attributes in class
* __number\_of\_children__ - number of children class has
* __number\_of\_comments__ - number of comments
* __number\_of\_implemented\_interfaces__ - number of implemented interfaces
* __number\_of\_instructions__ - number of instructions
* __number\_of\_methods__ - number of methods
* __parent\_name__ - name of parent class
* __usr__ - unique identifier inside application

### Module

* __app\_key__ - unique key to identify application
* __name__ - name of module

## Relationships

* App	
   * APP\_OWNS\_MODULE	Module
* Argument 
   * IS\_OF\_TYPE	Class
* Class	
   * CLASS\_OWNS\_VARIABLE	Variable
   * CLASS\_OWNS\_METHOD	Method
   * DUPLICATES	Class _(i.e. some parts of the class are duplicated in the other class)_
   * IMPLEMENTS	Class
   * EXTENDS	Class
* Method	
   * USES	Variable
   * CALLS	Method
   * METHOD\_OWNS\_ARGUMENT	Argument
* Module	
   * MODULE\_OWNS\_CLASS	Class
* Variable	
   * IS\_OF\_TYPE	Class
