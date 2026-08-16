import XCTest
@testable import Kharcha

final class BackupManagerTests: XCTestCase {
    
    func testBackupDataEncodingDecodingRoundtrip() throws {
        let sampleExpense = BackupExpenseData(
            amount: 250.0,
            note: "Coffee & Snacks",
            paymentMode: "upi",
            createdAt: Date(),
            categoryName: "Chai-Sutta"
        )
        
        let sampleCategory = BackupCategoryData(
            name: "Chai-Sutta",
            emoji: "☕",
            colorHex: "#795548",
            nameHinglish: "Chai-Sutta",
            nameEnglish: "Tea & Coffee",
            nameHindi: "चाय-सुट्टा"
        )
        
        let backup = KharchaBackupPayload(
            version: "1.0.0",
            exportedAt: Date(),
            expenses: [sampleExpense],
            categories: [sampleCategory]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        XCTAssertGreaterThan(data.count, 0)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(KharchaBackupPayload.self, from: data)
        
        XCTAssertEqual(decoded.version, "1.0.0")
        XCTAssertEqual(decoded.expenses.count, 1)
        XCTAssertEqual(decoded.expenses.first?.amount, 250.0)
        XCTAssertEqual(decoded.expenses.first?.categoryName, "Chai-Sutta")
        XCTAssertEqual(decoded.categories.first?.emoji, "☕")
    }
}
