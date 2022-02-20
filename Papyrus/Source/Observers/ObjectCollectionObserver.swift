import Foundation


final class ObjectCollectionObserver<Output: Papyrus> {
    private let fileManager = FileManager.default
    private let url: URL
    private let decoder: JSONDecoder

    private var directoryObserver: DirectoryObserver?
    private let onChange: (_ objects: [Output]) -> Void
    
    // MARK: Initialization
    
    init(
        url: URL,
        decoder: JSONDecoder = JSONDecoder(),
        onChange: @escaping (_ objects: [Output]) -> Void
    ) {
        self.url = url
        self.decoder = decoder
        self.onChange = onChange
    }
    
    // MARK: Setup
    
    func start() {
        self.onChange(self.fetchObjects())
        
        self.directoryObserver = DirectoryObserver(
            url: self.url,
            onChange: { [weak self] _ in
                guard let self = self else { return }
                self.onChange(self.fetchObjects())
            }
        )
        self.directoryObserver?.start()
    }
    
    // MARK: Subscriber
    
    func cancel() {
        self.directoryObserver?.cancel()
        self.directoryObserver = nil
    }
    
    // MARK: Data
    
    private func fetchObjects() -> [Output] {
        guard let directoryNames = try? self.fileManager.contentsOfDirectory(atPath: self.url.path) else { return [] }
        
        return directoryNames
            .map { self.url.appendingPathComponent($0) }
            .compactMap {
                do {
                    let data = try Data(contentsOf: $0)
                    return try decoder.decode(Output.self, from: data)
                } catch {
                    // Cached data is using an old schema.
                    return nil
                }
            }
    }
}
