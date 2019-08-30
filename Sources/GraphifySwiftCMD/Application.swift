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
            
            let appKey: OptionArgument<String> = analyseParser.add(option: "--appkey", shortName: "-a", kind: String.self, usage: "Appkey as unique identifier of the app.", completion: .none)
            let folderPath = analyseParser.add(positional: "foldername", kind: String.self)
            let outputArgument: OptionArgument<Bool> = analyseParser.add(option: "--resultOutput", shortName: "-o", kind: Bool.self, usage: "Determines if a result file is created for every swift file.", completion: .none)
            
            parser.add
            
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
                
                self.runAnalysis(url: url, appKey: key, printOutput: shouldPrintOutput)
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
           } else {
                print("Specify action as 'analyse' or 'query'")
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
    
    func runAnalysis(url: Foundation.URL, appKey: String, printOutput: Bool) {
//        let analysisController = SourceFileAnalysisController()
        dispatchGroup.enter()
        
        var dependencyURL = url
        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)
        
        let analysisController = SourceFileIndexAnalysisController(homeURL: url, dependencyURL: dependencyURL)
        analysisController.analyseAllFiles() {
            print("finished")
            
            self.dispatchGroup.leave()
        }
//
     //   analysisController.analyseFolder(at: url, appKey: appKey, printOutput: printOutput)

        dispatchGroup.notify(queue: DispatchQueue.main) {
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
        
//        var dependencyURL = url
//        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
//        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)
//
//        let analysisController = SourceFileIndexAnalysisController(homeURL: url, dependencyURL: dependencyURL)
//        analysisController.analyseAllFiles()
    }
    
    func runQuery(query: String) {
        let analysisController = AnalysisController()
        dispatchGroup.enter()
        
        analysisController.analyse(queryString: query) { rows in
            if let rows = rows {
                for row in rows {
                    if row.count == 2 {
                        print("\(row[0]) - \(row[1])")
                    } else {
                        print("Wrong number of items: \(row)")
                    }
                }
            }
            self.dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
}
