//
//  StringSource.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 10.12.17.
//  Copyright © 2017 Flinesoft. All rights reserved.
//

import Foundation

class StringSource: Source {
    private let lines: [String]

    init(contentString: String, lineEnding: LineEnding) {
        let correctedLineEnding: LineEnding = {
            if lineEnding == .unknown {
                if contentString.contains(LineEnding.carriageReturnLineFeed.rawValue) {
                    return .carriageReturnLineFeed
                } else if contentString.contains(LineEnding.newLine.rawValue) {
                    return .newLine
                } else if contentString.contains(LineEnding.carriageReturn.rawValue) {
                    return .carriageReturn
                }
            }

            return lineEnding
        }()

        lines = contentString.components(separatedBy: correctedLineEnding.rawValue)
    }

    func forEach(_ closure: (String) -> Void) {
        lines.forEach(closure)
    }
}
