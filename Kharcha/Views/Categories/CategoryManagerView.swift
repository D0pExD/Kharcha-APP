import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc
    
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    @State private var showAddSheet = false
    @State private var editingCategory: ExpenseCategory?
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: ExpenseCategory?
    
    var body: some View {
        List {
            Section(header: Text("Categories")) {
                ForEach(categories) { category in
                    HStack(spacing: 12) {
                        Text(category.emoji)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color(hex: category.colorHex).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.localizedName(for: loc.currentLanguage))
                                .font(.subheadline.weight(.medium))
                            
                            if category.isDefault {
                                Text("Default")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Expense count
                        let count = category.expenses?.count ?? 0
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingCategory = category
                    }
                    .swipeActions(edge: .trailing) {
                        if !category.isDefault {
                            Button(role: .destructive) {
                                categoryToDelete = category
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        
                        Button {
                            editingCategory = category
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
                .onMove { source, destination in
                    var reordered = categories.map { $0 }
                    reordered.move(fromOffsets: source, toOffset: destination)
                    for (index, cat) in reordered.enumerated() {
                        cat.sortOrder = index
                    }
                    try? modelContext.save()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(loc.string(for: .categories))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCategorySheet()
        }
        .sheet(item: $editingCategory) { category in
            EditCategorySheet(category: category)
        }
        .alert("Delete Category?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let cat = categoryToDelete {
                    modelContext.delete(cat)
                    try? modelContext.save()
                }
            }
        } message: {
            Text("Expenses in this category will become uncategorized.")
        }
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    @State private var emoji = "📦"
    @State private var name = ""
    @State private var nameEnglish = ""
    @State private var nameHindi = ""
    @State private var selectedColor = "#FF6D00"
    
    private let colorOptions = [
        "#FF6D00", "#E91E63", "#9C27B0", "#3F51B5",
        "#2196F3", "#00BCD4", "#4CAF50", "#8BC34A",
        "#FF9800", "#795548", "#607D8B", "#F44336"
    ]
    
    private let emojiOptions = [
        "🍔", "☕", "🚗", "📚", "🎬", "👕", "💊", "📱",
        "🏠", "🎁", "💇", "🛒", "🍕", "🏋️", "✂️", "🎮",
        "🐕", "🎵", "💻", "🎨", "✈️", "🍺", "🧴", "📦"
    ]
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(emojiOptions, id: \.self) { e in
                            Button {
                                emoji = e
                                UIImpactFeedbackGenerator.fire(.light)
                            } label: {
                                Text(e)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        emoji == e ? Color.accent.opacity(0.2) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(emoji == e ? Color.accent : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                
                Section("Name") {
                    TextField("Hinglish Name", text: $name)
                    TextField("English Name (optional)", text: $nameEnglish)
                    TextField("Hindi Name (optional)", text: $nameHindi)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .shadow(color: selectedColor == color ? Color(hex: color).opacity(0.5) : .clear, radius: 4)
                                .onTapGesture {
                                    selectedColor = color
                                    UIImpactFeedbackGenerator.fire(.light)
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Preview
                Section("Preview") {
                    HStack(spacing: 12) {
                        Text(emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: selectedColor).opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let cat = ExpenseCategory(
                            name: name.trimmingCharacters(in: .whitespaces),
                            emoji: emoji,
                            colorHex: selectedColor,
                            isDefault: false,
                            sortOrder: categories.count,
                            nameHinglish: name,
                            nameEnglish: nameEnglish.isEmpty ? name : nameEnglish,
                            nameHindi: nameHindi.isEmpty ? name : nameHindi
                        )
                        modelContext.insert(cat)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Edit Category Sheet

struct EditCategorySheet: View {
    
    @Bindable var category: ExpenseCategory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var emoji: String
    @State private var nameHinglish: String
    @State private var nameEnglish: String
    @State private var nameHindi: String
    @State private var selectedColor: String
    
    private let colorOptions = [
        "#FF6D00", "#E91E63", "#9C27B0", "#3F51B5",
        "#2196F3", "#00BCD4", "#4CAF50", "#8BC34A",
        "#FF9800", "#795548", "#607D8B", "#F44336"
    ]
    
    init(category: ExpenseCategory) {
        self.category = category
        _emoji = State(initialValue: category.emoji)
        _nameHinglish = State(initialValue: category.nameHinglish)
        _nameEnglish = State(initialValue: category.nameEnglish)
        _nameHindi = State(initialValue: category.nameHindi)
        _selectedColor = State(initialValue: category.colorHex)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Emoji") {
                    TextField("Emoji", text: $emoji)
                        .font(.title)
                }
                
                Section("Names") {
                    TextField("Hinglish", text: $nameHinglish)
                    TextField("English", text: $nameEnglish)
                    TextField("Hindi", text: $nameHindi)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        category.emoji = emoji
                        category.nameHinglish = nameHinglish
                        category.nameEnglish = nameEnglish
                        category.nameHindi = nameHindi
                        category.name = nameHinglish
                        category.colorHex = selectedColor
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
