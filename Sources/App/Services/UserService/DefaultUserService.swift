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
        
        let accessDto = AccessDto(accessToken: accessToken, refreshToken: refreshToken, expiredAt: try TokenHelpers.expiredDate(of: accessToken))
        
        return refreshTokenModel.save(on: request).transform(to: accessDto)
    }
    
    // MARK: -
    
    func create(userForm: User.Form, request: Request) throws -> Future<AccessDto> {
        // TODO: - Send verification code
        
        let existingUser = User.query(on: request).filter(\.phoneNumber == userForm.phoneNumber).first()
        
        return existingUser.flatMap { existingUser in
            if let existingUser = existingUser {
                if !existingUser.isConfirmed {
                    existingUser.firstName = userForm.firstName
                    existingUser.lastName = userForm.lastName
                    
                    return existingUser.update(on: request).flatMap { user in
                        return try self.createTokens(for: user, on: request)
                    }
                } else {
                    throw Abort(.badRequest, reason: "User with phone number \(userForm.phoneNumber) already exists")
                }
            } else {
                let user = User(firstName: userForm.firstName, lastName: userForm.lastName, phoneNumber: userForm.phoneNumber)
                
                return user.save(on: request).flatMap { user in
                    return try self.createTokens(for: user, on: request)
                }
            }
        }
    }
    
    func fetch(request: Request) throws -> Future<[User]> {
        return User.query(on: request).all()
    }
    
    func confirm(_ request: Request, confirmPhoneDto: ConfirmPhoneDto) throws -> Future<User> {
        let userID = try TokenHelpers.getUserID(fromPayloadOf: request.token)
        
        return User.find(userID, on: request).unwrap(or: Abort(.badRequest, reason: "User not found")).flatMap { user in
            user.isConfirmed = true
            
            return user.update(on: request)
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
                    
                    let accessDto = AccessDto(accessToken: accessToken, refreshToken: refreshToken, expiredAt: expiredAt)
                    
                    return refreshTokenModel.save(on: request).transform(to: accessDto)
                }
            } else {
                throw Abort(.unauthorized)
            }
        }
    }
}
