import SwiftUI
import SwiftData

struct HistoryView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \Expense.createdAt, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    @State private var searchText = ""
    @State private var selectedCategoryFilter: ExpenseCategory?
    @State private var selectedPaymentFilter: PaymentMode?
    
    private var filteredExpenses: [Expense] {
        var result = allExpenses
        
        if !searchText.isEmpty {
            result = result.filter { expense in
                expense.note.localizedCaseInsensitiveContains(searchText) ||
                expense.category?.name.localizedCaseInsensitiveContains(searchText) == true ||
                expense.locationName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        if let catFilter = selectedCategoryFilter {
            result = result.filter { $0.category?.persistentModelID == catFilter.persistentModelID }
        }
        
        if let payFilter = selectedPaymentFilter {
            result = result.filter { $0.paymentMode == payFilter.rawValue }
        }
        
        return result
    }
    
    private var groupedExpenses: [(date: Date, expenses: [Expense])] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.startOfDay(for: expense.createdAt)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, expenses: $0.value) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterChips
                
                if filteredExpenses.isEmpty {
                    Spacer()
                    EmptyStateView(
                        emoji: "🔍",
                        message: loc.string(for: .emptyExpenses)
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.date) { group in
                            Section {
                                ForEach(group.expenses) { expense in
                                    NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                        ExpenseRowView(expense: expense)
                                    }
                                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 16))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                modelContext.delete(expense)
                                                try? modelContext.save()
                                            }
                                        } label: {
                                            Label(loc.string(for: .delete), systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Text(group.date.relativeHeader(language: loc.currentLanguage))
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(loc.string(for: .expenseHistory))
            .searchable(text: $searchText, prompt: loc.string(for: .searchPlaceholder))
        }
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All
                filterChip(
                    title: loc.string(for: .filterAll),
                    isSelected: selectedCategoryFilter == nil && selectedPaymentFilter == nil
                ) {
                    selectedCategoryFilter = nil
                    selectedPaymentFilter = nil
                }
                
                // Category filters
                ForEach(categories) { category in
                    filterChip(
                        title: "\(category.emoji) \(category.localizedName(for: loc.currentLanguage))",
                        isSelected: selectedCategoryFilter?.persistentModelID == category.persistentModelID
                    ) {
                        if selectedCategoryFilter?.persistentModelID == category.persistentModelID {
                            selectedCategoryFilter = nil
                        } else {
                            selectedCategoryFilter = category
                        }
                    }
                }
                
                Divider().frame(height: 20)
                
                // Payment mode filters
                ForEach(PaymentMode.allCases) { mode in
                    filterChip(
                        title: mode.displayName,
                        isSelected: selectedPaymentFilter == mode
                    ) {
                        if selectedPaymentFilter == mode {
                            selectedPaymentFilter = nil
                        } else {
                            selectedPaymentFilter = mode
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            UIImpactFeedbackGenerator.fire(.light)
        }) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isSelected ? Color.accent : Color(.tertiarySystemGroupedBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}
