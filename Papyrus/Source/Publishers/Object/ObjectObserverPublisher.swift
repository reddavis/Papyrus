#if canImport(Combine)

import Combine
import Foundation


struct ObjectObserverPublisher<T>: Publisher where T: Papyrus & Equatable {
    typealias Output = T
    typealias Failure = PapyrusStore.QueryError
    
    // Private
    private let filename: String
    private let directoryURL: URL
    
    // MARK: Initialization
    
    init(filename: String, directoryURL: URL) {
        self.filename = filename
        self.directoryURL = directoryURL
    }
    
    // MARK: Publisher
    
    func receive<S: Subscriber>(subscriber: S) where Self.Failure == S.Failure, Self.Output == S.Input {
        let subscription = ObjectObserverSubscription(
            filename: self.filename,
            directoryURL: self.directoryURL,
            subscriber: subscriber
        )
        subscriber.receive(subscription: subscription)
    }
}
#endif
