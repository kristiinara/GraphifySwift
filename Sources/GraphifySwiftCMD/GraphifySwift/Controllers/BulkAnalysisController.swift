//
//  BulkAnalysisController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 11/11/2019.
//

import Foundation

class BulkAnalysisController {
    let inputFileURL: URL
    let outputFolderURL: URL
    
    var projectQueue: [Project] = []
    var allProjects: [Project] = []
    
    var counProjectsAnalysed = 0
    
    var shouldRunGitClone = false
    let dispatchGroup = DispatchGroup()
    
    let outputFileName: String
    let outputFileURL: URL
    
    let dateString: String
    
    let dataSyncController = DataSyncController()
    
    var analysisResults: [String: (Project, Bool)] = [:]
    
    init(inputFileURL: URL, outputFolderURL: URL) {
        self.inputFileURL = inputFileURL
        self.outputFolderURL = outputFolderURL
        
        self.outputFileName = "analysedApplications.json"
        self.outputFileURL = self.outputFolderURL.appendingPathComponent(outputFileName)
        
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = Date()
        self.dateString = dateFormatter.string(from: date)
                   
    }
    
    func analyse() {
        let success = parseInputFile()
        print("succes? \(success)")
        let numberOfAllProjects = allProjects.count
        let numberOfProjects = projectQueue.count
        
        self.analyseNext()

        print("Number of all projects: \(numberOfAllProjects) projects")
        print("Analysed \(numberOfProjects) projects")
        //Do some output stuff?

        dispatchGroup.notify(queue: DispatchQueue.main) {
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
    
    func parseInputFile() -> Bool {
        
        var data: Data?
        do {
            data = try Data(contentsOf: inputFileURL, options: .mappedIfSafe)
        } catch let error {
            print("Error readind file \(inputFileURL) - \(error.localizedDescription)")
            return false
        }
        
        if let data = data {
            do {
                let json =  try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                let dictionary = json as? [String: Any]
                self.allProjects = self.parseDictionary(json: dictionary)
                self.projectQueue = self.allProjects.filter() { project in
                    if project.tags.contains("swift") || project.tags.contains("Swift") {
                        return true
                    }
                    return false
                }
                
                return true
            } catch let error {
                print("JsonError \(error.localizedDescription)")
                return false
            }
        } else {
            return false
        }
    }
    
    func analyseNext() {
        dispatchGroup.enter()
    
        if let nextProject = projectQueue.popLast() {
            print("Analyse: ")
            print("    \(nextProject.name)")
            print("    \(nextProject.repoPath)")
//            let listOfApps = ["ABU", "AlzPrevent", "Analog Synth X", "Aozora", "AppLove", "Awesome Swift iOS App", "Brave", "Calculator by mukeshthawani", "Chats", "Chess", "DeckRocket", "Dono", "Ello", "EmotionNote Diary", "EventBlankApp", "Firefox", "Furni", "Google Feud", "GrandCentralBoard", "Gulps", "Hack Cancer Hackathon", "HomeKit-Demo", "Keinex tech blog", "Lister", "LogU", "Meme Maker", "NumberPad", "Paws", "Post Manager", "Potatso", "Protocol-Oriented MVVM Examples", "RWDevCon", "Reusable Code", "Review Time", "Rocket.Chat", "Savings Assistant", "SceneKitFrogger", "Siesta GitHub Browser", "Soon", "SoundCloudSwift", "Swift-Demos", "SwiftTextClock", "Tweetometer", "WWDC Students", "WatchKit-Apps", "Wire", "Yep", "iCepa", "iOS 10 Day by Day", "iOS 9 Sampler", "tpg offline", "try!"]
//
//            if !listOfApps.contains(nextProject.name) {
//                analyseNext()
//                dispatchGroup.leave()
//            } else  {
            
            
            let success = cloneIfNotAvailable(project: nextProject) { success, project in
                if success {
                    if let url = project.localUrl {
//                        self.checkAndPrintDependencies(project: project)
//                        self.updateMissingDependencies(project: project)
//                        self.dispatchGroup.leave()
                        
                        
                        print("Project: \(project.name) start analysis!")
                        var dependencyURL = url
                        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
                        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)

                        let appKey = "\(project.name)-\(self.dateString)"
                        nextProject.appKey = appKey

                        do {
                            self.dataSyncController.reset()
                            
                            let controller = try SourceFileIndexAnalysisController(project: nextProject)
                            controller.useModules = true
                            controller.dataSyncController = self.dataSyncController
                            controller.analyseAllFilesAndAddToDatabase() {
                                print("Finished analysis for: \(project.name)")
                                project.projectAnalysed = true
                                self.printToFile(fileURL: self.outputFileURL)

                                self.dispatchGroup.leave()
                            }
                        } catch let error {
                            print(error.localizedDescription)
                            self.dispatchGroup.leave()
                        }
                    } else {
                        print("Project: \(project.name) no local url!")
                        self.dispatchGroup.leave()
                    }
                } else {
                    print("Project: \(project.name) not successful")
                    self.dispatchGroup.leave()
                }
            }
            self.counProjectsAnalysed += 1
            
            print("cloning succeeded? \(success)")
            
            //if self.counProjectsAnalysed < 400 {
                analyseNext()
            //}
            }
            
//        } else {
//            self.dispatchGroup.leave()
//        }
    }
    
    func parseDictionary(json: [String:Any]?) -> [Project] {
        var projects: [Project] = []
        
        guard let dictionary = json  else {
            print("Json is nil")
            return projects
        }
        
        guard let projectDictionary = dictionary["projects"] as? [[String:Any]] else {
            print("No projects")
            return projects
        }
        
        for projectData in projectDictionary {
            guard let title = projectData["title"] as? String else {
                print("no title")
                continue
            }
            
//            guard let description = projectData["description"] as? String else {
//                print("no description, title: \(title)")
//                continue
//            }
            
            let description = projectData["description"] as? String ?? "No description"
            
            guard let source = projectData["source"] as? String else {
                print("No source")
                continue
            }
                
            guard let tags = projectData["tags"] as? [String] else {
                print("No tags, title: \(title)")
                continue
            }
            
            let project = Project(name: title, repoPath: source, description: description, tags: tags)
            
            project.categories = projectData["gategory-ids"] as? [String]
            project.homePage = projectData["homePage"] as? String
            project.license = projectData["license"] as? String
            project.appstoreLink = projectData["itunes"] as? String
            project.stars = projectData["stars"] as? Int
            
            projects.append(project)
        }
        return projects
    }
}

@available(OSX 10.13, *)
extension Process {

