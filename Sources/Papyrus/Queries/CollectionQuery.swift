import Foundation

/// `PapyrusStore.CollectionQuery<T>` is a mechanism for querying `Papyrus` objects.
public class CollectionQuery<T> where T: Papyrus {
    public typealias OnFilter = (T) -> Bool
    public typealias OnSort = (T, T) -> Bool
    
    // Private
    private let decoder: JSONDecoder = .init()
    private let directoryURL: URL
    private let fileManager = FileManager.default
    private var filter: OnFilter?
    private let logger: Logger
    private var sort: OnSort?
    
    // MARK: Initialization
    
    init(directoryURL: URL, logLevel: LogLevel = .off) {
        self.directoryURL = directoryURL
        self.logger = Logger(
            subsystem: "com.reddavis.PapyrusStore",
            category: "CollectionQuery",
            logLevel: logLevel
        )
    }
    
    // MARK: API
     
    /// Executes the query. If filter or sort parameters are
    /// set, they will be applied to the results.
    /// - Returns: The results of the query.
    public func execute() -> [T] {
        self.fetchObjects()
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
                .map { _ in self.fetchObjects() }
                .eraseToThrowingStream()
        } catch {
            return Fail(error: error)
                .eraseToThrowingStream()
        }
    }
    
    private func fetchObjects() -> [T] {
        do {
            let filenames = try self.fileManager.contentsOfDirectory(atPath: self.directoryURL.path)
            return filenames.reduce(into: [(Date, T)]()) { result, filename in
                do {
                    let url = self.directoryURL.appendingPathComponent(filename)
                    let data = try Data(contentsOf: url)
                    let model = try self.decoder.decode(T.self, from: data)
                    let modifiedDate = try self.fileManager.attributesOfItem(
                        atPath: url.path
                    )[.creationDate] as? Date ?? .now
                    result.append((modifiedDate, model))
                } catch {
                    self.logger.error("Failed to read cached data. error: \(error)")
                }
            }
            .sorted { $0.0 < $1.0 }
            .map(\.1)
            .filter(self.filter)
            .sorted(by: self.sort)
        } catch CocoaError.fileReadNoSuchFile {
            self.logger.info("Failed to read contents of directory. url: \(self.directoryURL)")
            return []
        } catch {
            self.logger.fault("Unknown error occured. error: \(error)")
            return []
        }
    }
}

// MARK: Sequence

extension Sequence {
    fileprivate func filter(_ isIncluded: ((Element) -> Bool)?) -> [Element] {
        guard let isIncluded = isIncluded else { return Array(self) }
        return self.filter { isIncluded($0) }
    }
    
    fileprivate func sorted(by areInIncreasingOrder: ((Element, Element) -> Bool)?) -> [Element] {
        guard let areInIncreasingOrder = areInIncreasingOrder else { return Array(self) }
        return self.sorted { areInIncreasingOrder($0, $1) }
    }
}
