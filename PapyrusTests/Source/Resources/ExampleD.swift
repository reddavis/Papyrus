import Foundation
@testable import Papyrus


struct ExampleD: Papyrus
{
    var id: String
    var value: String
    var integerValue: Int
    
    // MARK Initialization
    
    init(
        id: String,
        value: String = UUID().uuidString,
        integerValue: Int = 0
    )
    {
        self.id = id
        self.value = value
        self.integerValue = integerValue
    }
}
