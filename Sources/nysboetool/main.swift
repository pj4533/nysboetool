
import Foundation
import Utility
import CSV

extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

func cleanHistoryItem(_ item: String) -> String {
    
    if item.contains("7TH SD") { return "" }
    if item.contains("TOWN OF N HEMPSTEAD") { return "" }
    if item == "PRES PRIMARY ELECTION" { return "PP04" }
    if item == "Presidential Primary Election" { return "PP16" }
    if item == "GENERAL ELECTION" { return "GE08" }
    
    var cleanItem = item.uppercased()
    cleanItem = cleanItem.replacingOccurrences(of: ",", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "  ", with: " ")
    
    cleanItem = cleanItem.replacingOccurrences(of: "SPECIAL ELECTION", with: "SE")
    cleanItem = cleanItem.replacingOccurrences(of: "SP", with: "SE")
    cleanItem = cleanItem.replacingOccurrences(of: "100TH & 103RD AD", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "20TH CD", with: "")

    cleanItem = cleanItem.replacingOccurrences(of: "GENERAL ELECTION", with: "GE")
    cleanItem = cleanItem.replacingOccurrences(of: "GENERAL STATE AND LOCAL", with: "GE")
    cleanItem = cleanItem.replacingOccurrences(of: "GENERAL", with: "GE")
    cleanItem = cleanItem.replacingOccurrences(of: "PRIMARY ELECTION", with: "PE")
    cleanItem = cleanItem.replacingOccurrences(of: "FEDERAL PRIMARY", with: "PE")
    cleanItem = cleanItem.replacingOccurrences(of: "PRESIDENTIAL PRIMARY", with: "PP")
    cleanItem = cleanItem.replacingOccurrences(of: "PRIMARY", with: "PE")
    cleanItem = cleanItem.replacingOccurrences(of: "PRESIDENTIAL", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "PRES", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "PR", with: "PE")
    cleanItem = cleanItem.replacingOccurrences(of: "FEDERAL", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "CITY", with: "")

    cleanItem = cleanItem.replacingOccurrences(of: "0205", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0316", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0419", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0624", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0626", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0628", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "1102", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "1103", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "1104", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "1105", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "1106", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "1107", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "1108", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0909", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0910", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0911", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0912", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0913", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0914", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "0915", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "1001", with: "")
    

    cleanItem = cleanItem.replacingOccurrences(of: "19", with: "")
    cleanItem = cleanItem.replacingOccurrences(of: "20", with: "")


    // Step 3: Rearrange to put year data last
    let components = cleanItem.components(separatedBy: " ")
    
    var rearrangedComponents : [String] = []
    var year : String?
    for comp in components {
        if comp.isNumber {
            year = comp
        } else {
            rearrangedComponents.append(comp)
        }
    }
    
    if let year = year {
        rearrangedComponents.append(year)
    }
    
    return rearrangedComponents.joined(separator: "")
}

func uniqueHistoryItems(_ path: String, _ debugOutput: Bool?) {
    let stream = InputStream(fileAtPath: path)!
    let csv = try! CSVReader(stream: stream)
    var uniqueHistoryItems : [String] = []
    // csv.next() // skip first row
    while let row = csv.next() {
        let voterHistory = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
        if voterHistory != "" {
            let historyItems = voterHistory.components(separatedBy: ";")
            for item in historyItems {
                // for building proper cleaning list -- only needed once per file
               if item != "" && !uniqueHistoryItems.contains(item) {
                    print("\(item)")
                    uniqueHistoryItems.append(item)
               }
            }
        }        
    }
    
    print("\n\n\(uniqueHistoryItems.count) unique history items")
}

func cleanFile(_ path: String, _ debugOutput: Bool?) {
    let stream = InputStream(fileAtPath: path)!
    let csv = try! CSVReader(stream: stream)
   var uniqueHistoryItems : [String] = []
    csv.next() // skip first row
    while let row = csv.next() {
        var cleanedVoterHistory : [String] = []
        let voterHistory = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
        if voterHistory != "" {
            let historyItems = voterHistory.components(separatedBy: ";")
            for item in historyItems {
                let cleanedItem = cleanHistoryItem(item)
                // for building proper cleaning list -- only needed once per file
               if cleanedItem != "" && !uniqueHistoryItems.contains(cleanedItem) {
                   if debugOutput == true {
                       print("\(item) --> \(cleanedItem)")
                   }
                   uniqueHistoryItems.append(cleanedItem)
               }
                cleanedVoterHistory.append(cleanedItem)
            }
        }
        
        if debugOutput != true {
            print ("UPDATE `state_boe_012219` SET `state_boe_012219`.`CLEANED_VOTER_HISTORY` = '\(cleanedVoterHistory.joined())' WHERE `state_boe_012219`.`SBOEID` = '\(row[0])';")            
        }
    }
    
    if debugOutput == true {
       print("\n\n\(uniqueHistoryItems.count) unique history items")
    }
}

// The first argument is always the executable, drop it
let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

let parser = ArgumentParser(usage: "<options>", overview: "NY State Board of Elections Tools")
let debug: OptionArgument<Bool> = parser.add(option: "--debug", shortName: "-do", kind: Bool.self, usage: "Debug output")
let cleanfile: OptionArgument<String> = parser.add(option: "--cleanfile", shortName:"-c", kind: String.self, usage: "Path CSV from NYSBOE to clean")
let showuniques: OptionArgument<String> = parser.add(option: "--showuniques", shortName:"-su", kind: String.self, usage: "Path CSV from NYSBOE to process")

func processArguments(arguments: ArgumentParser.Result) {
    let debugValue : Bool? = arguments.get(debug)
    if let path = arguments.get(cleanfile) {
        cleanFile(path, debugValue)
    }
    if let path = arguments.get(showuniques) {
        uniqueHistoryItems(path, debugValue)
    }
}

do {
    let parsedArguments = try parser.parse(arguments)
    processArguments(arguments: parsedArguments)
}
catch let error as ArgumentParserError {
    print(error.description)
}
catch let error {
    print(error.localizedDescription)
}
