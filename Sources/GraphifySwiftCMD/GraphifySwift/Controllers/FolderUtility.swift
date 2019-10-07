//
//  FolderUtility.swift
//  Basic
//
//  Created by Kristiina Rahkema on 13/06/2019.
//

import Foundation

class FolderUtility {
    static func getSubfolders(for url: URL, suffix: String) -> [URL] {
        var directories: [URL] = []
        
        let resourceKeys : [URLResourceKey] = [
            .creationDateKey,
            .isDirectoryKey,
            .nameKey,
            .fileSizeKey
        ]
        
        do {
            let fileUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles])
            
            for fileURL in fileUrls {
                let url = fileURL.appendingPathComponent(suffix, isDirectory: true)
                directories.append(url)
            }
        } catch {
            print("Could not get files in folder \(url.path)")
        }
        return directories
    }
    
    static func getFileNames(for url: URL) -> [String] {
        let fileQueue = getFileQueue(for: url)
        return fileQueue.map() { url in return url.path}
    }

    static func getFileQueue(for url: URL) -> [URL] {
        return getFileQueue(for: url, ignore: [])
    }

    static func getFileQueue(for url: URL, ignore: [String]) -> [URL] {
        var files: [URL] = []
        
        let resourceKeys : [URLResourceKey] = [
            .creationDateKey,
            .isDirectoryKey,
            .nameKey,
            .fileSizeKey
        ]
        
        let enumerator = FileManager.default.enumerator(
            at:                         url,
            includingPropertiesForKeys: resourceKeys,
            options:                    [.skipsHiddenFiles],
            errorHandler:               { (url, error) -> Bool in
                print("directoryEnumerator error at \(url): ", error)
                return true
        })!
        
        //fileQueue
        fileLoop: for case let fileURL as URL in enumerator {
            // ignoring files that contain the ignore string, but only looking at path relative to after the base url
            for ignorePath in ignore {
                var path = fileURL.path
                path = path.replacingOccurrences(of: url.path, with: "")
                if path.contains(ignorePath) {
                    continue fileLoop
                }
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                //print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
                
                if let name = resourceValues.name {
                    if name.hasSuffix(".swift") {
                        //let size = resourceValues.fileSize!
                        print("\(fileURL.path)")
                        //self.app.size = self.app.size + size
                        //TODO: fix size stuff
                        //self.classSizes.append(size)
                        
                        if (fileURL.path.contains("/Controllers/PasscodeExtensionDisplay.swift")) {
                            print("Ignore bad file!!")
                        
                        } else if (fileURL.path.contains("Tests")) {
                            print("Ignore test files")
                        } else {
                            files.append(fileURL)
                        }
                    }
                }
            } catch {
                //TODO: do something if an error is thrown!
                print("Error")
            }
        }
        return files
    }
}
