//
//  FolderUtility.swift
//  Basic
//
//  Created by Kristiina Rahkema on 13/06/2019.
//

import Foundation

class FolderUtility {
    static func getFileQueue(for url: URL) -> [URL] {
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
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
                
                if let name = resourceValues.name {
                    if name.hasSuffix(".swift") {
                        let size = resourceValues.fileSize!
                        //self.app.size = self.app.size + size
                        //TODO: fix size stuff
                        //self.classSizes.append(size)
                        
                        files.append(fileURL)
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
