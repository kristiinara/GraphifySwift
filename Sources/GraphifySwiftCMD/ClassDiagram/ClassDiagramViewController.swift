//
//  ClassDiagramViewController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 20/09/2019.
//

import Foundation
import Cocoa

class ClassDiagramViewController: NSViewController {
    var app: App
    var frame: NSRect
    
    override func loadView() {
        self.view = NSView(frame: frame)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.blue.cgColor
    }
    
    init(app: App, frame: NSRect) {
        self.app = app
        self.frame = frame
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init coder not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        let frame = self.view.frame
        let drawing = Drawing(frame: frame)
        
        drawing.classes = convertClassesIntoDrawable(app: self.app)
        
        self.view.addSubview(drawing)
        
        if #available(OSX 10.11, *) {
            drawing.translatesAutoresizingMaskIntoConstraints = false
            drawing.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            drawing.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            drawing.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            drawing.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        } else {
            // Fallback on earlier versions
        }
    }
    
    func convertClassesIntoDrawable(app: App) -> [DrawableClassInstance] {
        var classes: [DrawableClassInstance] = []
        var classDictionary: [String: DrawableClassInstance] = [:]
        
        for classInstance in app.allClasses {
            classInstance.setReverseRelationshipsToVariablesAndMethods()
            
            print("converting class: \(classInstance.name)")
            let drawableClass = DrawableClassInstance()
            drawableClass.name = classInstance.name as NSString
            
            classes.append(drawableClass)
            classDictionary[classInstance.name] = drawableClass
            
            //TODO: make this better. Current implementation VERY simplistic.
            if classInstance.name.contains("ViewModel") {
                drawableClass.type = .controller
            } else if classInstance.name.contains("View") ||  classInstance.name.contains("Cell") {
                drawableClass.type = .view
            } else if classInstance.name.contains("Controller") || classInstance.name.contains("Presenter") {
                drawableClass.type = .controller
            } else if classInstance.name.contains("AppDelegate") {
                drawableClass.type = .undefined
            } else {
                drawableClass.type = .model
            }
        }
        
        for classInstance in app.allClasses {
            if let drawableClass = classDictionary[classInstance.name] {
                let variables = classInstance.allVariables
                let methods = classInstance.allMethods
                
                var drawableVariables: [NSString] = []
                
                for variable in variables {
                    var type = variable.type
                    type = type.replacingOccurrences(of: "?", with: "")
                    type = type.replacingOccurrences(of: "!", with: "")
                    print("type: \(type)")
                    
                    var typeFound = false
                    if let connectedClass = classDictionary[type] {
                        drawableClass.singleConnections.append(connectedClass)
                        
                        typeFound = true
                        print("\(drawableClass.name) connections: \(drawableClass.singleConnections)")
                    }
                    
                    if typeFound == false {
                        //TODO: also detect dictionaries etc.
                        type = type.replacingOccurrences(of: "[", with: "")
                        type = type.replacingOccurrences(of: "]", with: "")
                        
                        if let connectedClass = classDictionary[type] {
                            drawableClass.multiConnections.append(connectedClass)
                            
                            typeFound = true
                            print("\(drawableClass.name) connections: \(drawableClass.multiConnections)")
                        }
                    }
                    
                    if typeFound == false {
                        drawableVariables.append(variable.name as NSString)
                    }
                }
                
                for method in methods {
                    print("Number of calledMethods: \(method.referencedMethods.count)")
                    for calledMethod in method.referencedMethods {
                        if let parentClass = calledMethod.classInstance {
                            if let calledClass = classDictionary[parentClass.name] {
                                print("called class: \(parentClass.name)")
                                drawableClass.calls.append(calledClass)
                            } else {
                                print("called class \(parentClass.name) not found")
                            }
                        } else {
                            print("No parent for: \(calledMethod.name)")
                        }
                    }
                    
                    for usedVariable in method.referencedVariables {
                        if let parentClass = usedVariable.classInstance {
                            if let calledClass = classDictionary[parentClass.name] {
                                drawableClass.uses.append(calledClass)
                            }
                        } else {
                            print("No parent for: \(usedVariable.name)")
                        }
                    }
                }
                
                drawableClass.variables = drawableVariables
                drawableClass.methods = classInstance.allMethods.map() { method in return method.name as NSString }
            }
        }
        print("classDictionary: \(classDictionary)")
        
        return classes
    }
}

