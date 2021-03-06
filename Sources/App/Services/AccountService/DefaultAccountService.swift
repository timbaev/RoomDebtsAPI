//
//  DefaultAccountService.swift
//  App
//
//  Created by Timur Shafigullin on 20/01/2019.
//

import Vapor
import FluentPostgreSQL
import Crypto

class DefaultAccountService: AccountService {
    
    // MARK: - Instance Properties
    
    var fileService: FileService
    
    // MARK: - Initializers
    
    init(fileService: FileService) {
        self.fileService = fileService
    }
    
    // MARK: - Instance Methods
    
    fileprivate func createTokens(for user: User, on request: Request) throws -> Future<AccessDto> {
        let accessToken = try TokenHelpers.createAccessToken(from: user)
        let refreshToken = TokenHelpers.createRefreshToken()
        
        let refreshTokenModel = RefreshToken(token: refreshToken, userID: try user.requireID())
        
        let userForm = User.Form(user: user)
        let accessDto = AccessDto(accessToken: accessToken, refreshToken: refreshToken, expiredAt: try TokenHelpers.expiredDate(of: accessToken), userData: userForm)
        
        return refreshTokenModel.save(on: request).transform(to: accessDto)
    }
    
    // MARK: -
    
    func create(userForm: User.Form, request: Request) throws -> Future<ResponseDto> {
        let existingUser = User.query(on: request).filter(\.phoneNumber == userForm.phoneNumber).first()
        
        return existingUser.flatMap { existingUser in
            if let existingUser = existingUser {
                if !existingUser.isConfirmed {
                    existingUser.firstName = userForm.firstName
                    existingUser.lastName = userForm.lastName
                    
                    let userID = try existingUser.requireID()
                    
                    return VerificationCode
                        .query(on: request)
                        .filter(\.userID == userID)
                        .first()
                        .unwrap(or: Abort(.badRequest, reason: "account.service.verification.code.not.found".localized(on: request)))
                        .flatMap { verificationCode in
                            verificationCode.update()

                            return verificationCode.update(on: request).then { savedVerificatioCode in
                                return existingUser
                                    .update(on: request)
                                    .transform(to: ResponseDto(message: "Account updated successfully"))
                        }
                    }
                } else {
                    throw Abort(.badRequest, reason: "account.service.user.exists".localized(on: request, interpolations: ["phoneNumber": userForm.phoneNumber]))
                }
            } else {
                let user = User(firstName: userForm.firstName, lastName: userForm.lastName, phoneNumber: userForm.phoneNumber)
                
                return user.save(on: request).flatMap { savedUser in
                    let verificationCode = try VerificationCode(userID: savedUser.requireID())
                    
                    return verificationCode
                        .save(on: request)
                        .transform(to: ResponseDto(message: "account.service.created".localized(on: request)))
                }
            }
        }
    }
    
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<AccessDto> {
        return User
            .query(on: request)
            .filter(\.phoneNumber == confirmPhoneDto.phoneNumber)
            .first()
            .unwrap(or: Abort(.badRequest, reason: "account.service.phone.not.found".localized(on: request, interpolations: ["phoneNumber": confirmPhoneDto.phoneNumber])))
            .flatMap { user in
                let userID = try user.requireID()
                
                return VerificationCode
                    .query(on: request)
                    .filter(\.userID == userID)
                    .first()
                    .unwrap(or: Abort(.badRequest, reason: "account.service.code.not.found".localized(on: request)))
                    .flatMap { verificationCode in
                        guard verificationCode.expiredAt > Date() else {
                            throw Abort(.badRequest, reason: "account.service.code.expired".localized(on: request))
                        }
                    
                        guard verificationCode.code == confirmPhoneDto.code else {
                            throw Abort(.badRequest, reason: "account.service.code.invalid".localized(on: request))
                        }
                    
                        user.isConfirmed = true
                    
                        return verificationCode.delete(on: request).then {
                            return user.update(on: request).flatMap { savedUser in
                                return RefreshToken.query(on: request).filter(\.userID == userID).delete().flatMap {
                                    return try self.createTokens(for: savedUser, on: request)
                        }
                    }
                }
            }
        }
    }
    
