#if canImport(Combine)
import Combine
import Foundation


final class CollectionObserverSubscription<T: Subscriber, Output: Papyrus>: Subscription
where T.Input == [Output] {
    // Private
    private let fileManager = FileManager.default
    private let directoryURL: URL
    private var subscriber: T?
    private var demand: Subscribers.Demand = .none
    private var observer: DirectoryObserver?
    private let decoder: JSONDecoder
    
    // MARK: Initialization
    
    init(directoryURL: URL, subscriber: T, decoder: JSONDecoder = JSONDecoder()) {
        self.directoryURL = directoryURL
        self.subscriber = subscriber
        self.decoder = decoder
    }
    
    // MARK: Subscriber
    
    func cancel() {
        self.subscriber = nil
        self.observer?.cancel()
    }
    
    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
        self.processChange()
        
        self.observer = DirectoryObserver(
            url: self.directoryURL,
            onChange: { [weak self] _ in
                self?.processChange()
            }
        )
        self.observer?.start()
    }
    
    // MARK: Data
    
    private func processChange() {
        guard let subscriber = self.subscriber else { return }
        
        guard self.demand > 0 else {
            subscriber.receive(completion: .finished)
            return
        }
        
        self.demand -= 1
        self.demand += subscriber.receive(self.fetchModels())
    }
    
    private func fetchModels() -> [Output] {
        guard let directoryNames = try? self.fileManager.contentsOfDirectory(atPath: self.directoryURL.path) else { return [] }
        
        return directoryNames
            .map { self.directoryURL.appendingPathComponent($0) }
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
#endif
