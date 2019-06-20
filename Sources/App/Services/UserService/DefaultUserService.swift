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

    func fetchInviteList(on request: Request) throws -> Future<[User.PublicForm]> {
        return try request.authorizedUser().flatMap { user in
            return try user
                .asCreatorConversations
                .query(on: request)
                .filter(\.status == .accepted)
                .all()
                .and(user.asOpponentConversations.query(on: request).filter(\.status == .accepted).all())
                .flatMap { creatorConversations, opponentConversations in
                    var opponents: [Future<User>] = []

                    creatorConversations.forEach { conversation in
                        opponents.append(conversation.opponent.get(on: request))
                    }

                    opponentConversations.forEach { conversation in
                        opponents.append(conversation.creator.get(on: request))
                    }

                    return opponents.map { opponent in
                        return opponent.toPublicForm()
                    }.flatten(on: request)
            }
        }
    }
}
