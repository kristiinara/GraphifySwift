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
    
    var analysisResults: [String: [[String]]] = [:]
    var analysisResultsHeaders: [String: [String]] = [:]
    var dateString = ""
    
    func start() {
        
        do {
            print("Starting application")
            
            let dateFormatter : DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = Date()
            self.dateString = dateFormatter.string(from: date)
            
            let parser = ArgumentParser(commandName: "GraphifySwiftCMD", usage: "appKey [--appkey AppKey], folder", overview: "Analyse swift app and insert classes data into neo4j database.")
            
            let analyseParser = parser.add(subparser: "analyse", overview: "Analyse swift app and insert data into neo4j database")
            let queryParser = parser.add(subparser: "query", overview: "Query existing database for code smells.")
            let clearParser = parser.add(subparser: "clearOutput", overview: "Clears .result files from folder")
            let diagramParser = parser.add(subparser: "classDiagram", overview: "Generates and displayes class diagram")
            let analyseBulkParaser = parser.add(subparser: "analyseBulk", overview: "Analyses multiple application at once")
            
            let appKey: OptionArgument<String> = analyseParser.add(option: "--appkey", shortName: "-a", kind: String.self, usage: "Appkey as unique identifier of the app.", completion: .none)
            let folderPath = analyseParser.add(positional: "foldername", kind: String.self)
            let outputArgument: OptionArgument<Bool> = analyseParser.add(option: "--resultOutput", shortName: "-o", kind: Bool.self, usage: "Determines if a result file is created for every swift file.", completion: .none)
            let moduleArgument: OptionArgument<Bool> = analyseParser.add(option: "--includModules", shortName: "-m", kind: Bool.self, usage: "Determines if modules should be included.", completion: .none)
            let noDatabaseArgumnet: OptionArgument<Bool> = analyseParser.add(option: "--noDatabase", shortName: "-n", kind: Bool.self, usage: "Flag determines that analysis results are not entered into a database.", completion: .none)
            
            let diagramFolderPath = diagramParser.add(positional: "foldername", kind: String.self)
          
            //parser.add
            
            let queryArgument: OptionArgument<String> = queryParser.add(option: "--query", shortName: "-q", kind: String.self, usage: "Query to run.", completion: .none)
            
            let htmlArgument: OptionArgument<String> = queryParser.add(option: "--htmlFile", shortName: "-t", kind: String.self, usage: "HTML file for output", completion: .filename)
            
            let csvArgument: OptionArgument<String> = queryParser.add(option: "--csvFolder", shortName: "-c", kind: String.self, usage: "Folder to write all csv files.", completion: .filename)
            
            let clearFolder = clearParser.add(positional: "foldername", kind: String.self)
            
            let fileArgument: OptionArgument<String> = analyseBulkParaser.add(option: "--fileName", shortName: "-f", kind: String.self, usage: "Path to file with list of applications", completion: .filename)
            let outputFolder = analyseBulkParaser.add(positional: "foldername", kind: String.self)
            
            
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
                
                let url = urlFromStirng(path: path)
                
                var shouldPrintOutput = false
                if result.get(outputArgument) != nil {
                    shouldPrintOutput = true
                }
                
                var shouldIncludeModules = false
                if result.get(moduleArgument) != nil {
                    shouldIncludeModules = true
                }
                
                var shouldInsertToDatabase = true
                if result.get(noDatabaseArgumnet) != nil {
                    shouldInsertToDatabase = false
                }
                
                self.runAnalysis(url: url!, appKey: key, printOutput: shouldPrintOutput, useModules: shouldIncludeModules, insertToDatabase: shouldInsertToDatabase)
            } else if subparser == "query" {
                print("query")
                guard let query = result.get(queryArgument) else {
                    throw ArgumentParserError.expectedArguments(parser, ["--query"])
                }
                
                var htmlOutput = false
                var url: Foundation.URL? = nil
                
                if let htmlFile = result.get(htmlArgument) {
                    htmlOutput = true
                    url = urlFromStirng(path: htmlFile)
                }
                
                var csvUrl: Foundation.URL? = nil
                if let csvPath = result.get(csvArgument) {
                    csvUrl = urlFromStirng(path: csvPath)
                }
                
                self.runQueryWithStatistics(query: query, htmlURL: url, csvURL: csvUrl)
                //self.runQuery(query: query)
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
                let url = urlFromStirng(path: path)
                
                self.generateClassDiagram(url: url!)
                
            } else if subparser == "analyseBulk" {
                guard let inputPath = result.get(fileArgument) else {
                    throw ArgumentParserError.expectedArguments(parser, ["--fileName"])
                }
                
                guard let outputFolder = result.get(outputFolder) else {
                    throw ArgumentParserError.expectedArguments(parser, ["Folder"])
                }
                
                let inputURL = self.urlFromStirng(path: inputPath)
                let outputURL = self.urlFromStirng(path: outputFolder)
                if let inputURL = inputURL, let outputURL = outputURL {
                    self.analyseInBulk(inputFileURL: inputURL, outputFolderURL: outputURL)
                } else {
                    print("Input or output url was nil: \(inputURL), \(outputURL)")
                }
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
    
    func analyseInBulk(inputFileURL: Foundation.URL, outputFolderURL: Foundation.URL) {
        let analysisController = BulkAnalysisController(inputFileURL: inputFileURL, outputFolderURL: outputFolderURL)
        analysisController.analyse()
    }
    
    func clearOutput(url: Foundation.URL) {
        ResultToFileHandler.clearOutput(at: url)
    }
    
    func runAnalysis(url: Foundation.URL, appKey: String, printOutput: Bool, useModules: Bool, insertToDatabase: Bool) {
        dispatchGroup.enter()
        
        var dependencyURL = url
        dependencyURL = dependencyURL.appendingPathComponent("Carthage", isDirectory: true)
        dependencyURL = dependencyURL.appendingPathComponent("Checkouts", isDirectory: true)
        
        let analysisController = SourceFileIndexAnalysisController(homeURL: url, dependencyURL: dependencyURL)
        analysisController.useModules = useModules
        analysisController.printOutput = printOutput
        analysisController.insertToDatabase = insertToDatabase
        
        analysisController.analyseAllFilesAndAddToDatabase() {
            print("finished")
            
            self.dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
    
    func runQueryWithStatistics(query: String, htmlURL: Foundation.URL?, csvURL: Foundation.URL?) {
        let analysisController = AnalysisController()
        //var analysisResults: [String: [[String: Any]]] = [:]
        
        analysisController.analyse(queryString: query) { name, rows, headers, totalQueries, currentQuery in
            if let rows = rows {
                //print("rows: \(rows)")
                if var existing = self.analysisResults[name] {
                    existing.append(contentsOf: rows)
                } else {
                    self.analysisResults[name] = rows
                }
                
                if let headers = headers {
                    self.analysisResultsHeaders[name] = headers
                }
                
                if let csvURL = csvURL {
                    //TODO: fix? small hack where we only write results for the current query
                    self.printStatistics(results: [name: self.analysisResults[name]!], headers: self.analysisResultsHeaders, csvURL: csvURL)
                }
                
                if (csvURL == nil || htmlURL != nil) && totalQueries == currentQuery {
                    self.printStatistics(results: self.analysisResults, headers: self.analysisResultsHeaders, htmlURL: htmlURL)
                }
            }
        }
    }
    
    func printStatistics(results: [String: [[String]]], headers: [String:[String]], csvURL: Foundation.URL) {
        let queryCSVs = HTMLPresenter.generateCSV(dictionary: results, headerDictionary: headers, fileNamePrefix: "\(self.dateString)-")
         
         do {
             try FileManager.default.createDirectory(at: csvURL, withIntermediateDirectories: true, attributes: nil)
         }
         catch let error {
             print("error \(error)")
         }
         
         for fileName in queryCSVs.keys {
             if let fileString = queryCSVs[fileName] {
                 let url = csvURL.appendingPathComponent(fileName)
                 
                 do {
                     try fileString.write(to: url, atomically: false, encoding: .utf8)
                 } catch let error {
                     print("error \(error)")
                 }
             }
         }
    }
    
    func printStatistics(results: [String: [[String]]], headers: [String:[String]], htmlURL: Foundation.URL?) {
        print("Print statistics!")
        var applications: [String: [String: [[String]]]] = [:]
       // print("\(results)")
        
        for queryName in results.keys {
            //print("query: \(queryName)")
            if let queryResult = results[queryName] {
                for row in queryResult {
                 //   print("row: \(row)")
                    if row.count >= 1 {
                        let appKey = row[0]
                        
                        if applications[appKey] == nil {
                            applications[appKey] = [String: [[String]]]()
                        }
                        
                        if var appStuff = applications[appKey] {
                           // print("starting with query stuff")
                            if appStuff[queryName] == nil {
                             //   print("nil")
                                appStuff[queryName] = [[String]]()
                            }
                            
                            if var queryStuff = appStuff[queryName] {
                              //  print("not nil")
                                queryStuff.append(row)
                                appStuff[queryName] = queryStuff
                                
                               // print("appStuff[queryName] = \(appStuff[queryName])")
                               // print("queryStuff = \(queryStuff)")
                            }
                            
                            applications[appKey] = appStuff
                        }
                    }
                    
                    
                    /*
                    if let appKey = row["app_key"] as? String {
                        if applications[appKey] == nil {
                            applications[appKey] = [:]
                        }
                        
                        if var appStuff = applications[appKey] {
                            if appStuff[queryName] == nil {
                                appStuff[queryName] = [[String: Any]]()
                            }
                            
                            if var queryArray = appStuff[queryName] as? [[String: Any]] {
                                queryArray.append(row)
                            }
                        }
                    }
                    */
                }
            }
        }
        
        if htmlURL == nil{
            print("applications: \(applications)")
        
            for key in applications.keys {
                print("application: \(key)")
                
                if let applicationStuff = applications[key] {
                    for query in applicationStuff.keys {
                        print("       query: \(query)")
                        if let queryResults = applicationStuff[query] {
                            for result in queryResults {
                                print("              \(result)")
                            }
                        }
                    }
                }
            }
        }
        
        if let htmlURL = htmlURL {
            let htmlFiles = HTMLPresenter.generateHTML(fileName: "html-result", dictionary: applications, headerDictionary: headers)
            
            
//            for key in htmlFiles.keys {
//                if let htmlString = htmlFiles[key] {
//                    let url = URL(key)
//
//                    do {
//                        try htmlString.write(to: url, atomically: false, encoding: .utf8)
//                    } catch let error {
//                        print("error \(error)")
//                    }
//                }
//            }
            
            do {
                try FileManager.default.createDirectory(at: htmlURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error {
                print("error \(error)")
            }
            
            for fileName in htmlFiles.keys {
                if let fileString = htmlFiles[fileName] {
                    let url = htmlURL.appendingPathComponent(fileName)
                    
                    do {
                        try fileString.write(to: url, atomically: false, encoding: .utf8)
                    } catch let error {
                        print("error \(error)")
                    }
                }
            }
        }
    }
    
    func urlFromStirng(path: String) -> Foundation.URL? {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        
        var url = URL(fileURLWithPath: currentPath)
        
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else {
            //relative path
            url.appendPathComponent(path)
        }
        
        return url
    }
    
    func runQuery(query: String) {
        let analysisController = AnalysisController()
        
        analysisController.analyse(queryString: query) { name, rows, headers, totalQueries, currentQuery in
            if let rows = rows {
                print("Query number of results: \(rows.count)")
                print("\(headers)")
                for row in rows {
                    print(row.reduce("") { result, item in
                        if result.count == 0 {
                            return "\(item)"
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
