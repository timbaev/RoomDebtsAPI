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
    
    func create(_ request: Request, userForm: User.Form) throws -> Future<ResponseDto> {
        return try self.userService.create(userForm: userForm, request: request)
    }
    
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<AccessDto> {
        return try self.userService.confirm(request, confirmPhoneDto: confirmPhoneDto)
    }
    
    func refreshToken(_ request: Request, accessDto: AccessDto) throws -> Future<AccessDto> {
        return try self.userService.refreshToken(request, accessDto: accessDto)
    }
}

// MARK: - RouteCollection

extension UserController: RouteCollection {
    
    // MARK: - Instance Methods
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/account").grouped(Logger())
        let authGroup = group.grouped(JWTMiddleware())
        
        group.post(User.Form.self, use: self.create)
        group.post(AccessDto.self, at: "/token", use: self.refreshToken)
        group.post(ConfirmPhoneDto.self, at: "/confirm", use: self.confirm)
        
        authGroup.get(use: self.index)
    }
}
