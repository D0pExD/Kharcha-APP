import SwiftUI
import SwiftData

@main
struct KharchaApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        do {
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
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
