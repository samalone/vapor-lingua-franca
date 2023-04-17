//
//  File.swift
//  
//
//  Created by Stuart A. Malone on 3/23/23.
//

import Foundation

#if os(macOS) || os(iOS)
public extension URLSession {
    
    func send<ActionType: ServerAction>(action: ActionType, to baseURL: URL) async throws -> ActionType.ResponseType {
        let (data, _) = try await self.data(for: action.buildRequest(to: baseURL))
        let response = try JSONDecoder().decode(ActionType.ResponseType.self, from: data)
        return response
    }
    
    func send<ActionType: ServerAction>(action: ActionType, to baseURL: URL) async throws where ActionType.ResponseType == None {
        _ = try await self.data(for: action.buildRequest(to: baseURL))
    }
    
}
#endif
