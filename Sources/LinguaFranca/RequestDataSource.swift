//
//  File.swift
//  
//
//  Created by Stuart A. Malone on 4/1/23.
//

import Foundation

public protocol RequestDataSource {
    func getQueryData<ResultType: Decodable>(key: String) -> ResultType?
    func getParameter(name: String) -> String?
    func getBody() throws -> Data?
}
