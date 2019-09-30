//
//  Application.swift
//  CYaml
//
//  Created by Kristiina Rahkema on 09/05/2019.
//

import Foundation
import Utility

class Application {
    let dispatchGroup = DispatchGroup()
    
    func start() {
        
        do {
            print("Starting application")
            
            let parser = ArgumentParser(commandName: "GraphifySwiftCMD", usage: "appKey [--appkey AppKey], folder", overview: "Analyse swift app and insert classes data into neo4j database.")
            
            let analyseParser = parser.add(subparser: "analyse", overview: "Analyse swift app and insert data into neo4j database")
            let queryParser = parser.add(subparser: "query", overview: "Query existing database for code smells.")
            let clearParser = parser.add(subparser: "clearOutput", overview: "Clears .result files from folder")
            let diagramParser = parser.add(subparser: "classDiagram", overview: "Generates and displayes class diagram")
            
            let appKey: OptionArgument<String> = analyseParser.add(option: "--appkey", shortName: "-a", kind: String.self, usage: "Appkey as unique identifier of the app.", completion: .none)
            let folderPath = analyseParser.add(positional: "foldername", kind: String.self)
            let outputArgument: OptionArgument<Bool> = analyseParser.add(option: "--resultOutput", shortName: "-o", kind: Bool.self, usage: "Determines if a result file is created for every swift file.", completion: .none)
            let moduleArgument: OptionArgument<Bool> = analyseParser.add(option: "--includModules", shortName: "-m", kind: Bool.self, usage: "Determines if modules should be included.", completion: .none)
            
            let diagramFolderPath = diagramParser.add(positional: "foldername", kind: String.self)
          
            //parser.add
            
            let queryArgument: OptionArgument<String> = queryParser.add(option: "--query", shortName: "-q", kind: String.self, usage: "Query to run.", completion: .none)
            
            let clearFolder = clearParser.add(positional: "foldername", kind: String.self)
            
            let args = Array(CommandLine.arguments.dropFirst())
            let result = try parser.parse(args)
            
            print("Command parser set up: \(result.description)")
            
            let subparserInstance = result.subparser(parser)
            
            //print("parsed arguments: \(result)")
            
            guard let subparser = subparserInstance else {
                throw ArgumentParserError.expectedArguments(parser, ["action"])
            }
            
            if subparser == "analyse" {
                print("analyse")
                
                guard let path = result.get(folderPath) else {
                    throw ArgumentParserError.expectedArguments(parser, ["foldername"])
                }
                
                guard let key = result.get(appKey) else {
                    throw ArgumentParserError.expectedArguments(parser, ["--appkey"])
                }
                
                let fileManager = FileManager.default
                let currentPath = fileManager.currentDirectoryPath
                
                var url = URL(fileURLWithPath: currentPath)
                
                if path.hasPrefix("/") {
                    url = URL(fileURLWithPath: path)
                } else {
                    //relative path
                    url.appendPathComponent(path)
                }
                
                var shouldPrintOutput = false
                if result.get(outputArgument) != nil {
                    shouldPrintOutput = true
                }
                
                var shouldIncludeModules = false
                if result.get(moduleArgument) != nil {
                    shouldIncludeModules = true
                }
                
                self.runAnalysis(url: url, appKey: key, printOutput: shouldPrintOutput, useModules: shouldIncludeModules)
            } else if subparser == "query" {
                print("query")
                guard let query = result.get(queryArgument) else {
                    throw ArgumentParserError.expectedArguments(parser, ["--query"])
                }
                
                self.runQuery(query: query)
            } else if subparser == "clearOutput" {
                guard let path = result.get(clearFolder) else {
                    throw ArgumentParserError.expectedArguments(parser, ["Folder"])
                }
                let fileManager = FileManager.default
                let currentPath = fileManager.currentDirectoryPath
                
                var url = URL(fileURLWithPath: currentPath)
                
                if path.hasPrefix("/") {
                    url = URL(fileURLWithPath: path)
                } else {
                    //relative path
                    url.appendPathComponent(path)
                }
                
                self.clearOutput(url: url)
            } else if subparser == "classDiagram" {
                guard let path = result.get(diagramFolderPath) else {
                    throw ArgumentParserError.expectedArguments(parser, ["Folder"])
                }
                let fileManager = FileManager.default
                let currentPath = fileManager.currentDirectoryPath
                
                var url = URL(fileURLWithPath: currentPath)
                
                if path.hasPrefix("/") {
                    url = URL(fileURLWithPath: path)
                } else {
                    //relative path
                    url.appendPathComponent(path)
                }
                
                self.generateClassDiagram(url: url)
                
            } else {
                print("Specify action as 'analyse', 'query', 'clearOutput' or 'classDiagram'")
               // throw ArgumentParserError.unknownOption(action)
            }
        } catch ArgumentParserError.expectedValue(let value) {
            print("Missing value for argument \(value).")
        } catch ArgumentParserError.expectedArguments( _, let stringArray) {
            print("Missing arguments: \(stringArray.joined()).")
        } catch ArgumentParserError.unexpectedArgument(let value){
            print("Unexpected argument: \(value)")
        } catch ArgumentParserError.unknownOption(let value) {
            print("Unknown option: \(value)")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func clearOutput(url: Foundation.URL) {
        ResultToFileHandler.clearOutput(at: url)
    }
    
    func runAnalysis(url: Foundation.URL, appKey: String, printOutput: Bool, useModules: Bool) {
        dispatchGroup.enter()
        
        var dependencyURL = url
        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)
        
        let analysisController = SourceFileIndexAnalysisController(homeURL: url, dependencyURL: dependencyURL)
        analysisController.useModules = useModules
        
        analysisController.analyseAllFilesAndAddToDatabase() {
            print("finished")
            
            self.dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
    
    func runQuery(query: String) {
        let analysisController = AnalysisController()
        
        analysisController.analyse(queryString: query) { rows in
            if let rows = rows {
                print("Query number of results: \(rows.count)")
                for row in rows {
                    print(row.reduce("") { result, item in
                        if result.count == 0 {
                            return item
                        }
                        return "\(result), \(item)"
                    })
                }
            } else {
                print("Results: nil")
            }
        }
    }
    
    func generateClassDiagram(url: Foundation.URL) {
        var dependencyURL = url
        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)
        
        let analysisController = SourceFileIndexAnalysisController(homeURL: url, dependencyURL: dependencyURL)
        
        let app = analysisController.analyseAllFiles()
        AppDelegate.run(app: app)
    }
}
