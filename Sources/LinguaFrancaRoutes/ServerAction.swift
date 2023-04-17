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
            case .param:
                return .parameter("foo")
            }
        }
    }
}

extension Request: RequestDataSource {
    public func getQueryData<ResultType: Decodable>(key: String) -> ResultType? {
        return self.query[key]
    }
    
    public func getParameter(name: String) -> String? {
        return self.parameters.get(name)
    }
    
    public func getBody() throws -> Data? {
        guard var buffer = self.body.data else { return nil }
        return buffer.readData(length: buffer.readableBytes)
    }
}

extension Request {
    public func getBody<T: Decodable>() throws -> T? {
        guard let data = try getBody() else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
