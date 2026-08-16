import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    
    @Binding var showQuickAdd: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \Expense.createdAt, order: .reverse) private var allExpenses: [Expense]
    @Query private var profiles: [UserProfile]
    @Query private var budgets: [Budget]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    @State private var showToast = false
    @State private var toastMessage = ""
    
    private var profile: UserProfile? { profiles.first }
    
    private var currentMonthExpenses: [Expense] {
        let startOfMonth = Date().startOfMonth
        return allExpenses.filter { $0.createdAt >= startOfMonth }
    }
    
    private var totalSpentThisMonth: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyBudget: Double {
        let key = Budget.currentMonthKey()
        return budgets.first(where: { $0.month == key })?.totalBudget ?? profile?.monthlyBudget ?? 10000
    }
    
    private var todayExpenses: [Expense] {
        allExpenses.filter { $0.createdAt.isToday }
    }
    
    private var todaySpend: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var weekSpend: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return allExpenses.filter { $0.createdAt >= weekAgo }.reduce(0) { $0 + $1.amount }
    }
    
    private var avgDaily: Double {
        let startOfMonth = Date().startOfMonth
        let daysSoFar = max(1, Calendar.current.dateComponents([.day], from: startOfMonth, to: Date()).day ?? 1)
        return totalSpentThisMonth / Double(daysSoFar)
    }
    
    private var budgetPercentage: Double {
        guard monthlyBudget > 0 else { return 0 }
        return totalSpentThisMonth / monthlyBudget
    }
    
    // Group expenses by date
    private var groupedExpenses: [(date: Date, expenses: [Expense])] {
        let grouped = Dictionary(grouping: allExpenses.prefix(30)) { expense in
            Calendar.current.startOfDay(for: expense.createdAt)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, expenses: $0.value) }
    }
    
    // Category breakdown for donut
    private var categoryBreakdown: [(category: ExpenseCategory, total: Double)] {
        var totals: [PersistentIdentifier: Double] = [:]
        var catMap: [PersistentIdentifier: ExpenseCategory] = [:]
        
        for expense in currentMonthExpenses {
            if let cat = expense.category {
                totals[cat.persistentModelID, default: 0] += expense.amount
                catMap[cat.persistentModelID] = cat
            }
        }
        
        return totals
            .compactMap { (id, total) in
                guard let cat = catMap[id] else { return nil }
                return (category: cat, total: total)
            }
            .sorted { $0.total > $1.total }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    if let profile {
                        HStack {
                            Text(loc.greeting(name: profile.name))
                                .font(.title3.weight(.semibold))
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Balance Card
                    balanceCard
                    
                    // Quick Stats
                    quickStatsRow
                    
                    // Category Donut
                    if !categoryBreakdown.isEmpty {
                        categoryDonutSection
                    }
                    
                    // Recent Expenses
                    recentExpensesSection
                }
                .padding(.bottom, 100)
            }
            .navigationTitle("Kharcha")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // FAB
                Button {
                    showQuickAdd = true
                    UIImpactFeedbackGenerator.fire()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(Color.accent, in: Circle())
                        .shadow(color: Color.accent.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .desiToast(isPresented: $showToast, message: toastMessage, icon: "💰")
        .onAppear {
            WidgetDataManager.shared.update(
                todaySpend: todaySpend,
                budgetLeft: monthlyBudget - totalSpentThisMonth,
                budgetTotal: monthlyBudget
            )
        }
        .onChange(of: totalSpentThisMonth) { _, _ in
            WidgetDataManager.shared.update(
                todaySpend: todaySpend,
                budgetLeft: monthlyBudget - totalSpentThisMonth,
                budgetTotal: monthlyBudget
            )
        }
    }
    
    // MARK: - Balance Card
    
    private var balanceCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text(loc.string(for: .thisMonth))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                
                Text(Date(), format: .dateTime.month(.wide).year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.accent)
                
                Text("\(Int(totalSpentThisMonth))")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                
                Spacer()
            }
            
            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(budgetPercentage > 1 ? Color.red : Color.accent)
                            .frame(width: geo.size.width * min(budgetPercentage, 1), height: 8)
                            .animation(.spring, value: budgetPercentage)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text(DesiMessages.budgetStatus(percentage: budgetPercentage * 100, language: loc.currentLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(loc.string(for: .budgetLeft)): \((monthlyBudget - totalSpentThisMonth).rupeesFullFormatted)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(budgetPercentage > 1 ? .red : Color.accent)
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // MARK: - Quick Stats
    
    private var quickStatsRow: some View {
        HStack(spacing: 10) {
            StatCard(
                title: loc.string(for: .todaySpend),
                value: todaySpend.rupeesFormatted,
                icon: "sun.max.fill",
                color: .saffron
            )
            StatCard(
                title: loc.string(for: .weekSpend),
                value: weekSpend.rupeesFormatted,
                icon: "calendar",
                color: .appPurple
            )
            StatCard(
                title: loc.string(for: .avgDaily),
                value: avgDaily.rupeesFormatted,
                icon: "chart.line.uptrend.xyaxis",
                color: Color.accent
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Category Donut
    
    private var categoryDonutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.string(for: .categoryBreakdown))
                .font(.headline)
                .padding(.horizontal)
            
            Chart(categoryBreakdown, id: \.category.persistentModelID) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(Color(hex: item.category.colorHex))
                .cornerRadius(4)
            }
            .frame(height: 200)
            .padding(.horizontal)
            
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(categoryBreakdown.prefix(6), id: \.category.persistentModelID) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: item.category.colorHex))
                            .frame(width: 10, height: 10)
                        
                        Text("\(item.category.emoji) \(item.category.localizedName(for: loc.currentLanguage))")
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(item.total.rupeesFormatted)
                            .font(.caption.weight(.medium))
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // MARK: - Recent Expenses
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.string(for: .recentExpenses))
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: HistoryView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal)
            
            if groupedExpenses.isEmpty {
                EmptyStateView(
                    emoji: "📝",
                    message: loc.string(for: .emptyExpenses),
                    actionTitle: loc.string(for: .tabAdd),
                    action: { showQuickAdd = true }
                )
            } else {
                ForEach(groupedExpenses.prefix(3), id: \.date) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.date.relativeHeader(language: loc.currentLanguage))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(group.expenses) { expense in
                            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                ExpenseRowView(expense: expense)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Expense Row

struct ExpenseRowView: View {
    
    let expense: Expense
    @Environment(LocalizationManager.self) private var loc
    
    var body: some View {
        HStack(spacing: 12) {
            // Category emoji
            Text(expense.category?.emoji ?? "💰")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    Color(hex: expense.category?.colorHex ?? "#9E9E9E").opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.category?.localizedName(for: loc.currentLanguage) ?? "Kharcha")
                    .font(.subheadline.weight(.medium))
                
                HStack(spacing: 6) {
                    if let location = expense.locationName {
                        HStack(spacing: 2) {
                            Image(systemName: "mappin")
                            Text(location)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                    
                    Text(expense.createdAt.timeString)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    if expense.photo != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(expense.amount.rupeesFullFormatted)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                
                HStack(spacing: 3) {
                    Image(systemName: PaymentMode(rawValue: expense.paymentMode)?.icon ?? "indianrupeesign.circle")
                        .font(.caption2)
                    Text(expense.paymentMode.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
