import SwiftUI
import SwiftData

struct SettingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @Query private var profiles: [UserProfile]
    @Query private var allExpenses: [Expense]
    
    @State private var showCategoryManager = false
    @State private var showClearDataAlert = false
    @State private var showExportSheet = false
    @State private var showEditProfile = false
    @State private var csvFileURL: URL?
    
    // Backup States
    @State private var showBackupExporter = false
    @State private var showBackupImporter = false
    @State private var backupURL: URL?
    @State private var showToast = false
    @State private var toastMessage = ""
    
    private var profile: UserProfile? { profiles.first }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                if let profile {
                    Section {
                        Button {
                            showEditProfile = true
                        } label: {
                            HStack {
                                Text("Edit Profile")
                                Spacer()
                                Image(systemName: "pencil")
                            }
                        }
                        
                        profileRow(icon: "person.fill", title: loc.string(for: .yourName), value: profile.name)
                        profileRow(icon: "phone.fill", title: loc.string(for: .phoneNumber), value: PhoneValidator.format(profile.phone))
                        profileRow(icon: "building.columns.fill", title: loc.string(for: .college), value: profile.college)
                        
                        HStack {
                            Label(loc.string(for: .monthlyBudget), systemImage: "indianrupeesign.circle.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(profile.monthlyBudget.rupeesFullFormatted)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text(loc.string(for: .profile))
                    }
                }
                
                // Preferences
                Section {
                    // Language picker
                    NavigationLink {
                        LanguagePickerView()
                    } label: {
                        HStack {
                            Label(loc.string(for: .language), systemImage: "globe")
                            Spacer()
                            Text(loc.currentLanguage.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Category Manager
                    NavigationLink {
                        CategoryManagerView()
                    } label: {
                        Label(loc.string(for: .manageCategories), systemImage: "folder.fill")
                    }
                } header: {
                    Text(loc.string(for: .preferences))
                }
                
                // Data Management
                Section {
                    // Export
                    // Export CSV
                    Button {
                        let csv = CSVExporter.exportExpenses(allExpenses, language: loc.currentLanguage)
                        if let url = CSVExporter.saveToFile(csv) {
                            csvFileURL = url
                            showExportSheet = true
                        }
                    } label: {
                        Label(loc.string(for: .exportData), systemImage: "doc.text")
                    }
                    
                    // Full Backup Export
                    Button {
                        do {
                            backupURL = try BackupManager.shared.exportData(from: modelContext)
                            showBackupExporter = true
                        } catch {
                            toastMessage = "Backup failed: \(error.localizedDescription)"
                            showToast = true
                        }
                    } label: {
                        Label("Create Full Backup", systemImage: "square.and.arrow.up")
                    }
                    
                    // Full Backup Import
                    Button {
                        showBackupImporter = true
                    } label: {
                        Label("Restore Backup", systemImage: "square.and.arrow.down")
                    }
                    
                    // Expense count
                    HStack {
                        Label("Total Expenses", systemImage: "list.bullet")
                        Spacer()
                        Text("\(allExpenses.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    // Clear Data
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        Label(loc.string(for: .clearData), systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text(loc.string(for: .dataManagement))
                }
                
                // About
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Spacer()
                        Text(loc.string(for: .madeWith))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text(loc.string(for: .about))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(loc.string(for: .settings))
            .alert("Clear All Data?", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will delete all expenses, budgets, and fitness data. This cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = csvFileURL {
                    ShareSheet(items: [url])
                }
            }
            .fileExporter(
                isPresented: $showBackupExporter,
                document: BackupDocument(url: backupURL),
                contentType: .json,
                defaultFilename: "KharchaBackup.json"
            ) { result in
                switch result {
                case .success:
                    toastMessage = "Backup exported successfully! ✅"
                    showToast = true
                    UIImpactFeedbackGenerator.fire(.medium)
                case .failure(let error):
                    toastMessage = "Failed to export: \(error.localizedDescription)"
                    showToast = true
                }
            }
            .fileImporter(
                isPresented: $showBackupImporter,
                allowedContentTypes: [.json, .plainText, .data, .item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    do {
                        try BackupManager.shared.importData(from: url, into: modelContext)
                        toastMessage = "Backup restored successfully! 🎉"
                        showToast = true
                        UIImpactFeedbackGenerator.fire(.heavy)
                    } catch {
                        toastMessage = "Invalid backup file!"
                        showToast = true
                    }
                case .failure(let error):
                    toastMessage = "Failed to import: \(error.localizedDescription)"
                    showToast = true
                }
            }
            .desiToast(isPresented: $showToast, message: toastMessage, icon: "📦")
            .sheet(isPresented: $showEditProfile) {
                if let profile {
                    EditProfileSheet(profile: profile)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    private func profileRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
    
    private func clearAllData() {
        do {
            try modelContext.delete(model: Expense.self)
            try modelContext.delete(model: ExpenseCategory.self)
            try modelContext.delete(model: Budget.self)
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: WaterIntake.self)
            try modelContext.delete(model: Workout.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

// MARK: - Backup Document

import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(url: URL?) {
        if let url, let d = try? Data(contentsOf: url) {
            self.data = d
        } else {
            self.data = Data()
        }
    }
    
    init(configuration: ReadConfiguration) throws {
        if let d = configuration.file.regularFileContents {
            self.data = d
        } else {
            self.data = Data()
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Language Picker

struct LanguagePickerView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @Query private var profiles: [UserProfile]
    
    var body: some View {
        List {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    loc.currentLanguage = language
                    profiles.first?.language = language.rawValue
                    try? modelContext.save()
                    UIImpactFeedbackGenerator.fire(.light)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Text(languagePreview(language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if loc.currentLanguage == language {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accent)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func languagePreview(_ lang: AppLanguage) -> String {
        switch lang {
        case .hinglish: return "\"Aaj ka kharcha: ₹850\""
        case .english: return "\"Today's spending: ₹850\""
        case .hindi: return "\"आज का खर्चा: ₹850\""
        }
    }
}
