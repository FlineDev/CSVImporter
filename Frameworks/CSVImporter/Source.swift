import Foundation

let chunkSize = 4_096

protocol Source {
   func forEach(_ closure: (String) -> Void)
}
