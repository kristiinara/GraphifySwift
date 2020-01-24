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
        self.checkPatternMatchFor(classes: drawing.classes)
        
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
    
    func checkPatternMatchFor(classes: [DrawableClassInstance]) {
        let checker = MVPChecker()
        for classInstance in classes {
            for connection in classInstance.connections {
                checker.checkAndUpdate(connection: connection)
            }
        }
    }
    
    func convertClassesIntoDrawable(app: App) -> [DrawableClassInstance] {
        var classes: [DrawableClassInstance] = []
        var classDictionary: [String: DrawableClassInstance] = [:]
        
        var allAppClasses = app.allClasses
        allAppClasses.append(contentsOf: app.protocols)
        allAppClasses.append(contentsOf: app.structures)
        
        for classInstance in app.allClasses {
            classInstance.setReverseRelationshipsToVariablesAndMethods()
            
            print("converting class: \(classInstance.name)")
            let drawableClass = DrawableClassInstance()
            drawableClass.name = classInstance.name as NSString
            
            classes.append(drawableClass)
            classDictionary[classInstance.name] = drawableClass
            
            drawableClass.parentNames = classInstance.inheritedTypes
            if drawableClass.parentNames.count == 0 {
                drawableClass.parentNames = [classInstance.parentName]
            }
            
            print("inheritedTypes: \(classInstance.inheritedTypes)")
            print("parentName: \(classInstance.parentName)")
            print("inheritedClasses: \(classInstance.inheritedClasses)")
            print("parentUsrs: \(classInstance.parentUsrs)")
            
            //TODO: make this better. Current implementation VERY simplistic.
            //TODO: implement checking if parent of class belongs to UIKit
            //TODO: add parent of class to drawing
            
            if ClassDetectionUtility.isViewClass(classInstance: drawableClass) {
                drawableClass.type = .view
            } else if classInstance.name.contains("ViewModel") {
                drawableClass.type = .controller
            } else if classInstance.name.contains("Controller") || classInstance.name.contains("Presenter") {
                drawableClass.type = .controller
            } else if classInstance.name.contains("View") {
                drawableClass.type = .view
            } else if classInstance.name.contains("AppDelegate") {
                drawableClass.type = .undefined
            } else {
                drawableClass.type = .model
            }
            
            if let _ = classInstance as? ClassInstance {
                drawableClass.classType = .classType
            } else if let _ = classInstance as? Struct {
                drawableClass.classType = .structType
            } else if let _ = classInstance as? Protocol {
                drawableClass.classType = .protocolType
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
                        //drawableClass.singleConnections.append(connectedClass)
                        let connection = DrawableConnection(fromClass: drawableClass, toClass: connectedClass)
                        drawableClass.connections.append(connection)
                        
                        typeFound = true
                        //print("\(drawableClass.name) connections: \(drawableClass.singleConnections)")
                    }
                    
                    if typeFound == false {
                        //TODO: also detect dictionaries etc.
                        type = type.replacingOccurrences(of: "[", with: "")
                        type = type.replacingOccurrences(of: "]", with: "")
                        
                        if let connectedClass = classDictionary[type] {
                            //drawableClass.multiConnections.append(connectedClass)
                            let connection = DrawableConnection(fromClass: drawableClass, toClass: connectedClass)
                            drawableClass.connections.append(connection)
                            
                            typeFound = true
                            //print("\(drawableClass.name) connections: \(drawableClass.multiConnections)")
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
                                //drawableClass.calls.append(calledClass)
                                let connection = DrawableConnection(fromClass: drawableClass, toClass: calledClass)
                                drawableClass.connections.append(connection)
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
                                //drawableClass.uses.append(calledClass)
                                let connection = DrawableConnection(fromClass: drawableClass, toClass: calledClass)
                                drawableClass.connections.append(connection)
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
    var classType: ClassType = .undefined
    var parentNames: [String] = []
    var parents: [DrawableClassInstance] = []
    
//    var singleConnections: [DrawableClassInstance] = []
//    var multiConnections: [DrawableClassInstance] = []
//    var calls: [DrawableClassInstance] = []
//    var uses: [DrawableClassInstance] = []
    
    var connections: [DrawableConnection] = []
    
    var x: CGFloat = 10
    var y: CGFloat = 10
    var rect: CGRect?
    var nameRect: CGRect?
    var variableRect: CGRect?
}

enum DrawableType {
    case view, model, controller, undefined
}

enum ClassType {
    case classType, structType, protocolType, undefined
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
//            for connectedClass in classInstance.singleConnections {
//                context.setStrokeColor(.black)
//                self.drawConnection(context: context, startClass: classInstance, endClass: connectedClass, offset: 0)
//            }
//
//            for connectedClass in classInstance.multiConnections {
//                context.setStrokeColor(NSColor.blue.cgColor)
//                self.drawConnection(context: context, startClass: classInstance, endClass: connectedClass, offset: 2)
//            }
//
//            for calledClass in classInstance.calls {
//                context.setStrokeColor(NSColor.red.cgColor)
//                self.drawConnection(context: context, startClass: classInstance, endClass: calledClass, offset: 4)
//            }
//
//            for usedVariable in classInstance.uses {
//                context.setStrokeColor(NSColor.orange.cgColor)
//                self.drawConnection(context: context, startClass: classInstance, endClass: usedVariable, offset: 6)
//            }
            
            var offset: CGFloat = 0
            for connection in classInstance.connections {
                context.setStrokeColor(connection.color)
                self.drawConnection(context: context, startClass: connection.fromClass, endClass: connection.toClass, offset: offset)
                offset += 1
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
            
            if classInstance.classType == .classType || classInstance.classType == .structType {
                context.setFillColor(.white)
            } else {
                context.setFillColor(NSColor.yellow.cgColor)
            }
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

class ClassDetectionUtility {
    static func isViewClass(classInstance: DrawableClassInstance) -> Bool {
        for parentName in classInstance.parentNames {
            if viewClasses.contains(parentName) {
                return true
            }
        }
        return false
    }
    
    // went to /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/UIKit.framework/Headers
    // got list of files, removed file endings, added quotes
    //TODO: make this automatic, when we specify a framework
    static let viewClasses = ["DocumentManager", "NSAttributedString", "NSDataAsset", "NSFileProviderExtension", "NSIndexPath+UIKitAdditions", "NSItemProvider+UIKitAdditions", "NSLayoutAnchor", "NSLayoutConstraint", "NSLayoutManager", "NSParagraphStyle", "NSShadow", "NSStringDrawing", "NSText", "NSTextAttachment", "NSTextContainer", "NSTextStorage", "UIAccelerometer", "UIAccessibility", "UIAccessibilityAdditions", "UIAccessibilityConstants", "UIAccessibilityContainer", "UIAccessibilityContentSizeCategoryImageAdjusting", "UIAccessibilityCustomAction", "UIAccessibilityCustomRotor", "UIAccessibilityElement", "UIAccessibilityIdentification", "UIAccessibilityLocationDescriptor", "UIAccessibilityZoom", "UIActionSheet", "UIActivity", "UIActivityIndicatorView", "UIActivityItemProvider", "UIActivityViewController", "UIAlert", "UIAlertController", "UIAlertView", "UIAppearance", "UIApplication", "UIApplicationShortcutItem", "UIAttachmentBehavior", "UIBarButtonItem", "UIBarButtonItemGroup", "UIBarCommon", "UIBarItem", "UIBezierPath", "UIBlurEffect", "UIButton", "UICloudSharingController", "UICollectionView", "UICollectionViewCell", "UICollectionViewController", "UICollectionViewFlowLayout", "UICollectionViewLayout", "UICollectionViewTransitionLayout", "UICollisionBehavior", "UIColor", "UIContentSizeCategory", "UIContentSizeCategoryAdjusting", "UIContextualAction", "UIControl", "UIDataDetectors", "UIDataSourceTranslating", "UIDatePicker", "UIDevice", "UIDocument", "UIDocumentBrowserAction", "UIDocumentBrowserViewController", "UIDocumentInteractionController", "UIDocumentMenuViewController", "UIDocumentPickerExtensionViewController", "UIDocumentPickerViewController", "UIDragInteraction", "UIDragItem", "UIDragPreview", "UIDragPreviewParameters", "UIDragSession", "UIDropInteraction", "UIDynamicAnimator", "UIDynamicBehavior", "UIDynamicItemBehavior", "UIEvent", "UIFeedbackGenerator", "UIFieldBehavior", "UIFocus", "UIFocusAnimationCoordinator", "UIFocusDebugger", "UIFocusGuide", "UIFocusMovementHint", "UIFocusSystem", "UIFont", "UIFontDescriptor", "UIFontMetrics", "UIGeometry", "UIGestureRecognizer", "UIGestureRecognizerSubclass", "UIGraphics", "UIGraphicsImageRenderer", "UIGraphicsPDFRenderer", "UIGraphicsRenderer", "UIGraphicsRendererSubclass", "UIGravityBehavior", "UIGuidedAccess", "UIGuidedAccessRestrictions", "UIImage", "UIImageAsset", "UIImagePickerController", "UIImageView", "UIImpactFeedbackGenerator", "UIInputView", "UIInputViewController", "UIInteraction", "UIInterface", "UIKit.apinotes", "UIKit", "UIKitCore", "UIKitDefines", "UILabel", "UILayoutGuide", "UILexicon", "UILocalNotification", "UILocalizedIndexedCollation", "UILongPressGestureRecognizer", "UIManagedDocument", "UIMenuController", "UIMotionEffect", "UINavigationBar", "UINavigationController", "UINavigationItem", "UINib", "UINibDeclarations", "UINibLoading", "UINotificationFeedbackGenerator", "UIPageControl", "UIPageViewController", "UIPanGestureRecognizer", "UIPasteConfiguration", "UIPasteConfigurationSupporting", "UIPasteboard", "UIPencilInteraction", "UIPickerView", "UIPinchGestureRecognizer", "UIPopoverBackgroundView", "UIPopoverController", "UIPopoverPresentationController", "UIPopoverSupport", "UIPresentationController", "UIPress", "UIPressesEvent", "UIPreviewInteraction", "UIPrintError", "UIPrintFormatter", "UIPrintInfo", "UIPrintInteractionController", "UIPrintPageRenderer", "UIPrintPaper", "UIPrinter", "UIPrinterPickerController", "UIProgressView", "UIPushBehavior", "UIReferenceLibraryViewController", "UIRefreshControl", "UIRegion", "UIResponder", "UIRotationGestureRecognizer", "UIScreen", "UIScreenEdgePanGestureRecognizer", "UIScreenMode", "UIScrollView", "UISearchBar", "UISearchContainerViewController", "UISearchController", "UISearchDisplayController", "UISegmentedControl", "UISelectionFeedbackGenerator", "UISlider", "UISnapBehavior", "UISplitViewController", "UISpringLoadedInteraction", "UISpringLoadedInteractionSupporting", "UIStackView", "UIStateRestoration", "UIStepper", "UIStoryboard", "UIStoryboardPopoverSegue", "UIStoryboardSegue", "UIStringDrawing", "UISwipeActionsConfiguration", "UISwipeGestureRecognizer", "UISwitch", "UITabBar", "UITabBarController", "UITabBarItem", "UITableView", "UITableViewCell", "UITableViewController", "UITableViewHeaderFooterView", "UITapGestureRecognizer", "UITargetedDragPreview", "UITextChecker", "UITextDragPreviewRenderer", "UITextDragURLPreviews", "UITextDragging", "UITextDropProposal", "UITextDropping", "UITextField", "UITextInput", "UITextInputTraits", "UITextItemInteraction", "UITextPasteConfigurationSupporting", "UITextPasteDelegate", "UITextView", "UITimingCurveProvider", "UITimingParameters", "UIToolbar", "UITouch", "UITraitCollection", "UIUserActivity", "UIUserNotificationSettings", "UIVibrancyEffect", "UIVideoEditorController", "UIView", "UIViewAnimating", "UIViewController", "UIViewControllerTransitionCoordinator", "UIViewControllerTransitioning", "UIViewPropertyAnimator", "UIVisualEffect", "UIVisualEffectView", "UIWebView", "UIWindow"]
}

protocol PatternChecker {
    func checkAndUpdate(connection: DrawableConnection)
    var allowedConnections: [DrawableType: [DrawableType]] { get }
    
}

extension PatternChecker {
    func checkAndUpdate(connection: DrawableConnection) {
        let fromClassType = connection.fromClass.type
        let toClassType = connection.toClass.type
        
        if let allowedTypes = self.allowedConnections[fromClassType] {
            print("fromType: \(fromClassType), toType: \(toClassType)")
            if allowedTypes.contains(toClassType) {
                connection.color = NSColor.green.cgColor
            } else {
                connection.color = NSColor.red.cgColor
            }
        }
    }
}

class MVPChecker: PatternChecker {
    //First simplistic definition
    var allowedConnections: [DrawableType : [DrawableType]] = [
        .view: [.view, .controller],
        .model: [.controller, .model],
        .controller: [.view, .model, .controller]
    ]
}

class DrawableConnection {
    let fromClass: DrawableClassInstance
    let toClass: DrawableClassInstance
    
    var color: CGColor = .black
    
    init(fromClass: DrawableClassInstance, toClass: DrawableClassInstance) {
        self.fromClass = fromClass
        self.toClass = toClass
    }
}
