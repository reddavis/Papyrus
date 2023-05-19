import Foundation

struct DirectoryObserver: Sendable {
    private let url: URL
    
    // MARK: Initialization
    
    init(url: URL) throws {
        self.url = url
        
        if !FileManager.default.fileExists(atPath: self.url.path) {
            try FileManager.default.createDirectory(at: self.url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: Setup
    
    func observe() -> AsyncStream<Void> {
        AsyncStream { [url] continuation in
            let queue = DispatchQueue(
                label: "com.reddavis.DirectoryObserver.directoryObserverDispatchQueue.\(UUID())",
                qos: .default
            )
            let fileDesciptor = open(url.path, O_EVTONLY)
            let directoryObserver = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileDesciptor,
                eventMask: [.attrib],
                queue: queue
            )
            directoryObserver.setEventHandler {
                continuation.yield()
            }
            continuation.onTermination = { _ in
                directoryObserver.cancel()
            }
            directoryObserver.resume()
        }
    }
}
