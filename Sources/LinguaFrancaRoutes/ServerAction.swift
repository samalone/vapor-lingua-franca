//
//  File.swift
//  
//
//  Created by Stuart A. Malone on 3/24/23.
//

import Foundation
import LinguaFranca
import Vapor

public extension ServerAction {
    static var pathComponents: [PathComponent] {
        return Self.path.map {
            switch $0 {
            case .constant(let string):
                return PathComponent(stringLiteral: string)
            case .param(let keyPath):
                return .parameter("foo")
            }
        }
    }
}
