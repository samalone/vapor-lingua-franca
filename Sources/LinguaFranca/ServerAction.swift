//
//  File.swift
//  
//
//  Created by Stuart A. Malone on 3/23/23.
//

import Foundation
import URLQueryCoder

fileprivate let jsonContentType = "application/json; charset=utf-8"

public enum PathPart<ActionType>: ExpressibleByStringInterpolation {
    case constant(String)
    
    case param(PartialKeyPath<ActionType>)
    
    public init(stringLiteral value: String) {
        self = .constant(value)
    }
}

/// None is a special ServerAction.ResponseType that indicates the
/// server does not provide any data in the body of the response.
public struct None: Codable {
    public init() {}
}

public protocol ServerAction {
    typealias Path = [PathPart<Self>]
    
    static var method: RequestMethod { get }
    static var path: Path { get }
    
    associatedtype RequestBodyType: Codable
    associatedtype ResponseType: Codable
    associatedtype QueryType: Codable
    
    var requestBody: RequestBodyType { get set }
    var query: QueryType { get set }
    
    #if os(macOS) || os(iOS)
    func buildRequest(to baseURL: URL, encoder: JSONEncoder) throws -> URLRequest
    
    /// Set the Accept header of the request according to the ResponseType of the action.
    func setAcceptHeader(_ request: inout URLRequest)
    #endif
    
    init()
}

// If the user doesn't specify a ResponseType, assume None.
//public extension ServerAction {
//    typealias ResponseType = None
//}

// If the ResponseType is None, assume the method is POST
public extension ServerAction where ResponseType == None {
    static var method: RequestMethod { .POST }
    
    #if os(macOS) || os(iOS)
    func setAcceptHeader(_ request: inout URLRequest) {
        // do nothing
    }
    #endif
}


// If the ResponseType isn't None, assume the method is GET
public extension ServerAction {
    static var method: RequestMethod { .GET }
    
    func at(baseURL: URL) throws -> URL {
        var result = baseURL
        for component in Self.path {
            switch component {
            case .constant(let string):
                result.append(component: string)
            case .param(let partialKeyPath):
                let value = self[keyPath: partialKeyPath]
                result.append(component: String(describing: value))
            }
        }
        
        var comp = URLComponents()
        comp.query = try URLQueryEncoder().encode(query)
        if let qi = comp.queryItems {
            result.append(queryItems: qi)
        }
        
        return result
    }
    
    #if os(macOS) || os(iOS)
    func buildRequest(to baseURL: URL, encoder: JSONEncoder) throws -> URLRequest {
        var req = try URLRequest(url: self.at(baseURL: baseURL))
        req.httpMethod = Self.method.rawValue
        req.setValue(jsonContentType, forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(requestBody)
        setAcceptHeader(&req)
        return req
    }
    
    func buildRequest(to baseURL: URL) throws -> URLRequest {
        return try buildRequest(to: baseURL, encoder: JSONEncoder())
    }
    
    func setAcceptHeader(_ request: inout URLRequest) {
        request.setValue(jsonContentType, forHTTPHeaderField: "Accept")
    }
    #endif
}

public extension ServerAction where RequestBodyType == None {
    var requestBody: RequestBodyType {
        None()
    }
    
    #if os(macOS) || os(iOS)
    func buildRequest(to baseURL: URL, encoder: JSONEncoder) throws -> URLRequest {
        var req = try URLRequest(url: self.at(baseURL: baseURL))
        req.httpMethod = Self.method.rawValue
        setAcceptHeader(&req)
        return req
    }
    #endif
}

public protocol GetAction: ServerAction where RequestBodyType == None {
}

extension GetAction {
    static var method: RequestMethod { .GET }
    public var requestBody: None { None() }
}

public protocol PostAction: ServerAction {}

extension PostAction {
    static var method: RequestMethod { .POST }
}

public protocol PatchAction: ServerAction where ResponseType == None {}

extension PatchAction {
    static public var method: RequestMethod { .PATCH }
}

public protocol DeleteAction: ServerAction where ResponseType == None, RequestBodyType == None {}

extension DeleteAction {
    static public var method: RequestMethod { .DELETE }
    public var requestBody: None { None() }
}

public protocol PutAction: ServerAction where ResponseType == None {}

extension PutAction {
    static public var method: RequestMethod { .PUT }
}
