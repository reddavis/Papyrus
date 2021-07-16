import Foundation
@testable import Papyrus


struct ExampleA: Papyrus
{
    var id: String
    @HasOne var test: ExampleB
}
