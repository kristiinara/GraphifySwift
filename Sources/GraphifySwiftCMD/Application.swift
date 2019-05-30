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
            
            let appKey: OptionArgument<String> = analyseParser.add(option: "--appkey", shortName: "-a", kind: String.self, usage: "Appkey as unique identifier of the app.", completion: .none)
            let folderPath = analyseParser.add(positional: "foldername", kind: String.self)
            parser.add
            
            let queryArgument: OptionArgument<String> = queryParser.add(option: "--query", shortName: "-q", kind: String.self, usage: "Query to run.", completion: .none)
            
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
                
                self.runAnalysis(url: url, appKey: key)
            } else if subparser == "query" {
                print("query")
                guard let query = result.get(queryArgument) else {
                    throw ArgumentParserError.expectedArguments(parser, ["--query"])
                }
                
                self.runQuery(query: query)
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
        
        let analysisController = SourceFileAnalysisController()
        analysisController.fileQueue.append(URL(fileURLWithPath: "/home/k/graphifyswiftcmd/Sources/GraphifySwiftCMD/Application.swift"))
        analysisController.analyseFiles {
            analysisController.analyseSpecialSuperClasses()
            analysisController.analyseClassHierarchy()
            analysisController.printApp()
            analysisController.dataSyncController.sync(app: analysisController.app)
        }
        
    }
    
    func runAnalysis(url: Foundation.URL, appKey: String) {
        let analysisController = SourceFileAnalysisController()
        dispatchGroup.enter()
        
        analysisController.analyseFolder(at: url, appKey: appKey) {
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
            print("rows: \(String(describing: rows))")
        }
    }
}
