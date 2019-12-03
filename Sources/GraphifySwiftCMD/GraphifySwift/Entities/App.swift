//
//  App.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 04/04/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

//import Foundation

class App : Kind {
    var id: Int?
    var name: String
//    var classes: [ClassInstance] = []
//    var structures: [Struct] = []
//    var protocols: [Protocol] = []
    
    var language: String
    var languageMixed: Bool
    var platform: String
    
    var numberOfExtensions: Int = 0
    var modules: [Module] = []
    var duplicates: [Duplication] = []
    
    var classes: [ClassInstance] {
        var allClasses: [ClassInstance] = []
        
        for module in self.modules {
            allClasses.append(contentsOf: module.classes)
        }
        
        return allClasses
    }
    
    var structures: [Struct] {
        var allStructs: [Struct] = []
        
        for module in self.modules {
            allStructs.append(contentsOf: module.structures)
        }
        
        return allStructs
    }
    
    var protocols: [Protocol] {
        var allProtocols: [Protocol] = []
        
        for module in self.modules {
            allProtocols.append(contentsOf: module.protocols)
        }
        
        return allProtocols
    }
    
    //Variables that are automatically incremented
    //Can calculate when initiating new app:
    var numberOfInterfaces : Int {
        return self.protocols.count
    }
    
    var numberOfAbstractClasses = 0 // Java specific. No abstract classes in swift!
    var numberOfInnerClasses : Int {
        let innerClasses = self.classes.filter() { classInstance in
            return classInstance.isInnerClass
        }
        
        let innerStructs = self.structures.filter() { classInstance in
            return classInstance.isInnerClass
        }
        
        return innerClasses.count + innerStructs.count
    }
    
    //Variables that we will calculate in the future
    var numberOfActivities : Int {
        return numberOfViewControllers
    }
    
    var numberOfViewControllers : Int {
        let viewControllers = self.classes.filter() { classInstance in
            return classInstance.isViewController
        }
        return viewControllers.count
    }
    
    var numberOfBroadcastReceivers = 0 //Android specific? --> replace with notificationCenter?
    var numberOfServices = 0 //Android specific --> background stuff, could replece with code executing in background
    
    //TODO: implement numberOfAsyncTasks
    var numberOfAsyncTasks = 0 // Count how many times things are done in async
    var numberOfViews: Int { //Number of views in the app
        //TODO: Determine real number of views, currently returning number of viewControllers
        return self.numberOfViewControllers
    }
    
    //Android specific only
    var numberOfContentProviders = 0 //Android specific
    
    //var dateAnalysis = 0 //seems that PAPRIKA will set it when analysing
    
    //Variables that we should get as input
    var targetSdk: String // input from user! (target sdk verion, extract from manifest)
    var dateDownload: String // input from user! (date of download)
    var package: String //get as input! (application main package)
    var versionCode: Int // get as input! (version code of the application, extract from manifest)
    var versionName: String // input from user! (version name of the applicaiton, extract from manifest)
    var appKey: String // input from user! (sha256 of the apk used as identifier, has to be )
    var developer: String // input from user! (application developer)
    var sdk: String// input from user! (sdk verion, extract from manifest)
    var category: String // input from user! (application category)
        //possible values:
        //APP_WALLPAPER, BOOKS_AND_REFERENCE, BUSINESS, COMICS, COMMUNICATION, EDUCATION, ENTERTAINMENT, FINANCE, GAME, HEALTH_AND_FITNESS, LIBRARIES_AND_DEMO, LIFESTYLE, MEDIA_AND_VIDEO, MEDICAL, MUSIC_AND_AUDIO, NEWS_AND_MAGAZINES, PERSONALIZATION, PHOTOGRAPHY, PRODUCTIVITY, SHOPPING, SOCIAL, SPORTS, TOOLS, TRANSPORTATION, TRAVEL_AND_LOCAL, WEATHER.
    
    //Variables we should get from appStore
    var rating = 0 //rating from appStore? but as input to program! (application rating)
    var nbDownload = "" //from appStore? but as input to program! (number of downloads for the app)
    var price = "" //from appStore? but as input to program! (price of the application)
    
    //We still have to figure out:
    var size = 0 //APK size in bytes --> setting it after going through files (adding up size of each file)
    
