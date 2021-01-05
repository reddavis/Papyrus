//
//  ObserverPublisher.swift
//  Papyrus
//
//  Created by Red Davis on 23/12/2020.
//

import Combine
import Foundation


extension PapyrusStore
{
    struct ObserverPublisher<T>: Publisher where T: Papyrus
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
        
        func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
        {
            let subscription = ObserverSubscription(directoryURL: self.directoryURL, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }
}
