import Foundation

final class DirectoryObserver {
    private let fileManager = FileManager.default
    private let url: URL
    
    private let directoryObserverDispatchQueue = DispatchQueue(
        label: "com.reddavis.DirectoryObserver.directoryObserverDispatchQueue.\(UUID())",
        qos: .utility
    )
    private var directoryObserver: DispatchSourceFileSystemObject?
    private let onChange: (_ directoryURL: URL) -> Void
    
    // MARK: Initialization
    
    init(
        url: URL,
        onChange: @escaping (_ url: URL) -> Void
    ) {
        self.url = url
        self.onChange = onChange
    }
    
    // MARK: Setup
    
    func start() {
        if !self.fileManager.fileExists(atPath: self.url.path) {
            try? self.fileManager.createDirectory(at: self.url, withIntermediateDirectories: true)
        }
        
        let fileDesciptor = open(self.url.path, O_EVTONLY)
        self.directoryObserver = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDesciptor,
            eventMask: [.attrib],
            queue: self.directoryObserverDispatchQueue
        )
        
        self.directoryObserver?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.onChange(self.url)
        }
        
        self.directoryObserver?.resume()
    }
    
    // MARK: Subscriber
    
    func cancel() {
        self.directoryObserver?.cancel()
        self.directoryObserver = nil
    }
}
