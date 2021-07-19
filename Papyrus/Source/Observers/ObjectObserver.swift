import Foundation


final class ObjectObserver<Output: Papyrus>
{
    // Private
    private let fileManager = FileManager.default
    private let filename: String
    private let directoryURL: URL
    private var previousFetch: Result<Output, PapyrusStore.QueryError>?
    
    private var directoryObserver: DirectoryObserver?
    private let onChange: (_ result: Result<Output, PapyrusStore.QueryError>) -> Void
    
    // MARK: Initialization
    
    init(
        filename: String,
        directoryURL: URL,
        onChange: @escaping (_ result: Result<Output, PapyrusStore.QueryError>) -> Void
    )
    {
        self.filename = filename
        self.directoryURL = directoryURL
        self.onChange = onChange
    }
    
    // MARK: Setup
    
    func start()
    {
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
    
    func cancel()
    {
        self.directoryObserver?.cancel()
        self.directoryObserver = nil
    }
    
    // MARK: Data
    
    private func processChange()
    {
        do
        {
            let object = try self.fetchObject()
            
            // Check the object has changed
            guard self.previousFetch != .success(object) else { return }
            self.previousFetch = .success(object)
            self.onChange(.success(object))
        }
        catch let error as PapyrusStore.QueryError
        {
            guard self.previousFetch != .failure(error) else { return }
            self.previousFetch = .failure(error)
            self.onChange(.failure(error))
        }
        catch { } // Only `PapyrusStore.QueryError` thrown
    }
    
    private func fetchObject() throws -> Output
    {
        let fileURL = self.directoryURL.appendingPathComponent(self.filename)
        guard self.fileManager.fileExists(atPath: fileURL.path) else { throw PapyrusStore.QueryError.notFound }
        
        do
        {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(Output.self, from: data)
        }
        catch
        {
            // Cached data is using an old schema.
            try? self.fileManager.removeItem(at: fileURL)
            throw PapyrusStore.QueryError.notFound
        }
    }
}
