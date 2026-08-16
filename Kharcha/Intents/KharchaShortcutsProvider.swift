import AppIntents

struct KharchaShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log a kharcha in \(.applicationName)",
                "Add an expense in \(.applicationName)",
                "Log expense in \(.applicationName)",
                "Add a kharcha in \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "indianrupeesign.circle.fill"
        )
    }
}
