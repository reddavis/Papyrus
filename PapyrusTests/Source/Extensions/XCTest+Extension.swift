//
//  XCTest+Extension.swift
//  PapyrusTests
//
//  Created by Red Davis on 17/12/2020.
//

import XCTest


extension XCTest
{
    func expectToEventually(
        _ test: @autoclosure () -> Bool,
        timeout: TimeInterval = 1.0,
        message: String = ""
    )
    {
        self.expectToEventually(test, timeout: timeout, message: message)
    }
    
    // Thanks to: https://www.vadimbulavin.com/swift-asynchronous-unit-testing-with-busy-assertion-pattern/
    func expectToEventually(
        _ test: () -> Bool,
        timeout: TimeInterval = 1.0,
        message: String = ""
    )
    {
        let runLoop = RunLoop.current
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        repeat
        {
            if test()
            {
                return
            }
            
            runLoop.run(until: Date(timeIntervalSinceNow: 0.01))
        } while Date().compare(timeoutDate) == .orderedAscending
        
        XCTFail(message)
    }
    
    func expectToEventuallyThrow(
        _ test: () throws -> Void,
        timeout: TimeInterval = 1.0,
        message: String = ""
    )
    {
        let runLoop = RunLoop.current
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        repeat
        {
            do
            {
                try test()
                runLoop.run(until: Date(timeIntervalSinceNow: 0.01))
            }
            catch
            {
                return
            }
        } while Date().compare(timeoutDate) == .orderedAscending
        
        XCTFail(message)
    }
    
    func expectToEventuallyReturn<T>(
        _ test: @autoclosure () -> T?,
        timeout: TimeInterval = 1.0,
        message: String = ""
    ) throws -> T
    {
        let runLoop = RunLoop.current
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        repeat
        {
            if let object = test()
            {
                return object
            }
            
            runLoop.run(until: Date(timeIntervalSinceNow: 0.01))
        } while Date().compare(timeoutDate) == .orderedAscending
        
        XCTFail(message)
        throw ExpectToEventuallyError.objectNeverReturned
    }
}


// MARK: Expect eventually error

extension XCTest
{
    enum ExpectToEventuallyError: Error
    {
        case objectNeverReturned
    }
}
