//
//  UserService.swift
//  App
//
//  Created by Timur Shafigullin on 20/01/2019.
//

import Vapor

protocol UserService {
    
    // MARK: - Instance Methods
    
    func create(userForm: User.Form, request: Request) throws -> Future<ResponseDto>
    func fetch(request: Request) throws -> Future<[User]>
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<AccessDto>
    func refreshToken(_ request: Request, accessDto: AccessDto) throws -> Future<AccessDto>
    func signIn(phoneNumberDto: PhoneNumberDto, request: Request) throws -> Future<ResponseDto>
    
}
