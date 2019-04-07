//
//  RawReceipt.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Foundation

struct RawReceipt: Codable {

    // MARK: - Nested Types

    struct Document: Codable {

        // MARK: - Instance Properties

        let receipt: Receipt
    }

    // MARK: - Instance Properties

    let document: Document
}
