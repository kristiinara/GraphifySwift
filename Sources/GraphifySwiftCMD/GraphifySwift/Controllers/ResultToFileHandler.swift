//
//  ResultToFileHandler.swift
//  Basic
//
//  Created by Kristiina Rahkema on 20/06/2019.
//

import Foundation

class ResultToFileHandler {
    static func clearOutput(at url: URL) {
        //self.addFilesToQueue(at: url)
        let fileQueue = FolderUtility.getFileQueue(for: url)
        
        for fileURL in fileQueue {
            let path = fileURL.path
            let newPath = path.replacingOccurrences(of: ".swift", with: "-result.json")
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: newPath))
            } catch {
                print("Could not remove file \(newPath)!")
            }
        }
    }
    
    static func write(resultString: String, toFile path: String) {
        let newPath = path.replacingOccurrences(of: ".swift", with: "-result.json")
        do {
            try resultString.write(toFile: newPath, atomically: true, encoding: .utf8)
        } catch {
            print("Could not write to file \(path)")
        }
    }
    
    static func writeOther(resultString: String, toFile path: String) {
        let newPath = path.replacingOccurrences(of: ".swift", with: "-doc-result.json")
        do {
            try resultString.write(toFile: newPath, atomically: true, encoding: .utf8)
        } catch {
            print("Could not write to file \(path)")
        }
    }
}
