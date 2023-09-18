import Foundation
@testable import Papyrus

struct ExampleD: Papyrus {
    var id: String = UUID().uuidString
    var value: String = UUID().uuidString
    var integerValue: Int = 1
}
