import Foundation

/// `ObjectQuery<T>` is a mechanism for querying a single `Papyrus` object.
public class ObjectQuery<T: Papyrus> {
    private let decoder: JSONDecoder = .init()
    private let directoryURL: URL
    private let fileManager = FileManager.default
    private let filename: String
    private let logger: Logger
    
    // MARK: Initialization
    
    init<ID: LosslessStringConvertible>(
        id: ID,
        directoryURL: URL,
        logLevel: LogLevel = .off
    ) {
        self.filename = String(id)
        self.directoryURL = directoryURL
        self.logger = Logger(
            subsystem: "com.reddavis.PapyrusStore",
            category: "ObjectQuery",
            logLevel: logLevel
        )
    }
    
    // MARK: API
    
    /// Executes the query.
    /// - Returns: The result of the query.
    public func execute() -> T? {
        switch self.fetchObject() {
        case .success(let object):
            return object
        case .failure:
            return nil
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
                    case (.success, .failure):
                        return .deleted
                    case (.failure, .success(let model)):
                        return .created(model)
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
            self.logger.info("Cached data not found. url: \(fileURL)")
            return .failure(NotFoundError())
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return .success(try decoder.decode(T.self, from: data))
        } catch {
            // Cached data is using an old schema.
            self.logger.error("Failed to parse cached data. url: \(fileURL)")
            do {
                // Delete cached data
                self.logger.debug("Deleting old cached data. url: \(fileURL)")
                try self.fileManager.removeItem(at: fileURL)
            } catch {
                self.logger.error("Failed deleting old cached data. url: \(fileURL) error: \(error)")
                return .failure(error)
            }
            return .failure(InvalidSchemaError(details: error))
        }
    }
}

// MARK: Errors

extension ObjectQuery {
    private struct NotFoundError: Error {}
    private struct InvalidSchemaError: Error {
        var details: Error
    }
}
