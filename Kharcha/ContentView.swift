import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Query private var profiles: [UserProfile]
    @State private var localization = LocalizationManager.shared
    
    private var hasCompletedOnboarding: Bool {
        profiles.first?.hasCompletedOnboarding ?? false
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environment(localization)
        .tint(Color.accent)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    
    @State private var selectedTab: AppTab = .home
    @State private var showQuickAdd = false
    @Environment(LocalizationManager.self) private var loc
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(showQuickAdd: $showQuickAdd)
                .tabItem {
                    Label(loc.string(for: .tabHome), systemImage: "house.fill")
                }
                .tag(AppTab.home)
            
            BudgetView()
                .tabItem {
                    Label(loc.string(for: .tabBudget), systemImage: "chart.pie.fill")
                }
                .tag(AppTab.budget)
            
            FitnessView()
                .tabItem {
                    Label(loc.string(for: .fitness), systemImage: "heart.fill")
                }
                .tag(AppTab.fitness)
            
            TimetableView()
                .tabItem {
                    Label(loc.string(for: .tabSchedule), systemImage: "calendar")
                }
                .tag(AppTab.schedule)
            
            SettingsView()
                .tabItem {
                    Label(loc.string(for: .tabProfile), systemImage: "person.fill")
                }
                .tag(AppTab.profile)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .add {
                showQuickAdd = true
                selectedTab = .home
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Tab Enum

enum AppTab: String, CaseIterable {
    case home, budget, fitness, add, schedule, profile
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Expense.self,
            ExpenseCategory.self,
            Budget.self,
            UserProfile.self,
            WaterIntake.self,
            Workout.self
        ], inMemory: true)
}
