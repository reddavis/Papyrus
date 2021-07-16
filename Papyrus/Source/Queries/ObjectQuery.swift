import Combine
import Foundation


/// `PapyrusStore.ObjectQuery<T>` is a mechanism for querying a single `Papyrus` object.
public extension PapyrusStore
{
    class ObjectQuery<T: Papyrus>
    {
        // Private
        private let fileManager = FileManager.default
        private let filename: String
        private let directoryURL: URL
        
        // MARK: Initialization
        
        init<ID: LosslessStringConvertible>(
            id: ID,
            directoryURL: URL
        )
        {
            self.filename = String(id)
            self.directoryURL = directoryURL
        }
        
        // MARK: API
        
        /// Executes the query. If filter or sort parameters are
        /// set, they will be applied to the results.
        /// - Returns: The results of the query.
        public func execute() async throws -> T
        {
            let fileURL = self.directoryURL.appendingPathComponent(self.filename)
            guard self.fileManager.fileExists(atPath: fileURL.path) else { throw PapyrusStore.QueryError.notFound }
            
            do
            {
                let data = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(T.self, from: data)
            }
            catch
            {
                // Cached data is using an old schema.
                try? self.fileManager.removeItem(at: fileURL)
                throw PapyrusStore.QueryError.notFound
            }
        }
        
        /// Observe changes to the query via a publisher.
        /// - Returns: A publisher that emits values when
        /// valid objects are changed.
        public func publisher() -> AnyPublisher<T, PapyrusStore.QueryError>
        {
            ObjectObserverPublisher(
                filename: self.filename,
                directoryURL: self.directoryURL
            )
            .eraseToAnyPublisher()
        }
        
        /// Observe changes to the query via an async stream.
        /// - Returns: A `AsyncThrowingStream` instance.
        public func stream() -> AsyncThrowingStream<T, Error>
        {
            let filename = self.filename
            let directoryURL = self.directoryURL
            
            return AsyncThrowingStream<T, Error> { continuation in
                let observer = ObjectFileObserver<T>(
                    filename: filename,
                    directoryURL: directoryURL,
                    onChange: { result in
                        switch result
                        {
                        case .success(let object):
                            continuation.yield(object)
                        case .failure(let error):
                            continuation.finish(throwing: error)
                        }
                    }
                )
                
                continuation.onTermination = { @Sendable _ in
                    observer.cancel()
                }
                
                observer.start()
            }
        }
    }
}
