//
//  ExampleC.swift
//  PapyrusTests
//
//  Created by Red Davis on 24/12/2020.
//

import Foundation
@testable import Papyrus


struct ExampleC: Papyrus
{
    let id: String
    let children: [ExampleB]
}
