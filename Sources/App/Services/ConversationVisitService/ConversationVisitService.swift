//
//  ConversationVisitService.swift
//  App
//
//  Created by Timur Shafigullin on 18/08/2019.
//

import Vapor

protocol ConversationVisitService {

    // MARK: - Instance Methods

    func updateConversationVisit(on request: Request, conversationID: Conversation.ID) throws -> Future<ConversationVisit.Form>
}