    var stars: Int = 0
    
    var inAppStore = false
    //Obscure variables?
    //let numberOfArgb8888 = 0 // what is this? argb8888 means alpha, red, green, blue 32bit
    
    init(name: String, targetSdk: String, dateDownload: String, package: String, versionCode: Int, versionName: String, appKey: String, developer: String, sdk: String, categroy: String, language: String, languageMixed: Bool, platform: String) {
        self.name = name
        self.targetSdk = targetSdk
        self.dateDownload = dateDownload
        self.package = package
        self.versionCode = versionCode
        self.versionName = versionName
        self.appKey = appKey
        self.developer = developer
        self.sdk = sdk
        self.category = categroy
        
        self.language = language
        self.languageMixed = languageMixed
        self.platform = platform
    }
    
    var numberOfClasses: Int {
        return classes.count
    }
    
    var numberOfStructs: Int {
        return structures.count
    }
    
    var numberOfMethods: Int {
        var methodsCount = 0
        
        for classInstance in classes {
            methodsCount += classInstance.classMethods.count + classInstance.instanceMethods.count
        }
        
        for structInstance in structures {
            methodsCount += structInstance.instanceMethods.count
        }
        
        return methodsCount
    }
    
    var numberOfVariables: Int {
        var variablesCount = 0
        
        for classInstance in classes {
            variablesCount += classInstance.instanceVariables.count
        }
        
        for structInstance in structures {
            variablesCount += structInstance.instanceVariables.count
        }
        return variablesCount
    }
    
    var description: String {
        return """
        Struct: \(name)
        """
    }
    
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
    
    var allClasses: [Class] {
        var classes: [Class] = []
        classes.append(contentsOf: self.classes)
        classes.append(contentsOf: self.structures)
        classes.append(contentsOf: self.protocols)
        
        return classes
    }
    
    var numberOfTests = 0
    var numberOfUITests = 0
}

extension App: Node4jInsertable {
    var nodeName: String {
        return "App"
    }
    
    var properties: String {
        return """
        {
        name:'\(self.name)',
        app_key:'\(self.appKey)',
        rating:\(self.rating),
        date_download:'\(self.dateDownload)',
        package:'\(self.package)',
        size:\(self.size),
        developer:'\(self.developer)',
        category:'\(self.category)',
        price:'\(self.price)',
        nb_download:'\(self.nbDownload)',
        number_of_classes:\(self.numberOfClasses),
        number_of_interfaces:\(self.numberOfInterfaces),
        number_of_abstract_classes:\(self.numberOfAbstractClasses),
        number_of_activities:\(self.numberOfActivities),
        number_of_view_controllers:\(self.numberOfViewControllers),
        number_of_broadcast_receivers:\(self.numberOfBroadcastReceivers),
        number_of_content_providers:\(self.numberOfContentProviders),
        number_of_services:\(self.numberOfServices),
        language:'\(self.language)',
        language_mixed:\(self.languageMixed),
        stars:\(self.stars),
        platform:'\(self.platform)',
        number_of_extensions:\(self.numberOfExtensions),
        in_app_store:\(self.inAppStore),
        number_of_tests:\(self.numberOfTests),
        number_of_ui_tests:\(self.numberOfUITests)
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
    
    func ownsModuleQuery(_ someModule: Module) -> String? {
        if let appId = self.id, let moduleId = someModule.id {
            return "match (a:App), (c:Module) where id(a) = \(appId) and id(c) = \(moduleId) create (a)-[r:APP_OWNS_MODULE]->(c) return id(r)"
        }
        return nil
    }
    
//    func ownsClassQuery(_ someClass: Class) -> String? {
//        if let appId = self.id, let classId = someClass.id {
//            return "match (a:App), (c:Class) where id(a) = \(appId) and id(c) = \(classId) create (a)-[r:APP_OWNS_CLASS]->(c) return id(r)"
//        }
//        return nil
//    }
//
//    func ownsStructQuery(_ someStruct: Struct) -> String? {
//        if let appId = self.id, let structId = someStruct.id {
//            return "match (a:App), (c:Struct) where id(a) = \(appId) and id(c) = \(structId) create (a)-[r:APP_OWNS_CLASS]->(c) return id(r)"
//        }
//        return nil
//    }
}
