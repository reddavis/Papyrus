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
                
                var store = PapyrusStore(url: url)
                store.logLevel = .off
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
                
                var store = PapyrusStore(url: url)
                store.logLevel = .off
                try await store.save(objects: objects)
                await store.delete(objects: objects)
                expectation.fulfill()
            }
            self.wait(for: [expectation])
        }
    }
    
    func test__delete() async {
        let objects = (0..<10000).map { _ in
            ExampleB(id: UUID().uuidString)
        }
        
        self.measure {
            let expectation = expectation(description: "Finished")
            Task {
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let url = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
                
                var store = PapyrusStore(url: url)
                store.logLevel = .off
                try await store.save(objects: objects)
                try await store._delete(objects: objects)
                expectation.fulfill()
            }
            self.wait(for: [expectation])
        }
    }
}
