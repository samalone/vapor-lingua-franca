import XCTest
@testable import LinguaFranca

struct User: Codable {
    var id: UUID
    var name: String
}

struct AddUser: PostAction, Codable {
    typealias ResponseType = User
    static let path: Path = ["user"]
    
    var name: String
    
    var requestBody: AddUser { self }
}

struct GetUser: GetAction {
    typealias ResponseType = User
    static let path: Path = ["user", .param(\.id)]
    
    var id: UUID
}

struct SetUserName: PatchAction {
    typealias ResponseType = None
    static let path: Path = ["user", .param(\.id), "name"]
    
    var id: UUID
    var name: String
    
    var requestBody: String { name }
}

struct DeleteUser: DeleteAction {
    static let path: Path = ["user", .param(\.id)]
    
    var id: UUID
}

struct ReplaceUser: PutAction {
    static let path: Path = ["user", .param(\.user.id)]
    
    var user: User
    
    var requestBody: User { user }
}

final class LinguaFrancaTests: XCTestCase {
    let baseURL = URL(string: "http://ravana.local/")!
    let userID = UUID(uuidString: "BC8EBCAE-282A-41CE-8BAE-43A624A55E91")!
    let jsonContentType = "application/json; charset=utf-8"
    
    // Create an encoder with sorted keys so the JSON is predictable.
    let encoder = {
        var enc = JSONEncoder()
        enc.outputFormatting = JSONEncoder.OutputFormatting.sortedKeys
        return enc
    }()
    
    func testAddUser() async throws {
        let action = AddUser(name: "Stuart")
        let request = try action.buildRequest(to: baseURL)
        
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "http://ravana.local/user")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), jsonContentType)
        XCTAssertEqual(request.httpBody, "{\"name\":\"Stuart\"}".data(using: .utf8))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), jsonContentType)
    }
    
    func testGetUser() async throws {
        let action = GetUser(id: userID)
        let request = try action.buildRequest(to: baseURL)
        
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString, "http://ravana.local/user/BC8EBCAE-282A-41CE-8BAE-43A624A55E91")
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertNil(request.httpBody)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), jsonContentType)
    }
    
    func testSetUserName() async throws {
        let action = SetUserName(id: userID, name: "Bob")
        let request = try action.buildRequest(to: baseURL)
        
        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.url?.absoluteString, "http://ravana.local/user/BC8EBCAE-282A-41CE-8BAE-43A624A55E91/name")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), jsonContentType)
        XCTAssertEqual(request.httpBody, "\"Bob\"".data(using: .utf8))
        XCTAssertNil(request.value(forHTTPHeaderField: "Accept"))
    }
    
    func testDeleteUser() async throws {
        let action = DeleteUser(id: userID)
        let request = try action.buildRequest(to: baseURL)
        
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.url?.absoluteString, "http://ravana.local/user/BC8EBCAE-282A-41CE-8BAE-43A624A55E91")
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.value(forHTTPHeaderField: "Accept"))
    }
    
    func testReplaceUser() async throws {
        let action = ReplaceUser(user: User(id: userID, name: "Janet"))
        let request = try action.buildRequest(to: baseURL, encoder: encoder)
        
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertEqual(request.url?.absoluteString, "http://ravana.local/user/BC8EBCAE-282A-41CE-8BAE-43A624A55E91")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), jsonContentType)
        XCTAssertEqual(request.httpBody, "{\"id\":\"BC8EBCAE-282A-41CE-8BAE-43A624A55E91\",\"name\":\"Janet\"}".data(using: .utf8))
        XCTAssertNil(request.value(forHTTPHeaderField: "Accept"))
        
    }
}
