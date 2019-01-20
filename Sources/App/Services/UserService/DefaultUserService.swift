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
    
    func create(user: User, request: Request) throws -> Future<User> {
        // TODO: - Send verification code
        
        let existingUser = User.query(on: request).filter(\.phoneNumber == user.phoneNumber).first()
        
        return existingUser.flatMap { existingUser in
            guard existingUser == nil else {
                throw Abort(.badRequest, reason: "User with phone number \(user.phoneNumber) already exists")
            }
            
            return try request.content.decode(User.self).flatMap { user in
                return user.save(on: request)
            }
        }
    }
    
    func fetch(request: Request) throws -> Future<[User]> {
        return User.query(on: request).all()
    }
    
}
