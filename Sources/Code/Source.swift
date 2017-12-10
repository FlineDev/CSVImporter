//
//  Source.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 10.12.17.
//  Copyright © 2017 Flinesoft. All rights reserved.
//

import Foundation

let chunkSize = 4_096

protocol Source {
    func forEach(_ closure: (String) -> Void)
}
