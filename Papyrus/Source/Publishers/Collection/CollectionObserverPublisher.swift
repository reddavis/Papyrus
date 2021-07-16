import Combine
import Foundation


struct CollectionObserverPublisher<T>: Publisher where T: Papyrus
{
    // Internal
    typealias Output = [T]
    typealias Failure = Never
    
    // Private
    private let directoryURL: URL
    
    // MARK: Initialization
    
    init(directoryURL: URL)
    {
        self.directoryURL = directoryURL
    }
    
    // MARK: Publisher
    
    func receive<S: Subscriber>(subscriber: S) where Self.Failure == S.Failure, Self.Output == S.Input
    {
        let subscription = CollectionObserverSubscription(directoryURL: self.directoryURL, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}
