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
    
    // MARK: - Initializers
    
    init(userService: UserService) {
        self.userService = userService
    }
    
    // MARK: - Instance Methods
    
    func index(_ request: Request) throws -> Future<[User]> {
        return try self.userService.fetch(request: request)
    }
    
    func create(_ request: Request, user: User) throws -> Future<Response> {
        return try self.userService.create(user: user, request: request)
    }
    
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<User> {
        return try self.userService.confirm(request, confirmPhoneDto: confirmPhoneDto)
    }
}

// MARK: - RouteCollection

extension UserController: RouteCollection {
    
    // MARK: - Instance Methods
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/account").grouped(Logger())
        let authGroup = group.grouped(JWTMiddleware())
        
        group.post(User.self, use: self.create)
        authGroup.get(use: self.index)
        authGroup.post(ConfirmPhoneDto.self, use: self.confirm)
    }
}