    func refreshToken(_ request: Request, accessDto: AccessDto) throws -> Future<AccessDto> {
        let refreshTokenModel = RefreshToken
            .query(on: request)
            .filter(\.token == accessDto.refreshToken)
            .first()
            .unwrap(or: Abort(.unauthorized))
        
        return refreshTokenModel.flatMap { refreshTokenModel in
            if refreshTokenModel.expiredAt > Date() {
                
                return refreshTokenModel.user.get(on: request).flatMap { user in
                    let accessToken = try TokenHelpers.createAccessToken(from: user)
                    let refreshToken = TokenHelpers.createRefreshToken()
                    let expiredAt = try TokenHelpers.expiredDate(of: accessToken)
                    
                    refreshTokenModel.token = refreshToken
                    refreshTokenModel.updateExpiredDate()
                    
                    let accessDto = AccessDto(accessToken: accessToken, refreshToken: refreshToken, expiredAt: expiredAt, userData: nil)
                    
                    return refreshTokenModel.save(on: request).transform(to: accessDto)
                }
            } else {
                throw Abort(.unauthorized)
            }
        }
    }
    
    func signIn(phoneNumberDto: PhoneNumberDto, request: Request) throws -> Future<ResponseDto> {
       return User
        .query(on: request)
        .filter(\.phoneNumber == phoneNumberDto.phoneNumber)
        .first()
        .unwrap(or: Abort(.badRequest, reason: "account.service.phone.not.found".localized(on: request, interpolations: ["phoneNumber": phoneNumberDto.phoneNumber])))
        .flatMap { user in
            let userID = try user.requireID()
            
            return VerificationCode.query(on: request).filter(\.userID == userID).first().then { verificationCode in
                if let verificationCode = verificationCode {
                    verificationCode.update()
                    
                    return verificationCode
                        .update(on: request)
                        .transform(to: ResponseDto(message: "account.service.code.sent".localized(on: request)))
                } else {
                    return VerificationCode(userID: userID)
                        .save(on: request)
                        .transform(to: ResponseDto(message: "account.service.code.sent".localized(on: request)))
                }
            }
        }
    }
    
    // MARK: -
    
    func uploadAvatarImage(request: Request, file: File) throws -> Future<User.Form> {
        return try request.authorizedUser().flatMap { user in
            
            if let userImage = user.image {
                return userImage.get(on: request).flatMap { fileRecord in
                    return try self.fileService.remove(request: request, fileRecord: fileRecord).flatMap {
                        return try self.fileService.uploadImage(on: request, file: file).flatMap { fileRecord in
                            user.imageID = try fileRecord.requireID()

                            return user.save(on: request).toForm()
                        }
                    }
                }
            } else {
                return try self.fileService.uploadImage(on: request, file: file).flatMap { fileRecord in
                    user.imageID = try fileRecord.requireID()

                    return user.save(on: request).toForm()
                }
            }
        }
    }

    func updateAccount(on request: Request, form: User.Form) throws -> Future<Response> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()
            let response = Response(using: request)

            user.firstName = form.firstName
            user.lastName = form.lastName

            if user.phoneNumber != form.phoneNumber {
                return User.query(on: request)
                    .filter(\.phoneNumber == form.phoneNumber)
                    .first()
                    .flatMap { existingUser in
                        guard existingUser == nil else {
                            throw Abort(.badRequest, reason: "account.service.user.exists".localized(on: request, interpolations: ["phoneNumber": form.phoneNumber]))
                        }

                        user.phoneNumber = form.phoneNumber
                        user.isConfirmed = false

                        return VerificationCode.query(on: request)
                            .filter(\.userID == userID)
                            .first()
                            .flatMap { verificationCode in
                                if let verificationCode = verificationCode {
                                    verificationCode.update()

                                    return verificationCode.save(on: request).flatMap { _ in
                                        user.save(on: request).toForm().map { userForm in
                                            response.http.status = .accepted
                                            try response.content.encode(userForm)

                                            return response
                                        }
                                    }
                                } else {
                                    return VerificationCode(userID: userID).save(on: request).flatMap { _ in
                                        return user.save(on: request).toForm().map { userForm in
                                            response.http.status = .accepted
                                            try response.content.encode(userForm)

                                            return response
                                        }
                                    }
                                }
                        }
                }
            } else {
                return user.save(on: request).toForm().map { userForm in
                    try response.content.encode(userForm)

                    return response
                }
            }
        }
    }

    func logout(on request: Request) throws -> Future<Void> {
        return try request.authorizedUser().flatMap { user in
            return try user.refreshTokens.query(on: request).delete()
        }
    }
}
