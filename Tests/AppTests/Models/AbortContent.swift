//
//  AbortContent.swift
//  App
//
//  Created by Timur Shafigullin on 26/03/2019.
//

import Vapor

struct AbortContent: Content {

    // MARK: - Instance Properties

    let error: Bool
    let reason: String
}
