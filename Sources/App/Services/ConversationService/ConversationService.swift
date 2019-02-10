//
//  ConversationService.swift
//  App
//
//  Created by Timur Shafigullin on 03/02/2019.
//

import Vapor

protocol ConversationService {
 
    // MARK: - Instance Methods
    
    func create(request: Request, createForm: Conversation.CreateForm) throws -> Future<Conversation.Form>
}
