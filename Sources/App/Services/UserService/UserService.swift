//
//  UserService.swift
//  App
//
//  Created by Timur Shafigullin on 20/01/2019.
//

import Vapor

protocol UserService {
    
    // MARK: - Instance Methods
    
    func create(user: User, request: Request) throws -> Future<User>
    func fetch(request: Request) throws -> Future<[User]>
    
}
