//
//  CSVImporter.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 13.01.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//

import Foundation

public class CSVImporter<T> {
    
    // MARK: - Stored Instance Properties
    
    let filePath: String
    
    var startedGenerating: NSDate?
    var lastProgressReport: NSDate?
    
    var importedRecords: [T] = []
    
    var progressClosure: ((importedDataLinesCount: Int, totalNumberOfDataLines: Int) -> Void)?
    var finishClosure: ((importedRecords: [T]) -> Void)?
    
    
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
    
    public init(filePath: String) {
        self.filePath = filePath
    }
    
    
    // MARK: - Instance Methods
    
    public func startImportingWithMapper(closure: (readValuesInLine: [String]) -> T) -> Self {
        
        self.startedGenerating = NSDate()
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {

            // TODO: read CSV file line
            
            let readValuesInLine: [String] = []
            
            let newImportedRecord = closure(readValuesInLine: readValuesInLine)
            self.importedRecords.append(newImportedRecord)
            
            if self.shouldReportProgress {
                
                self.reportProgress()
                self.lastProgressReport = NSDate()
                
            }
            
        }
        
        return self
    }
    
    public func onProgress(closure: (importedDataLinesCount: Int, totalNumberOfDataLines: Int) -> Void) -> Self {
        
        self.progressClosure = closure
        
        return self
    }
    
    public func onFinish(closure: (importedRecords: [T]) -> Void) {
        
        self.finishClosure = closure
        
    }
    
    func reportProgress() {
        
        
        
        if let progressClosure = self.progressClosure {
            
            dispatch_async(dispatch_get_main_queue()) {
                
                progressClosure(importedDataLinesCount: self.importedRecords.count, totalNumberOfDataLines: <#T##Int#>)
                
                progressClosure(currentDurationInSeconds: currentDurationInSeconds, currentQualityInPercent: currentQualityInPercent)
                
            }
            
        }
        
    }


}
