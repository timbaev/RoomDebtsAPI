//
//  Services.swift
//  App
//
//  Created by Timur Shafigullin on 20/01/2019.
//

import Foundation

enum RDServices {
    
    // MARK: - Instance Properties
    
    static let accountService: AccountService = DefaultAccountService(fileService: RDServices.fileService)
    static let fileService: FileService = DefaultFileService()
    static let conversationService: ConversationService = DefaultConversationService()
    static let userService: UserService = DefaultUserService()
    static let debtService: DebtService = DefaultDebtService(conversationService: RDServices.conversationService)

    static let checkService: CheckService = DefaultCheckService(receiptManager: RDServices.receiptManager,
                                                                productService: RDServices.productService,
                                                                fileService: RDServices.fileService,
                                                                debtService: RDServices.debtService,
                                                                conversationService: RDServices.conversationService)

    static let productService: ProductService = DefaultProductService()

    // MARK: -

    static let receiptManager: ReceiptManager = DefaultReceiptManager()
}
