//
//  main.swift
//  LSTool
//
//  Created by Simkó Viktor on 2017. 07. 02..
//  Copyright © 2017. Simkó Viktor. All rights reserved.
//

import Foundation

enum Action: String {
  
  case insert = "insert"
  
}

typealias ExecutableAction = (action: Action, args: [String])

var stringsDictionary: [String: [String: String]] = [:]

func validateArgs(_ args: [String]) -> ExecutableAction? {
  
  guard args.count > 1 else {
    return nil
  }
  
  guard let action = Action(rawValue: args[1]) else {
    return nil
  }
  
  var actionArgs: [String] = []
  
  if args.count > 2 {
    actionArgs.append(contentsOf: args[2...])
  }
  
  return (action, actionArgs)
}

func displayUsage() {
  
  print(
    """
      Usage:
        lstool insert <lstring>
    """
  )
  
}

func executeAction(_ executableAction: ExecutableAction) {
  
  switch executableAction.action {
  case .insert:
    insert(withArgs: executableAction.args)
  }
  
}

func insert(withArgs args: [String]) {
  
  guard args.count > 0 else {
    return displayUsage()
  }
  
  for arg in args {
    insert(arg)
  }
  
}

func insert(_ string: String) {
  print("Inserting \(string) ...")
  
  parseLocalizableStringsFiles()
  
  stringsDictionary = stringsDictionary.mapValues { stringDict in
    guard !stringDict.keys.contains(string) else {
      return stringDict
    }
    
    var newStringsDict = stringDict
    newStringsDict[string] = string
    return newStringsDict
  }
  
  writeLocalizableStringsFiles()
  
}

func parseLocalizableStringsFiles() {
  
  let localizableStringsFileURLs = getLocalizableStringsFileURLs()
  
  for url in localizableStringsFileURLs {
    parseLocalizableStringsFile(url)
  }
  
}

func getLocalizableStringsFileURLs() -> [URL] {
  
  let stringsEnumerator = FileManager.default.enumerator(atPath: ".")
  
  var stringsFileURLs: [URL] = []
  
  while let file = stringsEnumerator?.nextObject() as? String  {
    let fileURL = URL(fileURLWithPath: file)
    
    if fileURL.pathExtension == "strings" {
      stringsFileURLs.append(fileURL)
    }
  }
  
  return stringsFileURLs
}

func parseLocalizableStringsFile(_ url: URL) {
  
  print("Parsing \(url.relativeString)")
  
  stringsDictionary.removeAll()
  
  guard let contentsOfFile = try? String(contentsOf: url) else {
    return
  }
  
  stringsDictionary[url.relativeString] = [:]
  
  let linesOfFile = contentsOfFile.components(separatedBy: .newlines)
  
  for line in linesOfFile {
    
    let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespaces.union(.newlines))
    
    guard trimmedLine.count > 0 else {
      continue
    }
    
    let stringsRowRegexString = "\"(.*?)\" = \"(.*?)\";"
    guard let stringsRowRegex = try? NSRegularExpression(pattern: stringsRowRegexString, options: .caseInsensitive) else {
      continue
    }
    
    let matches = stringsRowRegex.matches(in: trimmedLine, options: [], range: NSMakeRange(0, trimmedLine.count))
    
    guard matches.count > 0 else {
      continue
    }
    
    let keyRange = matches[0].range(at: 1)
    let valueRange = matches[0].range(at: 2)
    
    let key = trimmedLine.substring(with: Range(keyRange, in: trimmedLine)!)
    let value = trimmedLine.substring(with: Range(valueRange, in: trimmedLine)!)
    
    stringsDictionary[url.relativeString]![key] = value
  }
  
}

func writeLocalizableStringsFiles() {
  
  for strings in stringsDictionary {
    let values = strings.value.sorted { $0.key.lowercased() < $1.key.lowercased() }
    
    var newContent = ""
    
    for string in values {
      newContent.append("\"\(string.key)\" = \"\(string.value)\";\n\n")
    }
    
    let url = URL(fileURLWithPath: strings.key)
    
    try? newContent.write(to: url, atomically: false, encoding: .utf8)
  }
  
}


let args = CommandLine.arguments

if let executableAction = validateArgs(args) {
  executeAction(executableAction)
} else {
  displayUsage()
}
