import Foundation
import SwiftData

struct BackupData: Codable {
    var expenses: [ExpenseBackup]
    var categories: [CategoryBackup]
    var budgets: [BudgetBackup]
    var profiles: [ProfileBackup]
}

struct ExpenseBackup: Codable {
    var id: String
    var amount: Double
    var note: String?
    var createdAt: Date
    var categoryId: String?
    var paymentMode: String?
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
}

struct CategoryBackup: Codable {
    var id: String
    var name: String
    var emoji: String
    var colorHex: String
    var isDefault: Bool
    var sortOrder: Int
    var nameHinglish: String
    var nameEnglish: String
    var nameHindi: String
}

struct BudgetBackup: Codable {
    var id: String
    var month: String
    var totalBudget: Double
}

struct ProfileBackup: Codable {
    var id: String
    var name: String
    var phone: String
    var age: Int
    var gender: String
    var college: String
    var monthlyBudget: Double
    var language: String
    var hasCompletedOnboarding: Bool
}

final class BackupManager {
    static let shared = BackupManager()
    
    private init() {}
    
    // MARK: - Export
    
    func exportData(from context: ModelContext) throws -> URL {
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        let categories = try context.fetch(FetchDescriptor<ExpenseCategory>())
        let budgets = try context.fetch(FetchDescriptor<Budget>())
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        
        var categoryIDMap = [PersistentIdentifier: String]()
        var categoryBackups = [CategoryBackup]()
        
        for c in categories {
            let catID = UUID().uuidString
            categoryIDMap[c.id] = catID
            categoryBackups.append(
                CategoryBackup(
                    id: catID,
                    name: c.name,
                    emoji: c.emoji,
                    colorHex: c.colorHex,
                    isDefault: c.isDefault,
                    sortOrder: c.sortOrder,
                    nameHinglish: c.nameHinglish,
                    nameEnglish: c.nameEnglish,
                    nameHindi: c.nameHindi
                )
            )
        }
        
        let backup = BackupData(
            expenses: expenses.map { e in
                let matchedCatID = e.category.flatMap { categoryIDMap[$0.id] }
                return ExpenseBackup(
                    id: UUID().uuidString,
                    amount: e.amount,
                    note: e.note,
                    createdAt: e.createdAt,
                    categoryId: matchedCatID,
                    paymentMode: e.paymentMode,
                    latitude: e.latitude,
                    longitude: e.longitude,
                    locationName: e.locationName
                )
            },
            categories: categoryBackups,
            budgets: budgets.map { b in
                BudgetBackup(
                    id: UUID().uuidString,
                    month: b.month,
                    totalBudget: b.totalBudget
                )
            },
            profiles: profiles.map { p in
                ProfileBackup(
                    id: UUID().uuidString,
                    name: p.name,
                    phone: p.phone,
                    age: p.age,
                    gender: p.gender,
                    college: p.college,
                    monthlyBudget: p.monthlyBudget,
                    language: p.language,
                    hasCompletedOnboarding: p.hasCompletedOnboarding
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backup)
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("KharchaBackup.json")
        try data.write(to: url)
        return url
    }
    
    // MARK: - Import
    
    func importData(from url: URL, into context: ModelContext) throws {
        // Read data
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let backup = try decoder.decode(BackupData.self, from: data)
        
        // Wipe existing data to avoid duplicates/conflicts
        try context.delete(model: Expense.self)
        try context.delete(model: ExpenseCategory.self)
        try context.delete(model: Budget.self)
        try context.delete(model: UserProfile.self)
        
        // Dictionary to link categories
        var categoryMap = [String: ExpenseCategory]()
        
        // Insert Categories
        for cb in backup.categories {
            let cat = ExpenseCategory(
                name: cb.name,
                emoji: cb.emoji,
                colorHex: cb.colorHex,
                isDefault: cb.isDefault,
                sortOrder: cb.sortOrder,
                nameHinglish: cb.nameHinglish,
                nameEnglish: cb.nameEnglish,
                nameHindi: cb.nameHindi
            )
            context.insert(cat)
            categoryMap[cb.id] = cat
        }
        
        // Insert Expenses
        for eb in backup.expenses {
            let exp = Expense(
                amount: eb.amount,
                note: eb.note ?? "",
                paymentMode: eb.paymentMode ?? "upi",
                latitude: eb.latitude,
                longitude: eb.longitude,
                locationName: eb.locationName
            )
            exp.createdAt = eb.createdAt
            if let catId = eb.categoryId, let cat = categoryMap[catId] {
                exp.category = cat
            }
            context.insert(exp)
        }
        
        // Insert Budgets
        for bb in backup.budgets {
            let bud = Budget(month: bb.month, totalBudget: bb.totalBudget)
            context.insert(bud)
        }
        
        // Insert Profiles
        for pb in backup.profiles {
            let prof = UserProfile(
                name: pb.name,
                phone: pb.phone,
                age: pb.age,
                gender: pb.gender,
                college: pb.college,
                monthlyBudget: pb.monthlyBudget,
                language: pb.language,
                hasCompletedOnboarding: pb.hasCompletedOnboarding
            )
            context.insert(prof)
        }
        
        try context.save()
    }
}
