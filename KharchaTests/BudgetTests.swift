import XCTest
@testable import Kharcha

final class BudgetTests: XCTestCase {
    
    func testCurrentMonthKeyFormat() {
        let key = Budget.currentMonthKey()
        let regex = try? NSRegularExpression(pattern: #"^\d{4}-\d{2}$"#)
        let range = NSRange(location: 0, length: key.utf16.count)
        XCTAssertNotNil(regex?.firstMatch(in: key, options: [], range: range), "Month key should follow YYYY-MM format")
    }
    
    func testBudgetInitialization() {
        let budget = Budget(month: "2026-08", totalBudget: 15000)
        XCTAssertEqual(budget.month, "2026-08")
        XCTAssertEqual(budget.totalBudget, 15000)
        XCTAssertEqual(budget.categoryAllocations?.count, 0)
    }
    
    func testRemainingBudgetCalculation() {
        let budget = Budget(month: "2026-08", totalBudget: 20000)
        let totalSpend = 8500.0
        let remaining = budget.totalBudget - totalSpend
        XCTAssertEqual(remaining, 11500.0)
        XCTAssertGreaterThan(remaining, 0)
    }
}
