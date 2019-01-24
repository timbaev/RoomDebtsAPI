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
    
    fileprivate func createTokens(for user: User, on request: Request) throws -> Future<AccessDto> {
        let accessToken = try TokenHelpers.createJWT(from: user)
        let refreshToken = TokenHelpers.createRefreshToken()
        
        let refreshTokenModel = RefreshToken(token: refreshToken, userID: try user.requireID())
        
        let userForm = User.Form(firstName: user.firstName, lastName: user.lastName, phoneNumber: user.phoneNumber)
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
                    
                    return VerificationCode.query(on: request).filter(\.userID == userID).first().unwrap(or: Abort(.badRequest, reason: "Verification Code not found")).flatMap { verificationCode in
                        verificationCode.update()
                        
                        return verificationCode.update(on: request).then { savedVerificatioCode in
                            return existingUser.update(on: request).transform(to: ResponseDto(message: "Account updated successfully"))
                        }
                    }
                } else {
                    throw Abort(.badRequest, reason: "User with phone number \(userForm.phoneNumber) already exists")
                }
            } else {
                let user = User(firstName: userForm.firstName, lastName: userForm.lastName, phoneNumber: userForm.phoneNumber)
                
                return user.save(on: request).flatMap { savedUser in
                    let verificationCode = try VerificationCode(userID: savedUser.requireID())
                    
                    return verificationCode.save(on: request).transform(to: ResponseDto(message: "Account created successfully"))
                }
            }
        }
    }
    
    func fetch(request: Request) throws -> Future<[User]> {
        return User.query(on: request).all()
    }
    
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<AccessDto> {
        return User.query(on: request).filter(\.phoneNumber == confirmPhoneDto.phoneNumber).first().unwrap(or: Abort(.badRequest, reason: "User with phone number \(confirmPhoneDto.phoneNumber) not found")).flatMap { user in
            let userID = try user.requireID()
            
            return VerificationCode.query(on: request).filter(\.userID == userID).first().unwrap(or: Abort(.badRequest, reason: "Verification Code not found")).flatMap { verificationCode in
                guard verificationCode.expiredAt > Date() else {
                    throw Abort(.badRequest, reason: "Verification code expired")
                }
                
                guard verificationCode.code == confirmPhoneDto.code else {
                    throw Abort(.badRequest, reason: "Invalid confirmation code")
                }
                
                user.isConfirmed = true
                
                return verificationCode.delete(on: request).then {
                    return user.update(on: request).flatMap { savedUser in
                        return try self.createTokens(for: savedUser, on: request)
                    }
                }
            }
        }
    }
    
    func refreshToken(_ request: Request, accessDto: AccessDto) throws -> Future<AccessDto> {
        let refreshTokenModel = RefreshToken.query(on: request).filter(\.token == accessDto.refreshToken).first().unwrap(or: Abort(.unauthorized))
        
        return refreshTokenModel.flatMap { refreshTokenModel in
            if refreshTokenModel.token == accessDto.refreshToken, refreshTokenModel.expiredAt > Date() {
                
                return refreshTokenModel.user.get(on: request).flatMap { user in
                    let accessToken = try TokenHelpers.createJWT(from: user)
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
}
