import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Dynamic Category AppEntity

struct CategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryEntityQuery()
    
    var id: String
    var name: String
    var emoji: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }
}

// MARK: - Dynamic Category Entity Query

struct CategoryEntityQuery: EntityQuery, EnumerableEntityQuery {
    
    @MainActor
    func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        try await allEntities().filter { identifiers.contains($0.id) }
    }
    
    @MainActor
    func suggestedEntities() async throws -> [CategoryEntity] {
        try await allEntities()
    }
    
    @MainActor
    func allEntities() async throws -> [CategoryEntity] {
        let schema = Schema([
            Expense.self,
            ExpenseCategory.self,
            Budget.self,
            UserProfile.self,
            WaterIntake.self,
            Workout.self,
            ClassSchedule.self,
            Assignment.self,
            ExpenseAuditLog.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return []
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<ExpenseCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let categories = try? context.fetch(descriptor), !categories.isEmpty else {
            return ExpenseCategory.defaultCategories.map {
                CategoryEntity(id: $0.name, name: $0.hinglish, emoji: $0.emoji)
            }
        }
        
        let currentLang = LocalizationManager.shared.currentLanguage
        return categories.map { cat in
            CategoryEntity(
                id: cat.name,
                name: cat.localizedName(for: currentLang),
                emoji: cat.emoji
            )
        }
    }
}

// MARK: - Log Expense Intent

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Kharcha"
    static var description: IntentDescription = IntentDescription("Log an expense asking for Amount, Category, and Note.")
    static var openAppWhenRun: Bool = false
    
    @Parameter(
        title: "Amount",
        description: "How much did you spend?",
        requestValueDialog: "Kitna kharcha hua (Amount)? 💸"
    )
    var amount: Double
    
    @Parameter(
        title: "Category",
        description: "Which category does this expense belong to?",
        requestValueDialog: "Kaunsi category ka kharcha hai? 🏷️"
    )
    var category: CategoryEntity
    
    @Parameter(
        title: "Note",
        description: "Note or description for this expense",
        requestValueDialog: "Koi note ya description likhna hai? 📝"
    )
    var note: String
    
    @Parameter(
        title: "Photo",
        description: "Optional receipt image"
    )
    var photo: IntentFile?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) in \(\.$category) with note \(\.$note)") {
            \.$photo
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([
            Expense.self,
            ExpenseCategory.self,
            Budget.self,
            UserProfile.self,
            WaterIntake.self,
            Workout.self,
            ClassSchedule.self,
            Assignment.self,
            ExpenseAuditLog.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        // Find matching Category dynamically from Database
        let descriptor = FetchDescriptor<ExpenseCategory>()
        let allCategories = (try? context.fetch(descriptor)) ?? []
        
        let matchedCategory = allCategories.first {
            $0.name == category.id ||
            $0.name.localizedCaseInsensitiveContains(category.name) ||
            $0.nameEnglish.localizedCaseInsensitiveContains(category.name) ||
            $0.nameHinglish.localizedCaseInsensitiveContains(category.name)
        } ?? allCategories.first
        
        let cleanedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var photoData: Data? = nil
        if let photoFile = photo {
            photoData = photoFile.data
        }
        
        // Fetch Real GPS Location
        let locData = await LocationManager.shared.fetchLocationAsync()
        
        let expense = Expense(
            amount: amount,
            note: cleanedNote,
            paymentMode: "upi",
            photo: photoData,
            latitude: locData.lat,
            longitude: locData.lng,
            locationName: locData.name,
            category: matchedCategory
        )
        context.insert(expense)
        try? context.save()
        
        // Update Widgets in real-time
        var widgetData = WidgetDataManager.shared.load()
        widgetData.todaySpend += amount
        widgetData.monthlyBudgetLeft -= amount
        WidgetDataManager.shared.save(data: widgetData)
        WidgetCenter.shared.reloadAllTimelines()
        
        let catEmoji = matchedCategory?.emoji ?? category.emoji
        let catName = matchedCategory?.localizedName(for: LocalizationManager.shared.currentLanguage) ?? category.name
        
        let noteInfo = cleanedNote.isEmpty ? "" : " (\(cleanedNote))"
        return .result(dialog: "Added ₹\(Int(amount)) for \(catEmoji) \(catName)\(noteInfo) to Kharcha! 🎉")
    }
}

// MARK: - Attach Receipt Intent (Optional Photo Step)

struct AttachReceiptIntent: AppIntent {
    static var title: LocalizedStringResource = "Attach Receipt Photo"
    static var description: IntentDescription = IntentDescription("Attaches a photo receipt to the most recently added expense.")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Photo", description: "Receipt photo image")
    var photo: IntentFile
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let schema = Schema([
            Expense.self,
            ExpenseCategory.self,
            Budget.self,
            UserProfile.self,
            WaterIntake.self,
            Workout.self,
            ClassSchedule.self,
            Assignment.self,
            ExpenseAuditLog.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return .result()
        }
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\Expense.createdAt, order: .reverse)])
        if let latestExpense = (try? context.fetch(descriptor))?.first {
            latestExpense.photo = photo.data
            try? context.save()
        }
        return .result()
    }
}
