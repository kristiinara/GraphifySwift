//
//  Application.swift
//  CYaml
//
//  Created by Kristiina Rahkema on 09/05/2019.
//

import Foundation

class Application {
    let dispatchGroup = DispatchGroup()
    
    func start() {
        print("Argument: \(CommandLine.arguments)")
        
        if CommandLine.arguments.count == 2 {
            print("folder: \(CommandLine.arguments[1])")
            let folder = CommandLine.arguments[1]
            
            let fileManager = FileManager.default
            var path = fileManager.currentDirectoryPath
            
            var url = URL(fileURLWithPath: path)
            
            if folder.hasPrefix("/") {
                url = URL(fileURLWithPath: folder)
            } else {
                //relative path
                url.appendPathComponent(folder)
                path.append(contentsOf: folder)
            }
            
            print(url)
            
            let analysisController = SourceFileAnalysisController()
            dispatchGroup.enter()
            
            analysisController.analyseFolder(at: url) {
                print("finished")

                self.dispatchGroup.leave()
            }
            
            //    let resourceKeys : [URLResourceKey] = [
            //        .creationDateKey,
            //        .isDirectoryKey,
            //        .nameKey,
            //        .fileSizeKey
            //    ]
            //
            //    let enumerator = FileManager.default.enumerator(
            //        at:                         url,
            //        includingPropertiesForKeys: resourceKeys,
            //        options:                    [.skipsHiddenFiles],
            //        errorHandler:               { (url, error) -> Bool in
            //            print("directoryEnumerator error at \(url): ", error)
            //            return true
            //    })!
            //
            //    //fileQueue
            //    for case let fileURL as URL in enumerator {
            //        do {
            //            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            //            print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
            //
            //            if let name = resourceValues.name {
            //                print("File: \(name)")
            //                if name.hasSuffix(".swift") {
            //                    //                    let size = resourceValues.fileSize!
            //                    //                    self.app.size = self.app.size + size
            //                    //
            //                    //                    fileQueue.append(fileURL)
            //                    if let file = File(path: fileURL.path) {
            //                        do {
            //                            let structure = try Structure(file: file)
            //                            let res = structure.dictionary as [String: AnyObject]
            //                            print("\(fileURL) : \(res)")
            //                        }  catch {
            //
            //                        }
            //                    }
            //                }
            //            }
            //        } catch {
            //            //TODO: do something if an error is thrown!
            //            print("Error")
            //        }
            //    }
        } else {
            print("Too many or too few arguments! ")
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
}