class DrawableClassInstance {
    var name: NSString = ""
    var variables: [NSString] = []
    var methods: [NSString] = []
    var type: DrawableType = .undefined
    var singleConnections: [DrawableClassInstance] = []
    var multiConnections: [DrawableClassInstance] = []
    var calls: [DrawableClassInstance] = []
    var uses: [DrawableClassInstance] = []
    
    var x: CGFloat = 10
    var y: CGFloat = 10
    var rect: CGRect?
    var nameRect: CGRect?
    var variableRect: CGRect?
}

enum DrawableType {
    case view, model, controller, undefined
}


class Drawing: NSView {
    var textHeight: CGFloat = 20
    var classes: [DrawableClassInstance] = []
    
    let width: CGFloat = 100
    let minBoundary: CGFloat = 10
    
    var modelColor: CGColor = NSColor.blue.cgColor
    var viewColor: CGColor = NSColor.green.cgColor
    var controllerColor: CGColor = NSColor.darkGray.cgColor
    
    func layoutClasses() {
        let modelClasses = classes.filter() { classInstance in return classInstance.type == .model }
        let viewClasses = classes.filter() { classInstance in return classInstance.type == .view }
        let controllerClasses = classes.filter() { classInstance in return classInstance.type == .controller }
        let undefinedClasses = classes.filter() { classInstance in return classInstance.type == .undefined }
        
        let verticalBoundary = self.frame.size.height/2
        let horizontalBoundary = self.frame.size.width/2
        
        let numberOfModels = modelClasses.count
        let numberOfViews = viewClasses.count
        let numberOfControllers = controllerClasses.count
        
        var viewStart = horizontalBoundary - CGFloat(numberOfViews)*(width+minBoundary)
        if viewStart < 0 {
            viewStart = 0
        } else {
            viewStart = viewStart/2
        }
        
        var controllerStart = self.frame.size.width - CGFloat(numberOfControllers)*(width+minBoundary)
        if controllerStart < 0 {
            controllerStart = 0
        } else {
            controllerStart = controllerStart/2
        }
        
        var modelStart = horizontalBoundary - CGFloat(numberOfModels)*(width+minBoundary)
        if modelStart < 0 {
            modelStart = self.frame.size.width - CGFloat(numberOfModels)*(width+minBoundary)
        } else {
            modelStart = horizontalBoundary + modelStart/2
        }
        
        if modelStart < 0 {
            modelStart = 0
        }
        
        var count = 0
        for classInstance in modelClasses {
            classInstance.x = CGFloat(count)*(minBoundary + width) + modelStart
            classInstance.y = minBoundary
            print("\(classInstance.name) x:\(classInstance.x) y:\(classInstance.y)")
            count += 1
        }
        
        count = 0
        for classInstance in viewClasses {
            classInstance.x = CGFloat(count)*(minBoundary + width) + viewStart
            classInstance.y = minBoundary
            print("\(classInstance.name) x:\(classInstance.x) y:\(classInstance.y)")
            count += 1
        }
        
        count = 0
        for classInstance in controllerClasses {
            classInstance.x = CGFloat(count)*(minBoundary + width) + controllerStart
            classInstance.y = verticalBoundary + minBoundary
            print("\(classInstance.name) x:\(classInstance.x) y:\(classInstance.y)")
            count += 1
        }
        
        count = 0
        let undefinedStart = minBoundary
        for classInstance in undefinedClasses {
            classInstance.x = CGFloat(count)*(minBoundary + width) + undefinedStart
            classInstance.y = verticalBoundary + minBoundary
        }
    }
    
