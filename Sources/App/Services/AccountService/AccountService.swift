//
//  UserService.swift
//  App
//
//  Created by Timur Shafigullin on 20/01/2019.
//

import Vapor

protocol AccountService {
    
    // MARK: - Instance Methods
    
    func create(userForm: User.Form, request: Request) throws -> Future<ResponseDto>
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<AccessDto>
    func refreshToken(_ request: Request, accessDto: AccessDto) throws -> Future<AccessDto>
    func signIn(phoneNumberDto: PhoneNumberDto, request: Request) throws -> Future<ResponseDto>
    func uploadAvatarImage(request: Request, file: File) throws -> Future<User.Form>
    func updateAccount(on request: Request, form: User.Form) throws -> Future<Response>
}
