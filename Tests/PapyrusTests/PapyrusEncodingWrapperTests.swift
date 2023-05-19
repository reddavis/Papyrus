import XCTest
@testable import Papyrus

final class PapyrusEncodingWrapperTests: XCTestCase {
    func test_initialization() throws {
        let id = "something"
        let object = ExampleB(id: id)
        let wrapper = PapyrusEncodingWrapper(object)
        
        XCTAssertEqual(wrapper.typeDescription, "ExampleB")
        XCTAssertEqual(wrapper.filename, id)
    }
}
