//
//  Created by Cihat Gündüz on 28.09.18.
//  Copyright © 2018 Flinesoft. All rights reserved.
//

import Foundation

#if os(Linux)
    func autoreleasepool(_ closure: () -> Void) {
        closure()
    }
#endif
