import Foundation

#if os(Linux)
func autoreleasepool(_ closure: () -> Void) {
   closure()
}
#endif
