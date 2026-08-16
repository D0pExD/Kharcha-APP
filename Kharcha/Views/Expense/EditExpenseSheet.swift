import SwiftUI
import SwiftData
import PhotosUI
import WidgetKit

struct EditExpenseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc
    
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    let expense: Expense
    
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var paymentMode: PaymentMode = .upi
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoImage: UIImage?
    
    @State private var showPhotoMenu = false
    @State private var showCamera = false
    @State private var showToast = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        amountSection
                        categorySection
                        extrasSection
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(loc.string(for: .cancel)) {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.headline)
                    .foregroundStyle(Color.accent)
                    .disabled(amountText.isEmpty || selectedCategory == nil)
                }
            }
            .onAppear {
                setupInitialData()
            }
            .desiToast(isPresented: $showToast, message: "Updated successfully!", icon: "💸")
        }
    }
    
    private func setupInitialData() {
        amountText = "\(Int(expense.amount))"
        note = expense.note
        selectedCategory = expense.category
        if let pMode = PaymentMode(rawValue: expense.paymentMode) {
            paymentMode = pMode
        }
        if let pData = expense.photo {
            photoData = pData
            photoImage = UIImage(data: pData)
        }
    }
    
    // MARK: - Amount Section
    
    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("₹")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.accent)
            
            TextField("0", text: $amountText)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .onChange(of: amountText) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        amountText = filtered
                    }
                }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.string(for: .selectCategory))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(categories) { cat in
                    categoryCell(cat)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func categoryCell(_ category: ExpenseCategory) -> some View {
        let isSelected = selectedCategory?.id == category.id
        
        return Button {
            selectedCategory = category
            UIImpactFeedbackGenerator.fire(.light)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex).opacity(isSelected ? 1 : 0.1))
                        .frame(width: 50, height: 50)
                    
                    Text(category.emoji)
                        .font(.title2)
                }
                
                Text(category.localizedName(for: loc.currentLanguage))
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Extras
    
    private var extrasSection: some View {
        VStack(spacing: 12) {
            // Note
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
                TextField(loc.string(for: .notePlaceholder), text: $note)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            // Photo button
            HStack {
                Button {
                    showPhotoMenu = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(Color.accent)
                        Text(loc.string(for: .addPhoto))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if photoImage != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primary)
            }
            .padding(.horizontal)
            .confirmationDialog("Choose Photo Source", isPresented: $showPhotoMenu, titleVisibility: .hidden) {
                Button("Take Photo") {
                    showCamera = true
                }
                PhotosPicker("Choose from Library", selection: $selectedPhotoItem, matching: .images)
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                        photoImage = UIImage(data: data)
                    }
                }
            }
            .onChange(of: photoImage) { _, newImage in
                if let newImage {
                    photoData = newImage.jpegData(compressionQuality: 0.7)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(selectedImage: $photoImage)
                    .ignoresSafeArea()
            }
            
            if let photoImage {
                Image(uiImage: photoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            self.photoImage = nil
                            self.photoData = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white, .black.opacity(0.6))
                                .padding(8)
                        }
                    }
            }
            
            // Payment Mode
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PaymentMode.allCases, id: \.self) { mode in
                        Button {
                            paymentMode = mode
                            UIImpactFeedbackGenerator.fire(.light)
                        } label: {
                            HStack {
                                Image(systemName: paymentModeIcon(mode))
                                Text(mode.rawValue.capitalized)
                            }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                paymentMode == mode ? Color.accent : Color(.secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(paymentMode == mode ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 4)
        }
    }
    
    private func paymentModeIcon(_ mode: PaymentMode) -> String {
        switch mode {
        case .upi: return "qrcode.viewfinder"
        case .cash: return "banknote"
        case .card: return "creditcard"
        case .online: return "globe"
        }
    }
    
    // MARK: - Save Action
    
    private func saveChanges() {
        guard let amount = Double(amountText), let category = selectedCategory else { return }
        
        let oldCategoryName = expense.category?.localizedName(for: .english) ?? "Unknown"
        
        // Create Audit Log
        let log = ExpenseAuditLog(
            oldAmount: expense.amount,
            oldNote: expense.note,
            oldPaymentMode: expense.paymentMode,
            oldCategoryName: oldCategoryName
        )
        
        modelContext.insert(log)
        
        if expense.auditLogs == nil {
            expense.auditLogs = []
        }
        expense.auditLogs?.append(log)
        
        // Update Expense
        expense.amount = amount
        expense.category = category
        expense.note = note
        expense.paymentMode = paymentMode.rawValue
        expense.photo = photoData
        
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        
        showToast = true
        UIImpactFeedbackGenerator.fire(.medium)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}
