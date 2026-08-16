import Foundation
import SwiftData

@Model
final class ExpenseAuditLog {
    var timestamp: Date
    var oldAmount: Double
    var oldNote: String
    var oldPaymentMode: String
    
    // We store the ID/name of the category to easily display it
    var oldCategoryName: String
    
    @Relationship(inverse: \Expense.auditLogs)
    var expense: Expense?
    
    init(
        oldAmount: Double,
        oldNote: String,
        oldPaymentMode: String,
        oldCategoryName: String
    ) {
        self.timestamp = Date()
        self.oldAmount = oldAmount
        self.oldNote = oldNote
        self.oldPaymentMode = oldPaymentMode
        self.oldCategoryName = oldCategoryName
    }
}
