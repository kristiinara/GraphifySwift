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
            let parser = ArgumentParser(commandName: "GraphifySwiftCMD", usage: "appKey [--appkey AppKey], folder", overview: "Analyse swift app and insert classes data into neo4j database.")
            
            let appKey: OptionArgument<String> = parser.add(option: "--appkey", shortName: "-a", kind: String.self, usage: "Appkey as unique identifier of the app.", completion: .none)
            let folderPath = parser.add(positional: "foldername", kind: String.self)
            
            let args = Array(CommandLine.arguments.dropFirst())
            let result = try parser.parse(args)
            
            //print("parsed arguments: \(result)")
            
            guard let path = result.get(folderPath) else {
                throw ArgumentParserError.expectedArguments(parser, ["foldername"])
            }
            
            guard let key = result.get(appKey) else {
                throw ArgumentParserError.expectedArguments(parser, ["-appkey"])
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
}
