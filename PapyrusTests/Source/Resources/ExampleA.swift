//
//  Example.swift
//  PapyrusTests
//
//  Created by Red Davis on 17/12/2020.
//

import Foundation
@testable import Papyrus


struct ExampleA: Papyrus
{
    var id: String
    @HasOne var test: ExampleB
}
