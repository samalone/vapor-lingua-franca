//
//  File.swift
//  
//
//  Created by Stuart A. Malone on 3/23/23.
//

import Foundation
import LinguaFranca
import Vapor
import URLQueryCoder

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
    
    func parseQuery<ActionType: ServerAction>(from request: Request, action: inout ActionType) throws {
        if let q = request.url.query {
            action.query = try URLQueryDecoder().decode(ActionType.QueryType.self, from: q)
        }
    }
    
    func parseQuery<ActionType: ServerAction>(from request: Request, action: inout ActionType) throws where ActionType.QueryType == None {
    }
    
    func add<ActionType: ServerAction>(action: ActionType.Type,
                                       _ fun: @escaping (ActionType) async throws -> () )
    where ActionType.ResponseType == None, ActionType.RequestBodyType == None {
        self.on(ActionType.method.httpMethod, ActionType.pathComponents) { (request) async throws in
            var action: ActionType = ActionType()
            try parseQuery(from: request, action: &action)
            try await fun(action)
            return HTTPStatus.ok
        }
    }
    
    func add<ActionType: ServerAction>(action: ActionType.Type,
                                       _ fun: @escaping (ActionType) async throws -> ActionType.ResponseType )
    where ActionType.ResponseType: AsyncResponseEncodable, ActionType.RequestBodyType == None {
        self.on(ActionType.method.httpMethod, ActionType.pathComponents) { (request) async throws -> ActionType.ResponseType in
            var action: ActionType = ActionType()
            try parseQuery(from: request, action: &action)
            return try await fun(action)
        }
    }
    
    func add<ActionType: ServerAction>(action: ActionType.Type,
                                       _ fun: @escaping (ActionType.RequestBodyType) async throws -> () )
    where ActionType.ResponseType == None, ActionType.RequestBodyType: Decodable {
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
    
    func add<ActionType: ServerAction>(action: ActionType.Type,
                                       _ fun: @escaping (ActionType.RequestBodyType) async throws -> ActionType.ResponseType )
    where ActionType.ResponseType: AsyncResponseEncodable, ActionType.RequestBodyType: Decodable {
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
