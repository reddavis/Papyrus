import Foundation

final class ObjectObserver<Output: Papyrus>: @unchecked Sendable {
    private var fileManager: FileManager { .default }
    private let filename: String
    private let directoryURL: URL
    @Atomic private var previousFetch: Result<Output, PapyrusStore.QueryError>?
    private let decoder: JSONDecoder
    
    private var directoryObserver: DirectoryObserver?
    private let onChange: (_ result: Result<Output, PapyrusStore.QueryError>) -> Void
    
    // MARK: Initialization
    
    init(
        filename: String,
        directoryURL: URL,
        decoder: JSONDecoder = JSONDecoder(),
        onChange: @escaping (_ result: Result<Output, PapyrusStore.QueryError>) -> Void
    ) {
        self.filename = filename
        self.directoryURL = directoryURL
        self.decoder = decoder
        self.onChange = onChange
    }
    
    // MARK: Setup
    
    func start() {
        self.processChange()
        
        self.directoryObserver = DirectoryObserver(
            url: directoryURL,
            onChange: { [weak self] _ in
                self?.processChange()
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
    
    private func processChange() {
        do {
            let object = try self.fetchObject()
            
            // Check the object has changed
            switch self.previousFetch {
            case .success(let previousObject) where previousObject == object:
                return
            default:
                self.previousFetch = .success(object)
                self.onChange(.success(object))
            }
        } catch let error as PapyrusStore.QueryError {
            switch self.previousFetch {
            case .success, .none:
                self.previousFetch = .failure(error)
                self.onChange(.failure(error))
            case .failure:
                return
            }
        }
        catch { } // Only `PapyrusStore.QueryError` thrown
    }
    
    private func fetchObject() throws -> Output {
        let fileURL = self.directoryURL.appendingPathComponent(self.filename)
        guard self.fileManager.fileExists(atPath: fileURL.path) else { throw PapyrusStore.QueryError.notFound }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(Output.self, from: data)
        } catch {
            throw PapyrusStore.QueryError.invalidSchema(details: error)
        }
    }
}
