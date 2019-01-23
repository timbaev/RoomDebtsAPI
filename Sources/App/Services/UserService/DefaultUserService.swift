//
//  DefaultUserService.swift
//  App
//
//  Created by Timur Shafigullin on 20/01/2019.
//

import Vapor
import FluentPostgreSQL

class DefaultUserService: UserService {
    
    // MARK: - Instance Methods
    
    func create(user: User, request: Request) throws -> Future<Response> {
        // TODO: - Send verification code
        
        let existingUser = User.query(on: request).filter(\.phoneNumber == user.phoneNumber).first()
        
        return existingUser.flatMap { existingUser in
            guard existingUser == nil else {
                throw Abort(.badRequest, reason: "User with phone number \(user.phoneNumber) already exists")
            }
            
            return user.save(on: request).flatMap { user in
                do {
                    let token = try TokenHelpers.createJWT(from: user)
                    
                    let httpBody = HTTPBody(data: try JSONEncoder().encode(user))
                    let http = HTTPResponse(headers: [HeaderKeys.authorization: token], body: httpBody)
                    
                    return request.future(Response(http: http, using: request))
                } catch {
                    print(error.localizedDescription)
                    throw Abort(.badRequest, reason: "Can't create token")
                }
            }
        }
    }
    
    func fetch(request: Request) throws -> Future<[User]> {
        return User.query(on: request).all()
    }
}
