import Foundation
@testable import Papyrus

struct ExampleC: Papyrus {
    var id: String
    @HasMany var children: [ExampleB]
}
