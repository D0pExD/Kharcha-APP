import Foundation
import SwiftData

@Model
final class ExpenseCategory {
    var name: String
    var emoji: String
    var colorHex: String
    var isDefault: Bool
    var sortOrder: Int
    
    // Localized names
    var nameHinglish: String
    var nameEnglish: String
    var nameHindi: String
    
    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]?
    
    init(
        name: String,
        emoji: String,
        colorHex: String,
        isDefault: Bool = false,
        sortOrder: Int = 0,
        nameHinglish: String = "",
        nameEnglish: String = "",
        nameHindi: String = ""
    ) {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.nameHinglish = nameHinglish.isEmpty ? name : nameHinglish
        self.nameEnglish = nameEnglish.isEmpty ? name : nameEnglish
        self.nameHindi = nameHindi.isEmpty ? name : nameHindi
    }
    
    /// Returns the localized name based on current language setting
    func localizedName(for language: AppLanguage) -> String {
        switch language {
        case .hinglish: return nameHinglish
        case .english: return nameEnglish
        case .hindi: return nameHindi
        }
    }
}

// MARK: - Default Categories

extension ExpenseCategory {
    
    static let defaultCategories: [(name: String, emoji: String, color: String, hinglish: String, english: String, hindi: String)] = [
        ("Khaana-Peena", "🍔", "#FF6D00", "Khaana-Peena", "Food & Drinks", "खाना-पीना"),
        ("Chai-Sutta", "☕", "#795548", "Chai-Sutta", "Tea & Coffee", "चाय-सुट्टा"),
        ("Sawari", "🚗", "#2196F3", "Sawari", "Transport", "सवारी"),
        ("Padhai", "📚", "#4CAF50", "Padhai", "Study & Books", "पढ़ाई"),
        ("Masti", "🎬", "#E91E63", "Masti", "Entertainment", "मस्ती"),
        ("Kapde", "👕", "#9C27B0", "Kapde", "Clothing", "कपड़े"),
        ("Dawa", "💊", "#F44336", "Dawa", "Medical", "दवाई"),
        ("Recharge", "📱", "#00BCD4", "Recharge", "Recharge & Bills", "रिचार्ज"),
        ("Kiraya", "🏠", "#FF9800", "Kiraya/PG", "Rent & PG", "किराया"),
        ("Tohfe", "🎁", "#E040FB", "Tohfe", "Gifts", "तोहफे"),
        ("Hajjam", "💇", "#607D8B", "Hajjam", "Grooming", "हज्जाम"),
        ("Shopping", "🛒", "#8BC34A", "Shopping", "Shopping", "शॉपिंग"),
        ("Zomato/Swiggy", "🍕", "#FF5722", "Zomato/Swiggy", "Food Delivery", "ऑनलाइन खाना"),
        ("Gym", "🏋️", "#3F51B5", "Gym", "Gym & Fitness", "जिम"),
        ("Futkar", "✂️", "#9E9E9E", "Futkar", "Miscellaneous", "फुटकर")
    ]
    
    static func seedDefaults(in context: ModelContext) {
        // Check if categories already exist
        let descriptor = FetchDescriptor<ExpenseCategory>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }
        
        for (index, cat) in defaultCategories.enumerated() {
            let category = ExpenseCategory(
                name: cat.name,
                emoji: cat.emoji,
                colorHex: cat.color,
                isDefault: true,
                sortOrder: index,
                nameHinglish: cat.hinglish,
                nameEnglish: cat.english,
                nameHindi: cat.hindi
            )
            context.insert(category)
        }
        try? context.save()
    }
}
