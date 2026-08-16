import SwiftUI
import SwiftData
import PhotosUI
import WidgetKit

struct QuickAddSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc
    
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    @State private var amountText = ""
    @State private var note = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var paymentMode: PaymentMode = .upi
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoImage: UIImage?
    
    @State private var showPhotoMenu = false
    @State private var showCamera = false
    
    @State private var showCategoryManager = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    private var locationManager = LocationManager.shared
    
    private var amount: Double? {
        Double(amountText.filter { $0.isNumber || $0 == "." })
    }
    
    private var isValid: Bool {
        guard let amount, amount > 0 else { return false }
        return selectedCategory != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount Input
                    amountSection
                    
                    // Note
                    noteSection
                    
                    // Category Grid
                    categorySection
                    
                    // Payment Mode
                    paymentSection
                    
                    // Extras (Photo + Location)
                    extrasSection
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(loc.string(for: .newExpense))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.string(for: .cancelButton)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc.string(for: .saveButton)) {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .tint(Color.accent)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showCategoryManager) {
                NavigationStack {
                    CategoryManagerView()
                }
            }
            .onAppear {
                locationManager.fetchCurrentLocation()
            }
        }
    }
    
    // MARK: - Amount Section
    
    private var amountSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accent)
                
                TextField("0", text: $amountText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Quick amount pills
            HStack(spacing: 8) {
                ForEach([50, 100, 200, 500, 1000], id: \.self) { val in
                    Button {
                        amountText = "\(val)"
                        UIImpactFeedbackGenerator.fire(.light)
                    } label: {
                        Text("₹\(val)")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                amountText == "\(val)" ? Color.accent.opacity(0.2) : Color(.tertiarySystemGroupedBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(amountText == "\(val)" ? Color.accent : .secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Note Section
    
    private var noteSection: some View {
        TextField(loc.string(for: .notePlaceholder), text: $note, axis: .vertical)
            .lineLimit(1...3)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
    }
    
    // MARK: - Category Grid
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(loc.string(for: .selectCategory))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    showCategoryManager = true
                } label: {
                    Label(loc.string(for: .edit), systemImage: "pencil")
                        .font(.caption)
                        .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(categories) { category in
                    categoryCell(category)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func categoryCell(_ category: ExpenseCategory) -> some View {
        let isSelected = selectedCategory?.persistentModelID == category.persistentModelID
        
        return Button {
            selectedCategory = category
            UIImpactFeedbackGenerator.fire(.light)
        } label: {
            VStack(spacing: 4) {
                Text(category.emoji)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(
                        isSelected ? Color(hex: category.colorHex).opacity(0.25) : Color(.tertiarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: category.colorHex) : Color.clear, lineWidth: 2)
                    )
                
                Text(category.localizedName(for: loc.currentLanguage))
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Payment Section
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.string(for: .paymentMode))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: 8) {
                ForEach(PaymentMode.allCases) { mode in
                    let isSelected = paymentMode == mode
                    
                    Button {
                        paymentMode = mode
                        UIImpactFeedbackGenerator.fire(.light)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.caption)
                            Text(mode.displayName)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            isSelected ? Color.accent : Color(.tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Extras Section (Photo + Location)
    
    private var extrasSection: some View {
        VStack(spacing: 12) {
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
                    // Compress image if from camera to save space
                    photoData = newImage.jpegData(compressionQuality: 0.7)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(selectedImage: $photoImage)
                    .ignoresSafeArea()
            }
            
            // Photo preview
            if let photoImage {
                Image(uiImage: photoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            self.photoImage = nil
                            self.photoData = nil
                            self.selectedPhotoItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        .padding(8)
                    }
                    .padding(.horizontal)
            }
            
            // Location
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color.accent)
                Text(loc.string(for: .autoLocation))
                    .font(.subheadline)
                
                Spacer()
                
                if locationManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let name = locationManager.currentLocationName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Save
    
    private func saveExpense() {
        guard let amount, amount > 0, let category = selectedCategory else { return }
        
        let expense = Expense(
            amount: amount,
            note: note.trimmingCharacters(in: .whitespaces),
            paymentMode: paymentMode.rawValue,
            photo: photoData,
            latitude: locationManager.currentLatitude,
            longitude: locationManager.currentLongitude,
            locationName: locationManager.currentLocationName,
            category: category
        )
        
        modelContext.insert(expense)
        try? modelContext.save()
        
        // Reload Widgets
        var widgetData = WidgetDataManager.shared.load()
        widgetData.todaySpend += amount
        widgetData.monthlyBudgetLeft -= amount
        WidgetDataManager.shared.save(data: widgetData)
        
        UIImpactFeedbackGenerator.fire(.heavy)
        locationManager.clearLocation()
        dismiss()
    }
}
