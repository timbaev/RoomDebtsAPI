//
//  StringExtension.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Foundation
import Vapor
import Lingo

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

    func matche(_ regex: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: regex) else {
            return nil
        }

         let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))

        if let result = results.first {
            guard let range = Range(result.range, in: self) else {
                return nil
            }

            return String(self[range])
        } else {
            return nil
        }
    }

    func localized(on request: Request, interpolations: [String: Any]? = nil) -> String {
        guard let lingo = try? request.make(Lingo.self) else {
            fatalError("LingoProvider is not registered.")
        }

        if let localeIdentifier = request.http.headers[.acceptLanguage].first {
            return lingo.localize(self, locale: localeIdentifier, interpolations: interpolations)
        } else {
            return lingo.localize(self, locale: lingo.defaultLocale, interpolations: interpolations)
        }
    }
}
