//
//  AccessDto.swift
//  App
//
//  Created by Timur Shafigullin on 23/01/2019.
//

import Vapor

struct AccessDto: Content {
    
    // MARK: - Instance Properties
    
    let accessToken: String?
    let refreshToken: String
    let expiredAt: Date?
    let userData: User.Form?
}
