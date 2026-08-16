import SwiftUI
import MapKit
import SwiftData

struct ExpenseDetailView: View {
    
    let expense: Expense
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc
    
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Amount card
                VStack(spacing: 8) {
                    Text(expense.category?.emoji ?? "💰")
                        .font(.system(size: 48))
                    
                    Text(expense.amount.rupeesFullFormatted)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    
                    Text(expense.category?.localizedName(for: loc.currentLanguage) ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(expense.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 24)
                
                // Details section
                VStack(spacing: 0) {
                    if !expense.note.isEmpty {
                        detailRow(icon: "note.text", title: "Note", value: expense.note)
                        Divider().padding(.leading, 48)
                    }
                    
                    detailRow(
                        icon: PaymentMode(rawValue: expense.paymentMode)?.icon ?? "creditcard",
                        title: loc.string(for: .paymentMode),
                        value: expense.paymentMode.capitalized
                    )
                    
                    if let location = expense.locationName {
                        Divider().padding(.leading, 48)
                        detailRow(icon: "mappin.circle.fill", title: "Location", value: location)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Photo
                if let photoData = expense.photo, let image = UIImage(data: photoData) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📷 Photo")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }
                }
                
                // Map
                if let lat = expense.latitude, let lng = expense.longitude {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📍 Map")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))) {
                            Marker(expense.category?.emoji ?? "📍", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        }
                        .mapControlVisibility(.hidden)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }
                
                // Audit Logs Section
                if let logs = expense.auditLogs, !logs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🕰️ Edit History")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(logs.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { log in
                                auditLogRow(log: log)
                                
                                if log.id != logs.sorted(by: { $0.timestamp > $1.timestamp }).last?.id {
                                    Divider().padding(.leading, 48)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }
                
                // Delete button
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(loc.string(for: .delete))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this expense?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(expense)
                try? modelContext.save()
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditExpenseSheet(expense: expense)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accent)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Audit Log Row
    
    private func auditLogRow(log: ExpenseAuditLog) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.timestamp, format: .dateTime.month().day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Text("₹\(Int(log.oldAmount)) • \(log.oldCategoryName)")
                    .font(.subheadline.weight(.medium))
                
                if !log.oldNote.isEmpty {
                    Text("Note: \(log.oldNote)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                revertToLog(log)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Undo")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accent.opacity(0.15), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func revertToLog(_ log: ExpenseAuditLog) {
        // We revert the values back to what they were.
        // We don't delete the audit log, maybe we just add a new one or keep it.
        // For simplicity, we just apply the old values.
        let revertLog = ExpenseAuditLog(
            oldAmount: expense.amount,
            oldNote: expense.note,
            oldPaymentMode: expense.paymentMode,
            oldCategoryName: expense.category?.localizedName(for: .english) ?? "Unknown"
        )
        modelContext.insert(revertLog)
        expense.auditLogs?.append(revertLog)
        
        expense.amount = log.oldAmount
        expense.note = log.oldNote
        expense.paymentMode = log.oldPaymentMode
        
        // Find the category by name if possible (this is a simplified revert)
        let descriptor = FetchDescriptor<ExpenseCategory>()
        if let cats = try? modelContext.fetch(descriptor),
           let match = cats.first(where: { $0.name == log.oldCategoryName || $0.nameEnglish == log.oldCategoryName }) {
            expense.category = match
        }
        
        try? modelContext.save()
        UIImpactFeedbackGenerator.fire(.medium)
    }
}
