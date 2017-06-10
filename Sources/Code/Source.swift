//
//  Source.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 10.12.17.
//  Copyright © 2017 Flinesoft. All rights reserved.
//

import Foundation

let chunkSize = 4096

// MARK: - Sub Types
protocol Source {
    func forEach(_ closure: (String) -> Void)
}
