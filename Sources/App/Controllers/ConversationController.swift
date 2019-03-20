//
//  ConversationController.swift
//  App
//
//  Created by Timur Shafigullin on 03/02/2019.
//

import Vapor

final class ConversationController {
    
    // MARK: - Instance Properties
    
    var conversationService: ConversationService
    
    // MARK: - Initializers
    
    init(conversationService: ConversationService) {
        self.conversationService = conversationService
    }
    
    // MARK: - Instance Methods
    
    func create(_ request: Request, createForm: Conversation.CreateForm) throws -> Future<Conversation.Form> {
        return try self.conversationService.create(request: request, createForm: createForm)
    }

    func fetch(_ request: Request) throws -> Future<[Conversation.Form]> {
        return try self.conversationService.fetch(request: request)
    }

    func accept(_ request: Request) throws -> Future<Conversation.Form> {
        return try request.parameters.next(Conversation.self).flatMap { conversation in
            return try self.conversationService.accept(request: request, conversation: conversation)
        }
    }

    func reject(_ request: Request) throws -> Future<Response> {
        return try request.parameters.next(Conversation.self).flatMap { conversation in
            return try self.conversationService.reject(request: request, conversation: conversation)
        }
    }

    func repayAllRequest(_ request: Request) throws -> Future<Conversation.Form> {
        return try request.parameters.next(Conversation.self).flatMap { conversation in
            return try self.conversationService.repayAllRequest(on: request, conversation: conversation)
        }
    }

    func deleteRequest(_ request: Request) throws -> Future<Conversation.Form> {
        return try request.parameters.next(Conversation.self).flatMap { conversation in
            return try self.conversationService.deleteRequest(on: request, conversation: conversation)
        }
    }
}

// MARK: - RouteCollection

extension ConversationController: RouteCollection {
    
    // MARK: - Instance Methods
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/conversations").grouped(Logger()).grouped(JWTMiddleware())
        
        group.post(Conversation.CreateForm.self, use: self.create)
        group.get(use: self.fetch)

        group.post(Conversation.parameter, "accept", use: self.accept)
        group.post(Conversation.parameter, "reject", use: self.reject)

        group.post(Conversation.parameter, "request", "repay", use: self.repayAllRequest)
        group.post(Conversation.parameter, "request", "delete", use: self.deleteRequest)
    }
}
