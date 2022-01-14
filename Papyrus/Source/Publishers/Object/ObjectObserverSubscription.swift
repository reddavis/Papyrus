import Combine
import Foundation


final class ObjectObserverSubscription<T: Subscriber, Output: Papyrus>: Subscription
where T.Input == Output,
      T.Failure == PapyrusStore.QueryError {
    // Private
    private let filename: String
    private let directoryURL: URL
    private var subscriber: T?
    private var demand: Subscribers.Demand = .none
    private var observer: ObjectObserver<Output>?
    
    // MARK: Initialization
    
    init(
        filename: String,
        directoryURL: URL,
        subscriber: T
    ) {
        self.filename = filename
        self.directoryURL = directoryURL
        self.subscriber = subscriber
    }
    
    // MARK: Subscriber
    
    func cancel() {
        self.subscriber = nil
        self.observer?.cancel()
    }
    
    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
        
        self.observer = ObjectObserver<Output>(
            filename: self.filename,
            directoryURL: self.directoryURL,
            onChange: { [weak self] result in
                self?.processResult(result)
            }
        )
        self.observer?.start()
    }
    
    // MARK: Data
    
    private func processResult(_ result: Result<Output, PapyrusStore.QueryError>) {
        guard let subscriber = self.subscriber else { return }
        guard self.demand > 0 else {
            subscriber.receive(completion: .finished)
            return
        }
        
        switch result {
        case .success(let object):
            self.demand -= 1
            self.demand += subscriber.receive(object)
        case .failure(let error):
            subscriber.receive(completion: .failure(error))
        }
    }
}