    func drawConnections(context: CGContext) {
        for classInstance in classes {
            for connectedClass in classInstance.singleConnections {
                context.setStrokeColor(.black)
                self.drawConnection(context: context, startClass: classInstance, endClass: connectedClass, offset: 0)
            }
            
            for connectedClass in classInstance.multiConnections {
                context.setStrokeColor(NSColor.blue.cgColor)
                self.drawConnection(context: context, startClass: classInstance, endClass: connectedClass, offset: 2)
            }
            
            for calledClass in classInstance.calls {
                context.setStrokeColor(NSColor.red.cgColor)
                self.drawConnection(context: context, startClass: classInstance, endClass: calledClass, offset: 4)
            }
            
            for usedVariable in classInstance.uses {
                context.setStrokeColor(NSColor.orange.cgColor)
                self.drawConnection(context: context, startClass: classInstance, endClass: usedVariable, offset: 6)
            }
        }
    }
    
    func drawConnection(context: CGContext, startClass: DrawableClassInstance, endClass: DrawableClassInstance, offset: CGFloat) {
        if let startRect = startClass.rect, let endRect = endClass.rect {
            context.beginPath()
            let startingPoint = CGPoint(x: startRect.midX + offset, y: startRect.midY + offset)
            let endingPoint = CGPoint(x: endRect.midX + offset, y: endRect.midY + offset)
            
            context.move(to: startingPoint)
            context.addLine(to: endingPoint)
            context.strokePath()
        }
    }
    
    func drawClasses(context: CGContext) {
        for classInstance in self.classes {
            var color: CGColor = .black
            
            //TODO: probably move this elsewhere
            if classInstance.type == .controller {
                color = controllerColor
            } else if classInstance.type == .model {
                color = modelColor
            } else if classInstance.type == .view {
                color = viewColor
            }
            
            context.setFillColor(.white)
            context.fill(classInstance.rect!)
            
            context.beginPath()
            context.setStrokeColor(color)
            
            context.addRect(classInstance.rect!)
            context.addRect(classInstance.nameRect!)
            context.addRect(classInstance.variableRect!)
            
            context.strokePath()
            
            let name = classInstance.name as NSString
            name.draw(in: classInstance.nameRect!, withAttributes: nil)
            
            let x = classInstance.x
            let y = classInstance.y
            
            let titleHeight = classInstance.nameRect!.size.height
            let variablesHeight = classInstance.variableRect!.size.height
            let height = classInstance.rect!.size.height
            
            var index: CGFloat = 1
            for variable in classInstance.variables {
                let rect = CGRect(origin: CGPoint(x: x, y: y+height - titleHeight - index * textHeight), size: CGSize(width: width, height: textHeight))
                variable.draw(in: rect, withAttributes: nil)
                index += 1
            }
            
            index = 1
            for method in classInstance.methods {
                let rect = CGRect(origin: CGPoint(x: x, y: y+height - titleHeight - variablesHeight - index * textHeight), size: CGSize(width: width, height: textHeight))
                method.draw(in: rect, withAttributes: nil)
                index += 1
            }
        }
    }
    
    //TODO: make it nicer, but works
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.layoutClasses()
        
        if let context = NSGraphicsContext.current?.cgContext {
            
            context.setFillColor(.init(gray: 0.5, alpha: 1))
            context.fill(dirtyRect)
            
            for classInstance in self.classes {
                let x = classInstance.x
                let y = classInstance.y
                
                let variables: [NSString] = classInstance.variables
                let methods: [NSString] = classInstance.methods
                
                let methodsHeight = CGFloat(methods.count) * textHeight
                let variablesHeight = CGFloat(variables.count) * textHeight
                let titleHeight = textHeight
                
                let height = titleHeight + variablesHeight + methodsHeight
                
                let rectangle = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
                let nameRectangle = CGRect(origin: CGPoint(x: x, y: y + height - titleHeight), size: CGSize(width: width, height: titleHeight))
                let variableRectangle = CGRect(origin: CGPoint(x: x, y: y + height - titleHeight - variablesHeight), size: CGSize(width: width, height: variablesHeight))
                
                classInstance.rect = rectangle
                classInstance.nameRect = nameRectangle
                classInstance.variableRect = variableRectangle
            }
            self.drawConnections(context: context)
            self.drawClasses(context: context)
        }
    }
}
