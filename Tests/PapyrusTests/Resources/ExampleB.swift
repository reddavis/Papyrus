import Foundation
@testable import Papyrus

struct ExampleB: Papyrus {
    var id: String
    var value: String
    var integerValue: Int
    
    // MARK Initialization
    
    init(
        id: String,
        value: String = UUID().uuidString,
        integerValue: Int = 0
    ) {
        self.id = id
        self.value = value
        self.integerValue = integerValue
    }
    
    // MARK: Data
    
    func write(to url: URL) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let url = url.appendingPathComponent(self.id)
        try data.write(to: url)
    }
    
    func remove(from url: URL) throws {
        try FileManager.default.removeItem(at: url.appendingPathComponent(self.id))        
    }
}
