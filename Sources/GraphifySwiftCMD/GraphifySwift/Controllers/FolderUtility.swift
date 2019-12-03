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
    
    static func getNumberOfTests(for url: URL, ignore: [String]) -> (tests:Int, uitests:Int) {
        // UITests
        // Tests
        // if 37 lines --> empty test
        
        var numberOfTests = 0
        var numberOfUITests = 0
        
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
            
            let emptyTestString = """
XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
"""
            
            let emptyUITestString = """
XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
"""
            
            if fileURL.path.contains("UITests/") {
                do {
                    let testText = try String(contentsOf: fileURL, encoding: .utf8)
                    if testText.contains(emptyUITestString) {
                        print("Empty UITest")
                    } else {
                        numberOfUITests += 1
                    }
                }
                catch {print(error.localizedDescription)}
                
                numberOfUITests = numberOfUITests + 1
            } else if fileURL.path.contains("Tests/") {
                do {
                    let testText = try String(contentsOf: fileURL, encoding: .utf8)
                    if testText.contains(emptyTestString) {
                        print("Empty Test")
                    } else {
                        numberOfTests += 1
                    }
                }
                catch {print(error.localizedDescription)}
            }
        }
        
        return (tests:numberOfTests, uitests:numberOfUITests)
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
            
            if fileURL.path.contains("+") {
                continue fileLoop
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                //print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
                
                if let name = resourceValues.name {
                    if name.hasSuffix(".swift") || name.hasSuffix(".h") {
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
