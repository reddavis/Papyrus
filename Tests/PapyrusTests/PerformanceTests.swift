import XCTest
@testable import Papyrus

final class PerformanceTests: XCTestCase {
    func test_save() async {
        let objects = (0..<10000).map { _ in
            ExampleB(id: UUID().uuidString)
        }
        
        self.measure {
            let expectation = expectation(description: "Finished")
            Task {
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let url = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
                
                let store = PapyrusStore(url: url)
                try await store.save(objects: objects)
                expectation.fulfill()
            }
            self.wait(for: [expectation])
        }
    }

    func test_delete() async {
        let objects = (0..<10000).map { _ in
            ExampleB(id: UUID().uuidString)
        }
        
        self.measure {
            let expectation = expectation(description: "Finished")
            Task {
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let url = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
                
                let store = PapyrusStore(url: url)
                try await store.save(objects: objects)
                try await store.delete(objects: objects)
                expectation.fulfill()
            }
            self.wait(for: [expectation])
        }
    }
}
