//
//  CSVImporter.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 13.01.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//

import Foundation
import FileKit

public class CSVImporter<T> {
    
    // MARK: - Stored Instance Properties
    
    let csvFile: TextFile
    let delimiter: String
    
    var startedGenerating: NSDate?
    var lastProgressReport: NSDate?
    
    var progressClosure: ((importedDataLinesCount: Int) -> Void)?
    var finishClosure: ((importedRecords: [T]) -> Void)?
    var failClosure: (() -> Void)?
    
    
    // MARK: - Computes Instance Properties
    
    var generationHasStarted: Bool {
        get {
            return self.startedGenerating != nil
        }
    }
    
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
    
    public func startImportingWithMapper(closure: (readValuesInLine: [String]) -> T) -> Self {
        
        self.startedGenerating = NSDate()
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {

            if let csvStreamReader = self.csvFile.streamReader() {
                
                var importedRecords: [T] = []
                
                for line in csvStreamReader {
                    
                    let readValuesInLine = line.componentsSeparatedByString(self.delimiter)
                    let newRecord = closure(readValuesInLine: readValuesInLine)
                    
                    importedRecords.append(newRecord)
                    
                    if self.shouldReportProgress {
                        
                        self.reportProgress(importedRecords)
                        self.lastProgressReport = NSDate()
                        
                    }
                }
                
            } else {
                
                self.failClosure?()
                
            }
            
        }
        
        return self
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
    
    func reportProgress(importedRecords: [T]) {
        
        if let progressClosure = self.progressClosure {
            
            dispatch_async(dispatch_get_main_queue()) {
                
                progressClosure(importedDataLinesCount: importedRecords.count)
                
            }
            
        }
        
    }


}
