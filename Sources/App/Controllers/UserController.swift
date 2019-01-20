//
//  UserController.swift
//  App
//
//  Created by Timur Shafigullin on 19/01/2019.
//

import Vapor

final class UserController {
    
    // MARK: - Instance Properties
    
    var userService: UserService
    
    // MARK: - Instance Methods
    
    func index(_ request: Request) throws -> Future<[User]> {
        return try self.userService.fetch(request: request)
    }
    
    func create(_ request: Request, user: User) throws -> Future<User> {
        return try self.userService.create(user: user, request: request)
    }
    
    // MARK: - Initializers
    
    init(userService: UserService) {
        self.userService = userService
    }
}
