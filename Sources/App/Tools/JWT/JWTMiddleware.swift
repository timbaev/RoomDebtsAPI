//
//  JWTMiddleware.swift
//  App
//
//  Created by Timur Shafigullin on 22/01/2019.
//

import Vapor

class JWTMiddleware: Middleware {
    
    // MARK: - Instance Methods
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        if let token = request.http.headers.firstValue(name: HTTPHeaderName.authorization) {
            do {
                try TokenHelpers.tokenIsVerified(token)
                return try next.respond(to: request)
            } catch let error as JWTError {
                throw Abort(.unauthorized, reason: error.description)
            }
        } else {
            throw Abort(.unauthorized, reason: "No auth token")
        }
    }
}
