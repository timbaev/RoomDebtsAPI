//
//  Application+Testable.swift
//  App
//
//  Created by Timur Shafigullin on 22/03/2019.
//

@testable import App
import Vapor
import FluentPostgreSQL

extension Application {

    // MARK: - Type Methods

    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing

        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }

        try App.configure(&config, &env, &services)

        let app = try Application(config: config, environment: env, services: services)

        try App.boot(app)

        return app
    }

    static func reset() throws {
        let revertEnvironment = ["vapor", "revert", "--all", "-y"]

        try Application.testable(envArgs: revertEnvironment).asyncRun().wait()

        let migrateEnvironment = ["vapor", "migrate", "-y"]

        try Application.testable(envArgs: migrateEnvironment).asyncRun().wait()
    }

    // MARK: - Instance Methods

    func sendRequest<Body>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: Body? = nil, authenticatedUser: User? = nil) throws -> Response where Body: Content {
        var headers = headers

        if let authenticatedUser = authenticatedUser {
            let accessToken = try TokenHelpers.createAccessToken(from: authenticatedUser)

            headers.add(name: .authorization, value: accessToken)
        }

        guard let url = URL(string: path) else {
            throw Abort(.badRequest)
        }

        let httpRequest = HTTPRequest(method: method, url: url, headers: headers)
        let wrappedRequest = Request(http: httpRequest, using: self)

        if let body = body {
            try wrappedRequest.content.encode(body)
        }

        let responder = try self.make(Responder.self)

        return try responder.respond(to: wrappedRequest).wait()
    }

    func sendRequest(to path: String, file: File, method: HTTPMethod = .POST, headers: HTTPHeaders = .init(), authenticatedUser: User? = nil) throws -> Response {
        var headers = headers

        if let authenticatedUser = authenticatedUser {
            let accessToken = try TokenHelpers.createAccessToken(from: authenticatedUser)

            headers.add(name: .authorization, value: accessToken)
        }

        guard let url = URL(string: path) else {
            throw Abort(.badRequest)
        }

        let httpRequest = HTTPRequest(method: method, url: url, headers: headers)
        let wrappedRequest = Request(http: httpRequest, using: self)

        try wrappedRequest.content.encode(json: file)

        let responder = try self.make(Responder.self)

        return try responder.respond(to: wrappedRequest).wait()
    }

    func getResponse<C, T>(to path: String, method: HTTPMethod = .GET,
                           headers: HTTPHeaders = .init(), data: C? = nil,
                           deocodeTo type: T.Type, authenticatedUser: User? = nil) throws -> T where C: Content, T: Decodable {
        let response = try self.sendRequest(to: path, method: method, headers: headers, body: data, authenticatedUser: authenticatedUser)

        return try response.content.decode(type).wait()
    }
}
