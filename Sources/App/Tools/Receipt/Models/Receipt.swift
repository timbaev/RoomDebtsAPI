//
//  Receipt.swift
//  CheckCheck
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Foundation

struct Receipt: Codable {

    // MARK: - Instance Properties

    let retailPlaceAddress: String
    let user: String?
    let dateTime: Date
    let totalSum: Int
    let items: [Item]
}
