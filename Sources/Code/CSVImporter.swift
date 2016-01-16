//
//  CSVImporter.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 13.01.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//

import Foundation
import FileKit
import HandySwift

public class CSVImporter<T> {
    
    // MARK: - Stored Instance Properties
    
    let csvFile: TextFile
    let delimiter: String
    
    var lastProgressReport: NSDate?
    
    var progressClosure: ((importedDataLinesCount: Int) -> Void)?
    var finishClosure: ((importedRecords: [T]) -> Void)?
    var failClosure: (() -> Void)?
    
    
    // MARK: - Computes Instance Properties
    
    var shouldReportProgress: Bool {
        get {
            return self.progressClosure != nil &&
                (self.lastProgressReport == nil || NSDate().timeIntervalSinceDate(self.lastProgressReport!) > 0.1)
        }
    }
    
    
    // MARK: - Initializers
    
    public init(path: String, delimiter: String = ",") {

        self.csvFile = TextFile(path: Path(path))
        self.delimiter = delimiter
        
    }
    
    
    // MARK: - Instance Methods
    
    public func startImportingRecords(mapper closure: (recordValues: [String]) -> T) -> Self {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            var importedRecords: [T] = []
            
            let importedLinesWithSuccess = self.importLines { valuesInLine in
                
                let newRecord = closure(recordValues: valuesInLine)
                importedRecords.append(newRecord)
                
                self.reportProgressIfNeeded(importedRecords)
                
            }
            
            if importedLinesWithSuccess {
                self.reportFinish(importedRecords)
            } else {
                self.reportFail()
            }
            
        }
        
        return self
        
    }
    
    public func startImportingRecords(structure structureClosure: (headerValues: [String]) -> Void, recordMapper closure: (recordValues: [String: String]) -> T) -> Self {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            var recordStructure: [String]?
            var importedRecords: [T] = []
            
            let importedLinesWithSuccess = self.importLines { valuesInLine in
                
                if recordStructure == nil {
                    
                    recordStructure = valuesInLine
                    structureClosure(headerValues: valuesInLine)
                    
                } else {

                    if let structuredValuesInLine = [String: String](keys: recordStructure!, values: valuesInLine) {
                        
                        let newRecord = closure(recordValues: structuredValuesInLine)
                        importedRecords.append(newRecord)
                        
                        self.reportProgressIfNeeded(importedRecords)
                        
                    } else {
                        print("Warning: Couldn't structurize line.")
                    }
                    
                }
                
            }
            
            if importedLinesWithSuccess {
                self.reportFinish(importedRecords)
            } else {
                self.reportFail()
            }
            
        }
        
        return self
        
    }
    
    // Imports all lines one by one and returns true on finish, or returns false if can't read file
    func importLines(closure: (valuesInLine: [String]) -> Void) -> Bool {
        
        if let csvStreamReader = self.csvFile.streamReader() {
            
            for line in csvStreamReader {
                
                let valuesInLine = line.componentsSeparatedByString(self.delimiter)
                closure(valuesInLine: valuesInLine)
                
            }
            
            return true
            
        } else {
            
            return false
            
        }
        
    }
    
    public func onFail(closure: () -> Void) -> Self {
        
        self.failClosure = closure
        
        return self
        
    }
    
    public func onProgress(closure: (importedDataLinesCount: Int) -> Void) -> Self {
        
        self.progressClosure = closure
        
        return self
    }
    
    public func onFinish(closure: (importedRecords: [T]) -> Void) {
        
        self.finishClosure = closure
        
    }
    
    
    // MARK: - Helper Methods
    
    func reportFail() {
        
        if let failClosure = self.failClosure {
            
            dispatch_async(dispatch_get_main_queue()) {
                failClosure()
            }
            
        }
        
    }
    
    func reportProgressIfNeeded(importedRecords: [T]) {
        
        if self.shouldReportProgress {
            
            self.lastProgressReport = NSDate()
            if let progressClosure = self.progressClosure {
                
                dispatch_async(dispatch_get_main_queue()) {
                    progressClosure(importedDataLinesCount: importedRecords.count)
                }
                
            }

        }
        
    }
    
    func reportFinish(importedRecords: [T]) {
        
        if let finishClosure = self.finishClosure {
            
            dispatch_async(dispatch_get_main_queue()) {
                finishClosure(importedRecords: importedRecords)
            }
            
        }
        
    }


}