    private static let gitExecURL = URL(fileURLWithPath: "/usr/bin/git")
    //private static let carthageExecURL = URL(fileURLWithPath: "/usr/local/bin/carthage")
    private static let podsExecURL = URL(fileURLWithPath: "/usr/local/bin/pod")

    public func clone(repo: String, path: String) throws {
        executableURL = Process.gitExecURL
        arguments = ["clone", repo, path]
        try run()
    }
    
    public func installPods(path: String) throws {
        executableURL = Process.podsExecURL
        arguments = ["install", "--project-directory=\(path)"]
        try run()
    }
    
    public func updatePods(path: String) throws {
        executableURL = Process.podsExecURL
        arguments = ["update", "--project-directory=\(path)"]
        try run()
    }
    
    public func updateCarthage(url: URL) throws {
        executableURL = url
        arguments = ["checkout"]
        try run()
    }

}

// Git stuff
extension BulkAnalysisController {
    func cloneIfNotAvailable(project: Project, completition: @escaping (Bool, Project) -> Void) -> Bool {
        let url = self.outputFolderURL.appendingPathComponent(project.name)
        project.localUrl = url
        
        if FileManager.default.fileExists(atPath: url.path) {
            print("File already exists, will not clone")
            
            completition(true, project)
            return false
        }
        print("File does not exist: \(url)")
        
        if self.shouldRunGitClone {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error {
                print("error \(error)")
            }
            
            if #available(OSX 10.13, *) {
                do {
                    let process = Process()
                    process.terminationHandler = { process in
                        completition(process.terminationStatus == 0, project)
                    }
                    
                    try process.clone(repo: project.repoPath, path: url.path)
                    print("created repo: \(project.repoPath) in \(url.path)")
                    
                    project.projectDownloaded = true
                    
                    /*
                     xcodebuildProcess.terminationHandler = { process in
                        completion(process.terminationStatus)
                     }
                     */
                } catch let error {
                    print("Error cloning repo: \(project.repoPath), error: \(error.localizedDescription)")
                    completition(false, project)
                }
            } else {
                print("OSX version too old, cannot clone repo")
                completition(false, project)
            }
        }
        return true
    }
}

