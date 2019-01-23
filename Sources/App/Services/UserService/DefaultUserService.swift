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
            if let existingUser = existingUser {
                if !(existingUser.isConfirmed ?? false) {
                    existingUser.firstName = user.firstName
                    existingUser.lastName = user.lastName
                    
                    return existingUser.update(on: request).flatMap { user in
                        let token = try TokenHelpers.createJWT(from: user)
                        
                        let httpBody = HTTPBody(data: try JSONEncoder().encode(user))
                        let http = HTTPResponse(headers: [HeaderKeys.authorization: token], body: httpBody)
                        
                        return request.future(Response(http: http, using: request))
                    }
                } else {
                    throw Abort(.badRequest, reason: "User with phone number \(user.phoneNumber) already exists")
                }
            } else {
                return user.save(on: request).flatMap { user in
                    let token = try TokenHelpers.createJWT(from: user)
                    
                    let httpBody = HTTPBody(data: try JSONEncoder().encode(user))
                    let http = HTTPResponse(headers: [HeaderKeys.authorization: token], body: httpBody)
                    
                    return request.future(Response(http: http, using: request))
                }
            }
        }
    }
    
    func fetch(request: Request) throws -> Future<[User]> {
        return User.query(on: request).all()
    }
    
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<User> {
        let userID = try TokenHelpers.getUserID(fromPayloadOf: request.token)
        
        return User.find(userID, on: request).unwrap(or: Abort(.badRequest, reason: "User not found")).flatMap { user in
            user.isConfirmed = true
            
            return user.update(on: request)
        }
    }
}
