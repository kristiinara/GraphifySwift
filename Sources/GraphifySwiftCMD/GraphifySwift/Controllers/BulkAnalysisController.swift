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
    
    var analysisResults: [String: (Project, Bool)] = [:]
    
    init(inputFileURL: URL, outputFolderURL: URL) {
        self.inputFileURL = inputFileURL
        self.outputFolderURL = outputFolderURL
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
            let success = cloneIfNotAvailable(project: nextProject) { success, project in
                if success {
                    if let url = project.localUrl {
                        print("Project: \(project.name) start analysis!")
                        var dependencyURL = url
                        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
                        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)
                        
                        let controller = SourceFileIndexAnalysisController(homeURL: url, dependencyURL: dependencyURL)
                        controller.analyseAllFilesAndAddToDatabase() {
                            print("Finished analysis for: \(project.name)")
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
            
            //if self.counProjectsAnalysed < 3 {
                analyseNext()
            //}
        } else {
            self.dispatchGroup.leave()
        }
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

    public func clone(repo: String, path: String) throws {
        executableURL = Process.gitExecURL
        arguments = ["clone", repo, path]
        try run()
    }

}

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

class Project {
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
    
    init(name: String, repoPath: String, description: String, tags: [String]) {
        self.name = name
        self.repoPath = repoPath
        self.description = description
        self.tags = tags
    }
}
