//
//  DependencyController.swift
//  Basic
//
//  Created by Kristiina Rahkema on 08/08/2019.
//

import Foundation

class DependencyController {
    let homePath: String
    var successfulDependencies: [String] = []
    var failedDependencies: [String] = []
    var dependencyQueue: [URL] = []
    var successfullPaths: [String] = []
    //TODO: get all folders, get depencency queue for each folder
    
    init(homeURL: URL) {
        self.homePath = homeURL.absoluteString
        self.dependencyQueue = FolderUtility.getSubfolders(for: homeURL, suffix: "Sources")
    }
    
    var resolved: Bool {
        return self.dependencyQueue.isEmpty
    }
    
    var nextDepencency: URL? {
        if dependencyQueue.count > 0 {
            return dependencyQueue.remove(at: 0)
        } else {
            return nil
        }
    }
    
    var successfulDependencyString: String {
        let result = self.successfulDependencies.reduce("") { res, depencency in
            if res.count > 0 {
                return "\(res) \(depencency)"
            } else {
                return depencency
            }
        }
        return result
    }
    
    func tryNextDependency(with request:(([String]) -> Bool)) {
        if let dependency = self.nextDepencency {
            let foldernames = FolderUtility.getFileNames(for: dependency)
            let result = request(foldernames)
            print("Resolving dependancy \(dependency) -- successful? \(result)")
            print("Folder names: \(foldernames)")
            
            //TODO: shouldn't we add foldernames to successfulDependencies??
            if result == true {
                self.successfulDependencies.append(dependency.absoluteString)
                self.successfullPaths.append(contentsOf: foldernames)
            } else {
                self.failedDependencies.append(dependency.absoluteString)
            }
        }
    }
}
