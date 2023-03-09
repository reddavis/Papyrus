import Foundation

/// `PapyrusStore.CollectionQuery<T>` is a mechanism for querying `Papyrus` objects.
public class CollectionQuery<T> where T: Papyrus {
    public typealias OnFilter = (T) throws -> Bool
    public typealias OnSort = (T, T) throws -> Bool
    
    // Private
    private let fileManager = FileManager.default
    private let directoryURL: URL
    private var filter: OnFilter?
    private var sort: OnSort?
    private let decoder: JSONDecoder
    
    // MARK: Initialization
    
    init(directoryURL: URL, decoder: JSONDecoder = JSONDecoder()) {
        self.directoryURL = directoryURL
        self.decoder = decoder
    }
    
    // MARK: API
     
    /// Executes the query. If filter or sort parameters are
    /// set, they will be applied to the results.
    /// - Returns: The results of the query.
    public func execute() async -> [T] {
        guard let filenames = try? self.fileManager.contentsOfDirectory(atPath: self.directoryURL.path)
        else { return [] }
        
        var results: [(Date, T)] = []
        for filename in filenames {
            let url = self.directoryURL.appendingPathComponent(filename)
            do {
                let data = try Data(contentsOf: url)
                let model = try decoder.decode(T.self, from: data)
                let modifiedDate = try self.fileManager.attributesOfItem(
                    atPath: url.path
                )[.creationDate] as? Date ?? .now
                results.append((modifiedDate, model))
            } catch {
                continue
            }
        }
        
        do {
            return try results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
                .filter(self.filter)
                .sorted(by: self.sort)
        } catch {
            return []
        }
    }
    
    /// Apply a filter to the query.
    /// - Parameter onFilter: The filter to be applied.
    /// - Returns: The query item.
    @discardableResult
    public func filter(_ onFilter: @escaping OnFilter) -> Self {
        self.filter = onFilter
        return self
    }
    
    /// Apply a sort to the query.
    /// - Parameter onSort: The sort to be applied.
    /// - Returns: The query item.
    @discardableResult
    public func sort(_ onSort: @escaping OnSort) -> Self {
        self.sort = onSort
        return self
    }
    
    /// Observe changes to the query.
    /// - Returns: A `AsyncThrowingStream` instance.
    public func stream() -> AsyncThrowingStream<[T], Error> {
        let url = self.directoryURL
        
        return AsyncThrowingStream { continuation in
            let observer = ObjectCollectionObserver<T>(
                url: url,
                onChange: { objects in
                    do {
                        var results = try objects.filter(self.filter)
                        results = try results.sorted(by: self.sort)
                        continuation.yield(results)
                    } catch {
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
