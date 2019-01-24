//
//  ConfirmPhoneDto.swift
//  App
//
//  Created by Timur Shafigullin on 22/01/2019.
//

import Vapor

struct ConfirmPhoneDto: Content {
    
    // MARK: - Instance Properties
    
    let phoneNumber: String
    let code: String
}
