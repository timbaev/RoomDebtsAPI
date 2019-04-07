//
//  DateFormatterExtension.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Foundation

extension DateFormatter {

    // MARK: - Type Properties

    static let receiptDateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss"

        return formatter
    }()
}
