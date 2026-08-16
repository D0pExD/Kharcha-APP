import Foundation
import SwiftData

@Model
final class Expense {
    var amount: Double
    var note: String
    var paymentMode: String // "cash", "upi", "card", "online"
    
    @Attribute(.externalStorage)
    var photo: Data?
    
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship var category: ExpenseCategory?
    
    @Relationship(deleteRule: .cascade) 
    var auditLogs: [ExpenseAuditLog]?
    
    init(
        amount: Double,
        note: String = "",
        paymentMode: String = "cash",
        photo: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        category: ExpenseCategory? = nil
    ) {
        self.amount = amount
        self.note = note
        self.paymentMode = paymentMode
        self.photo = photo
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Payment Mode

enum PaymentMode: String, CaseIterable, Codable, Identifiable {
    case cash = "cash"
    case upi = "upi"
    case card = "card"
    case online = "online"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .upi: return "UPI"
        case .card: return "Card"
        case .online: return "Online"
        }
    }
    
    var icon: String {
        switch self {
        case .cash: return "indianrupeesign.circle.fill"
        case .upi: return "iphone.gen3"
        case .card: return "creditcard.fill"
        case .online: return "globe"
        }
    }
}
