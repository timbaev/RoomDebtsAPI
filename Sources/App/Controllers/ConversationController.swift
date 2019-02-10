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
}

// MARK: - RouteCollection

extension ConversationController: RouteCollection {
    
    // MARK: - Instance Methods
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/conversations").grouped(Logger()).grouped(JWTMiddleware())
        
        group.post(Conversation.CreateForm.self, use: self.create)
    }
}
