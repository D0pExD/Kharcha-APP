import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \Expense.createdAt, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [Budget]
    @Query private var profiles: [UserProfile]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    @State private var showExportSheet = false
    @State private var csvFileURL: URL?
    
    private var monthlyBudget: Double {
        let key = Budget.currentMonthKey()
        return budgets.first(where: { $0.month == key })?.totalBudget ?? profiles.first?.monthlyBudget ?? 10000
    }
    
    private var currentMonthExpenses: [Expense] {
        let startOfMonth = Date().startOfMonth
        return allExpenses.filter { $0.createdAt >= startOfMonth }
    }
    
    private var totalSpent: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var remaining: Double { monthlyBudget - totalSpent }
    private var budgetPercentage: Double {
        guard monthlyBudget > 0 else { return 0 }
        return totalSpent / monthlyBudget
    }
    
    // Daily spending for chart
    private var dailySpending: [DailySpend] {
        let cal = Calendar.current
        let startOfMonth = Date().startOfMonth
        let grouped = Dictionary(grouping: currentMonthExpenses) { expense in
            cal.startOfDay(for: expense.createdAt)
        }
        
        var result: [DailySpend] = []
        var currentDate = startOfMonth
        let today = cal.startOfDay(for: Date())
        
        while currentDate <= today {
            let total = grouped[currentDate]?.reduce(0) { $0 + $1.amount } ?? 0
            result.append(DailySpend(date: currentDate, amount: total))
            currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return result
    }
    
    // Category breakdown
    private var categoryBreakdown: [(category: ExpenseCategory, total: Double, percentage: Double)] {
        var totals: [PersistentIdentifier: Double] = [:]
        var catMap: [PersistentIdentifier: ExpenseCategory] = [:]
        
        for expense in currentMonthExpenses {
            if let cat = expense.category {
                totals[cat.persistentModelID, default: 0] += expense.amount
                catMap[cat.persistentModelID] = cat
            }
        }
        
        let grandTotal = max(totalSpent, 1)
        return totals
            .compactMap { (id, total) in
                guard let cat = catMap[id] else { return nil }
                return (category: cat, total: total, percentage: total / grandTotal * 100)
            }
            .sorted { $0.total > $1.total }
    }
    
    // Location breakdown
    private var locationBreakdown: [(location: String, total: Double)] {
        var totals: [String: Double] = [:]
        for expense in currentMonthExpenses {
            if let loc = expense.locationName, !loc.isEmpty {
                totals[loc, default: 0] += expense.amount
            }
        }
        return totals
            .map { (location: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget Overview
                    budgetOverviewCard
                    
                    // Daily Trend Chart
                    if !dailySpending.isEmpty {
                        dailyTrendSection
                    }
                    
                    // Category Donut
                    if !categoryBreakdown.isEmpty {
                        categorySection
                    }
                    
                    // Top Locations
                    if !locationBreakdown.isEmpty {
                        locationSection
                    }
                    
                    // Export
                    exportSection
                }
                .padding(.bottom, 100)
            }
            .navigationTitle(loc.string(for: .budgetInsights))
        }
    }
    
    // MARK: - Budget Overview
    
    private var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(Date(), format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
            }
            
            // Ring gauge
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 14)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: min(budgetPercentage, 1))
                    .stroke(
                        budgetPercentage > 1 ? Color.red : Color.accent,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 140, height: 140)
                    .animation(.spring, value: budgetPercentage)
                
                VStack(spacing: 2) {
                    Text("\(Int(budgetPercentage * 100))%")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text(loc.string(for: .spent))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            // Stats row
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(loc.string(for: .spent))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalSpent.rupeesFullFormatted)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(budgetPercentage > 1 ? .red : .primary)
                }
                .frame(maxWidth: .infinity)
                
                Divider().frame(height: 30)
                
                VStack(spacing: 4) {
                    Text(loc.string(for: .budget))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(monthlyBudget.rupeesFullFormatted)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                
                Divider().frame(height: 30)
                
                VStack(spacing: 4) {
                    Text(loc.string(for: .remaining))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(remaining.rupeesFullFormatted)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(remaining >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // MARK: - Daily Trend
    
    private var dailyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.string(for: .dailyTrend))
                .font(.headline)
                .padding(.horizontal)
            
            Chart(dailySpending) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(Color.accent.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(val.rupeesFormatted)
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.string(for: .topCategories))
                .font(.headline)
                .padding(.horizontal)
            
            // Donut
            Chart(categoryBreakdown, id: \.category.persistentModelID) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(Color(hex: item.category.colorHex))
                .cornerRadius(4)
            }
            .frame(height: 180)
            .padding(.horizontal)
            
            // List
            ForEach(Array(categoryBreakdown.prefix(6).enumerated()), id: \.element.category.persistentModelID) { index, item in
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                    
                    Text(item.category.emoji)
                        .font(.body)
                    
                    Text(item.category.localizedName(for: loc.currentLanguage))
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(item.total.rupeesFullFormatted)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                    
                    Text("(\(Int(item.percentage))%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.string(for: .topLocations))
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(Array(locationBreakdown.prefix(5).enumerated()), id: \.element.location) { index, item in
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.saffron)
                    
                    Text(item.location)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(item.total.rupeesFullFormatted)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // MARK: - Export
    
    private var exportSection: some View {
        Button {
            let csv = CSVExporter.exportExpenses(allExpenses, language: loc.currentLanguage)
            if let url = CSVExporter.saveToFile(csv) {
                csvFileURL = url
                showExportSheet = true
            }
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text(loc.string(for: .exportCSV))
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .sheet(isPresented: $showExportSheet) {
            if let url = csvFileURL {
                ShareSheet(items: [url])
            }
        }
    }
}

// MARK: - Daily Spend Data

struct DailySpend: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
