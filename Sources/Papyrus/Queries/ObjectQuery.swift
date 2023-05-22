import Foundation

/// `ObjectQuery<T>` is a mechanism for querying a single `Papyrus` object.
public class ObjectQuery<T: Papyrus> {
    private let fileManager = FileManager.default
    private let filename: String
    private let directoryURL: URL
    private let decoder: JSONDecoder = .init()
    
    // MARK: Initialization
    
    init<ID: LosslessStringConvertible>(
        id: ID,
        directoryURL: URL
    ) {
        self.filename = String(id)
        self.directoryURL = directoryURL
    }
    
    // MARK: API
    
    /// Executes the query. If filter or sort parameters are
    /// set, they will be applied to the results.
    /// - Returns: The results of the query.
    public func execute() throws -> T {
        switch self.fetchObject() {
        case .success(let object):
            return object
        case .failure(let error):
            throw error
        }
    }
        
    /// Observe changes to the query via an async stream.
    /// - Returns: A `AsyncThrowingStream` instance.
    public func observe() -> AsyncThrowingStream<ObjectChange<T>, Error> {
        var previousResult = self.fetchObject()
        do {
            let observer = try DirectoryObserver(url: self.directoryURL)
            return observer.observe()
                .compactMap { _ in
                    let result = self.fetchObject()
                    defer { previousResult = result }
                    
                    switch (previousResult, result) {
                    case (.success(let previousModel), .success(let model)) where previousModel != model:
                        return .changed(model)
                    case (.success, .failure(let error)):
                        if case PapyrusStore.QueryError.notFound = error {
                            return .deleted
                        } else {
                            throw error
                        }
                    case (.failure(let error), .success(let model)):
                        if case PapyrusStore.QueryError.notFound = error {
                            return .created(model)
                        } else {
                            return nil
                        }
                    default:
                        return nil
                    }
                }
                .eraseToThrowingStream()
        } catch {
            return Fail(error: error)
                .eraseToThrowingStream()
        }
    }
    
    private func fetchObject() -> Result<T, Error> {
        let fileURL = self.directoryURL.appendingPathComponent(self.filename)
        guard self.fileManager.fileExists(atPath: fileURL.path) else {
            return .failure(PapyrusStore.QueryError.notFound)
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return .success(try decoder.decode(T.self, from: data))
        } catch {
            // Cached data is using an old schema.
            return .failure(PapyrusStore.QueryError.invalidSchema(details: error))
        }
    }
}
