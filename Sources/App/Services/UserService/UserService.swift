//
//  UserService.swift
//  App
//
//  Created by Timur Shafigullin on 11/02/2019.
//

import Vapor

protocol UserService {
    
    // MARK: - Instance Methods
    
    func search(request: Request, keyword: String) throws -> Future<[User.PublicForm]>
    func fetchInviteList(on request: Request) throws -> Future<[User.PublicForm]>
}
