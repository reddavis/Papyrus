//
//  Integer+Extension.swift
//  PapyrusTests
//
//  Created by Red Davis on 21/12/2020.
//

import Foundation


extension Int
{
    func times(_ closure: () throws -> Void) rethrows
    {
        for _ in 0..<self { try closure() }
    }
}
