//
//  UserController.swift
//  App
//
//  Created by Timur Shafigullin on 11/02/2019.
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
    
    func search(_ request: Request) throws -> Future<[User.PublicForm]> {
        let keyword = try request.parameters.next(String.self)
        
        return try self.userService.search(request: request, keyword: keyword)
    }

    func inviteList(_ request: Request) throws -> Future<[User.PublicForm]> {
        return try self.userService.fetchInviteList(on: request)
    }
}

// MARK: - RouteCollection

extension UserController: RouteCollection {
    
    // MARK: - Instance Methods
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/users").grouped(ConsoleLogger()).grouped(JWTMiddleware())
        
        group.get("search", String.parameter, use: self.search)
        group.get("invite", use: self.inviteList)
    }
}
