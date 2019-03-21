//
//  UserController.swift
//  App
//
//  Created by Timur Shafigullin on 19/01/2019.
//

import Vapor

final class AccountController {
    
    // MARK: - Instance Properties
    
    var accountService: AccountService
    
    // MARK: - Initializers
    
    init(accountService: AccountService) {
        self.accountService = accountService
    }
    
    // MARK: - Instance Methods
    
    func create(_ request: Request, userForm: User.Form) throws -> Future<ResponseDto> {
        return try self.accountService.create(userForm: userForm, request: request)
    }
    
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<AccessDto> {
        return try self.accountService.confirm(request, confirmPhoneDto: confirmPhoneDto)
    }
    
    func refreshToken(_ request: Request, accessDto: AccessDto) throws -> Future<AccessDto> {
        return try self.accountService.refreshToken(request, accessDto: accessDto)
    }
    
    func signIn(_ request: Request, phoneNumberDto: PhoneNumberDto) throws -> Future<ResponseDto> {
        return try self.accountService.signIn(phoneNumberDto: phoneNumberDto, request: request)
    }
    
    func uploadImage(_ request: Request) throws -> Future<User.Form> {
        return try request.content.decode(File.self).flatMap { file in
            return try self.accountService.uploadAvatarImage(request: request, file: file)
        }
    }

    func update(_ request: Request, userForm: User.Form) throws -> Future<Response> {
        return try self.accountService.updateAccount(on: request, form: userForm)
    }

    func logout(_ request: Request) throws -> Future<HTTPStatus> {
        return try self.accountService.logout(on: request).transform(to: .noContent)
    }
}

// MARK: - RouteCollection

extension AccountController: RouteCollection {
    
    // MARK: - Instance Methods
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/account").grouped(Logger())
        let authGroup = group.grouped(JWTMiddleware())
        
        group.post(User.Form.self, use: self.create)
        group.post(AccessDto.self, at: "token", use: self.refreshToken)
        group.post(ConfirmPhoneDto.self, at: "confirm", use: self.confirm)
        group.post(PhoneNumberDto.self, at: "login", use: self.signIn)
        
        authGroup.post("avatar", use: self.uploadImage)
        authGroup.post("logout", use: self.logout)

        authGroup.put(User.Form.self, use: self.update)
    }
}
