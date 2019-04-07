//
//  StringExtension.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Foundation

extension String {

    // MARK: - Instance Properties

    var condenseWhitespace: String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }

    // MARK: - Instance Methods

    func matcheAndDelete(for regex: String) -> (matche: String?, updated: String) {
        guard let regex = try? NSRegularExpression(pattern: regex) else {
            return (matche: nil, updated: self)
        }

        let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))

        if let result = results.first {
            guard let range = Range(result.range, in: self) else {
                return (matche: nil, updated: self)
            }

            let matche = String(self[range])
            let updated = self.replacingOccurrences(of: matche, with: "")

            return (matche: matche, updated: updated)
        } else {
            return (matche: nil, updated: self)
        }
    }
}
