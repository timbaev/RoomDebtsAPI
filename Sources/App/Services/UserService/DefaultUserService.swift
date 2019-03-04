//
//  DefaultUserService.swift
//  App
//
//  Created by Timur Shafigullin on 11/02/2019.
//

import Vapor
import FluentSQL
import FluentPostgreSQL

class DefaultUserService: UserService {
    
    // MARK: - Instance Methods
    
    func search(request: Request, keyword: String) throws -> Future<[User.PublicForm]> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()

            return User.query(on: request).group(.or, closure: { builder in
                builder.filter(\.firstName, .ilike, keyword)
                    .filter(\.lastName, .ilike, keyword)
                    .filter(\.phoneNumber, .ilike, keyword)
            }).filter(\.id != userID).all().map(to: [User.PublicForm].self, { users in
                return users.map { User.PublicForm(user: $0) }
            })
        }
    }
}
