//
//  File.swift
//  
//
//  Created by Stuart A. Malone on 3/23/23.
//

import Foundation
import LinguaFranca
import Vapor

public extension RequestMethod {
    var httpMethod: HTTPMethod {
        switch self {
        case .DELETE:
            return .DELETE
        case .GET:
            return .GET
        case .PATCH:
            return .PATCH
        case .POST:
            return .POST
        case .PUT:
            return .PUT
        }
    }
}

public extension RoutesBuilder {
    func add<ActionType: ServerAction>(action: ActionType, _ fun: @escaping () async throws -> () ) where ActionType.ResponseType == None, ActionType.RequestBodyType == None {
        self.on(ActionType.method.httpMethod, ActionType.pathComponents) { (request) async throws in
            try await fun()
            return HTTPStatus.ok
        }
    }
    
    func add<ActionType: ServerAction>(action: ActionType, _ fun: @escaping () async throws -> ActionType.ResponseType ) where ActionType.ResponseType: AsyncResponseEncodable, ActionType.RequestBodyType == None {
        self.on(ActionType.method.httpMethod, ActionType.pathComponents) { (request) async throws in
            try await fun()
        }
    }
    
    func add<ActionType: ServerAction>(action: ActionType, _ fun: @escaping (ActionType.RequestBodyType) async throws -> () ) where ActionType.ResponseType == None, ActionType.RequestBodyType: Decodable {
        self.on(ActionType.method.httpMethod, ActionType.pathComponents) { (request) async throws in
            guard var buffer = request.body.data,
                  let body = try buffer.readJSONDecodable(ActionType.RequestBodyType.self,
                                                          decoder: JSONDecoder(),
                                                          length: buffer.readableBytes) else {
                return HTTPStatus.badRequest
            }
            
            try await fun(body)
            return HTTPStatus.ok
        }
    }
    
    func add<ActionType: ServerAction>(action: ActionType, _ fun: @escaping (ActionType.RequestBodyType) async throws -> ActionType.ResponseType ) where ActionType.ResponseType: AsyncResponseEncodable, ActionType.RequestBodyType: Decodable {
        self.on(ActionType.method.httpMethod, ActionType.pathComponents) { (request) async throws in
            guard var buffer = request.body.data,
                  let body = try buffer.readJSONDecodable(ActionType.RequestBodyType.self,
                                                          decoder: JSONDecoder(),
                                                          length: buffer.readableBytes) else {
                throw Abort(.badRequest)
            }
            
            return try await fun(body)
        }
    }
}
