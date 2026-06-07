//
//  MathAssociationHelper.swift
//  Memory Match Kids
//

import Foundation

enum MathAssociationHelper {
    /// Simple addition expressions like "5+1".
    static func isExpression(_ text: String) -> Bool {
        text.contains("+") && text.allSatisfy { $0.isNumber || $0 == "+" }
    }

    static func isNumericAnswer(_ text: String) -> Bool {
        !text.isEmpty && text.allSatisfy(\.isNumber)
    }

    static func evaluate(_ expression: String) -> Int? {
        let parts = expression.split(separator: "+", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let left = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let right = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        return left + right
    }

    /// True when one card is an expression and the other is its correct sum.
    static func expressionMatchesAnswer(_ lhs: String, _ rhs: String) -> Bool {
        if isExpression(lhs), isNumericAnswer(rhs), evaluate(lhs) == Int(rhs) { return true }
        if isExpression(rhs), isNumericAnswer(lhs), evaluate(rhs) == Int(lhs) { return true }
        return false
    }
}
