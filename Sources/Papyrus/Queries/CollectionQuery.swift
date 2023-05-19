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
    private let decoder: JSONDecoder = .init()
    
    // MARK: Initialization
    
    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }
    
    // MARK: API
     
    /// Executes the query. If filter or sort parameters are
    /// set, they will be applied to the results.
    /// - Returns: The results of the query.
    public func execute() throws -> [T] {
        try self.fetchObjects()
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
    public func observe() -> AsyncThrowingStream<[T], Error> {
        do {
            let observer = try DirectoryObserver(url: self.directoryURL)
            return observer.observe()
                .map { _ in try self.fetchObjects() }
                .eraseToThrowingStream()
        } catch {
            return Fail(error: error)
                .eraseToThrowingStream()
        }
    }
    
    private func fetchObjects() throws -> [T] {
        do {
            let filenames = try self.fileManager.contentsOfDirectory(atPath: self.directoryURL.path)
            return try filenames.reduce(into: [(Date, T)]()) { result, filename in
                let url = self.directoryURL.appendingPathComponent(filename)
                let data = try Data(contentsOf: url)
                let model = try decoder.decode(T.self, from: data)
                let modifiedDate = try self.fileManager.attributesOfItem(
                    atPath: url.path
                )[.creationDate] as? Date ?? .now
                result.append((modifiedDate, model))
            }
            .sorted { $0.0 < $1.0 }
            .map(\.1)
            .filter(self.filter)
            .sorted(by: self.sort)
        } catch CocoaError.fileReadNoSuchFile {
            return []
        } catch {
            throw error
        }
    }
}
