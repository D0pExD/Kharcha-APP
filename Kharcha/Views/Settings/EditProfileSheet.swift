import SwiftUI
import SwiftData

struct EditProfileSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let profile: UserProfile
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var age: Int = 18
    @State private var gender: String = ""
    @State private var college: String = ""
    @State private var monthlyBudget: Double = 10000
    @State private var budgetText: String = ""
    
    private let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    Stepper("Age: \(age)", value: $age, in: 13...99)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { g in
                            Text(g).tag(g)
                        }
                    }
                }
                
                Section("College & Budget") {
                    TextField("College / University", text: $college)
                        .textContentType(.organizationName)
                    
                    HStack {
                        Text("₹")
                        TextField("Monthly Budget", text: $budgetText)
                            .keyboardType(.numberPad)
                            .onChange(of: budgetText) { _, newValue in
                                if let val = Double(newValue.filter { $0.isNumber }) {
                                    monthlyBudget = val
                                }
                            }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                name = profile.name
                phone = profile.phone
                age = profile.age
                gender = profile.gender
                college = profile.college
                monthlyBudget = profile.monthlyBudget
                budgetText = "\(Int(profile.monthlyBudget))"
            }
        }
    }
    
    private func saveProfile() {
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.phone = PhoneValidator.rawNumber(phone)
        profile.age = age
        profile.gender = gender
        profile.college = college.trimmingCharacters(in: .whitespaces)
        
        let oldBudget = profile.monthlyBudget
        profile.monthlyBudget = monthlyBudget
        
        // Find current month budget and update it if the base budget changed
        if oldBudget != monthlyBudget {
            let monthKey = Budget.currentMonthKey()
            let descriptor = FetchDescriptor<Budget>(predicate: #Predicate { $0.month == monthKey })
            if let currentBudgets = try? modelContext.fetch(descriptor), let current = currentBudgets.first {
                current.totalBudget = monthlyBudget
            }
        }
        
        try? modelContext.save()
        UIImpactFeedbackGenerator.fire(.medium)
        dismiss()
    }
}
