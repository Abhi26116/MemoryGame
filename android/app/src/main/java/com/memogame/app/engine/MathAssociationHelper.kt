package com.memogame.app.engine

object MathAssociationHelper {
    /** Simple addition expressions like "5+1". */
    fun isExpression(text: String): Boolean =
        text.contains('+') && text.all { it.isDigit() || it == '+' }

    fun isNumericAnswer(text: String): Boolean =
        text.isNotEmpty() && text.all { it.isDigit() }

    fun evaluate(expression: String): Int? {
        val parts = expression.split('+')
        if (parts.size != 2) return null
        val left = parts[0].trim().toIntOrNull() ?: return null
        val right = parts[1].trim().toIntOrNull() ?: return null
        return left + right
    }

    /** True when one card is an expression and the other is its correct sum. */
    fun expressionMatchesAnswer(lhs: String, rhs: String): Boolean {
        if (isExpression(lhs) && isNumericAnswer(rhs) && evaluate(lhs) == rhs.toIntOrNull()) return true
        if (isExpression(rhs) && isNumericAnswer(lhs) && evaluate(rhs) == lhs.toIntOrNull()) return true
        return false
    }
}