// Projects to file and back
extension BulkAnalysisController {
    func printToFile(fileURL: URL) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let encodedData = try encoder.encode(self.allProjects)
            try encodedData.write(to: fileURL)
        } catch let error {
            print("Writing json to file failed: \(error.localizedDescription)")
        }
    }
    
    func readFromFile(fileURL: URL) -> [Project] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decodedData = try decoder.decode([Project].self, from: data)
            
            return decodedData
        } catch let error {
            print("Reading json from file failed: \(error.localizedDescription)")
        }
        
        return []
    }
}

// Check for project dependencies
extension BulkAnalysisController {
    func checkAndPrintDependencies(project: Project) {
        self.checkForDependencies(project: project)
        self.checkIfDependenceisAnalysed(project: project)
        
        self.printMissingDependencies(project: project)
    }
    
    func checkForDependencies(project:Project) {
        let fileManager = FileManager.default
        if let url = project.localUrl {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            
                for fileURL in fileURLs {
                    if fileURL.lastPathComponent == "Podfile" {
                        project.dependencies.append("CocoaPods")
                    } else if fileURL.lastPathComponent == "Cartfile" {
                        project.dependencies.append("Carthage")
                    } else if fileURL.lastPathComponent == "Pods" {
                        project.dependencyPaths.append(fileURL.path)
                        //updatePods(project: project)
                    } else if fileURL.lastPathComponent == "Carthage" {
                        let subURLs = try fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
                        
                        for subURL in subURLs {
                            if subURL.lastPathComponent == "Checkouts" {
                                project.dependencyPaths.append(subURL.path)
                            }
                        }
                    }
                }
            } catch {
                print("Error while enumerating files \(url.path): \(error.localizedDescription)")
                project.errorDescriptions.append(error.localizedDescription)
            }
        } else {
            print("Cannot check dependencies, local url nil")
            project.errorDescriptions.append("Cannot check dependencies, local url nil")
        }
    }
    
    func checkIfDependenceisAnalysed(project: Project) -> Bool {
        if project.dependencyPaths.count == project.dependencies.count {
            project.dependenciesAnalysed = true
            return true
        }
        
        project.dependenciesAnalysed = false
        return false
    }
    
    
    /*
     if #available(OSX 10.13, *) {
         do {
             let process = Process()
             process.terminationHandler = { process in
                 completition(process.terminationStatus == 0, project)
             }
             
             try process.clone(repo: project.repoPath, path: url.path)
             print("created repo: \(project.repoPath) in \(url.path)")
             
             project.projectDownloaded = true
             
             /*
              xcodebuildProcess.terminationHandler = { process in
                 completion(process.terminationStatus)
              }
              */
         } catch let error {
             print("Error cloning repo: \(project.repoPath), error: \(error.localizedDescription)")
             completition(false, project)
         }
     } else {
         print("OSX version too old, cannot clone repo")
         completition(false, project)
     }
     */
    
    func updatePods(project: Project) {
        if let url = project.localUrl {
            let podsURL = url.appendingPathComponent("Pods")
            print("podsURL: \(podsURL.path)")
            
            do {
                let podURLS = try FileManager.default.contentsOfDirectory(at: podsURL, includingPropertiesForKeys: nil)
                if podURLS.count <= 3 {
                    print("Missing pods in: \(url.path)")
                    let process = Process()
                    process.terminationHandler = { process in
                        print("terminated")
                    }
                    if #available(OSX 10.13, *) {
                        try process.updatePods(path: url.path)
                    }
                }
            } catch {
                print("Could not rul pod update: \(url.path), \(error.localizedDescription)")
            }
        }
    }
    
    func updateMissingDependencies(project: Project) {
        if project.dependenciesAnalysed == false {
            print("updateMissingDependencies")
            if project.dependencies.contains("CocoaPods") {
                var cocoaPodsExists = false
                
                for dependencyPath in project.dependencyPaths {
                    if dependencyPath.hasSuffix("Pods") {
                        cocoaPodsExists = true
                    }
                }
                
                print("project.url: \(project.localUrl)")
                if let url = project.localUrl {
                    if #available(OSX 10.13, *) {
                        if !cocoaPodsExists {
                            print("install pods")
                            
                            let process = Process()
                            process.terminationHandler = { process in
                                print("terminated")
                            }
                            
                            do {
                                try process.installPods(path: url.path)
                                print("pod install: \(url.path)")
                            } catch {
                                print("pod intall failed: \(url.path), \(error.localizedDescription)")
                                project.errorDescriptions.append("pod install failed: \(url.path), \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            
            if project.dependencies.contains("Carthage") {
                var carthageExists = false
                
                for dependencyPath in project.dependencyPaths {
                    if dependencyPath.hasSuffix("Carthage/Checkouts") {
                        carthageExists = true
                    }
                }
                
                print("project.url: \(project.localUrl)")
                if let url = project.localUrl {
                    if #available(OSX 10.13, *) {
                        if !carthageExists {
                            print("update carthage")
                            let process = Process()
                            process.terminationHandler = { process in
                                print("terminated")
                            }
                            
                            do {
                                try process.updateCarthage(url: url)
                                print("carthage update: \(url.path)")
                            } catch {
                                print("carthage update failed: \(url.path), \(error.localizedDescription)")
                                project.errorDescriptions.append("carthage update failed: \(url.path), \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func printMissingDependencies(project: Project) {
        print("project: \(project.name)")
        print("dependencies: \(project.dependencies)")
        print("dependency paths: \(project.dependencyPaths)")
            if !project.dependenciesAnalysed {
                if project.dependencies.contains("Cocoapods") {
                    var cocoaPodsExists = false
                    
                    for dependencyPath in project.dependencyPaths {
                        if dependencyPath.hasSuffix("Pods") {
                            cocoaPodsExists = true
                        }
                    }
                    
                    if !cocoaPodsExists {
                        print("\(project.name) - \(project.localUrl?.path ?? "?")")
                    }
                }
                
                if project.dependencies.contains("Carthage") {
                    var carthageExists = false
                    
                    for dependencyPath in project.dependencyPaths {
                        if dependencyPath.hasSuffix("Carthage/Checkouts") {
                            carthageExists = true
                        }
                    }
                    
                    if !carthageExists {
                        print("\(project.name) - \(project.localUrl?.path ?? "?")")
                    }
                }
            }
        }
}

class Project: Codable {
    let name: String
    let description: String
    let repoPath: String
    let tags: [String]
    
    var appstoreLink: String?
    var categories: [String]?
    var homePage: String?
    var license: String?
    var stars: Int?
    
    var localUrl: URL?
    
    var projectDownloaded = false
    var projectAnalysed = false
    var dependenciesAnalysed = false // true if checked for Cartfile and Podfile
    
    var appKey: String?
    
    var sdk: String?
    var target: String?
    
    var size: Int?
    
    var errorDescriptions: [String] = []
    
    var dependencies: [String] = [] // Carthage and/or Cocoapods (depending if Podfile or Cartfile is present)
    var dependencyPaths: [String] = [] // path to Carthage/Checkouts and/or Pods fodler
    
    var developer: String {
        // String between "/github.com/" and "/"
        
        let splitString = self.repoPath.split(separator: "/")
        if splitString.count < 3 {
            return ""
        }
        
        return String(splitString[splitString.count - 2])
    }
    
    init(name: String, repoPath: String, description: String, tags: [String]) {
        self.name = name
        self.repoPath = repoPath
        self.description = description
        self.tags = tags
    }
}
