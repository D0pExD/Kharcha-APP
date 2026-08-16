import Foundation
import SwiftData

@Model
final class Budget {
    var month: String       // "2026-08"
    var totalBudget: Double
    
    init(month: String, totalBudget: Double) {
        self.month = month
        self.totalBudget = totalBudget
    }
    
    static func currentMonthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}
