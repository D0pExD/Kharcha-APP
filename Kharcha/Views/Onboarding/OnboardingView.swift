import SwiftUI
import SwiftData

struct OnboardingView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    
    @State private var currentStep = 0
    @State private var name = ""
    @State private var phone = ""
    @State private var age = 18
    @State private var gender = ""
    @State private var college = ""
    @State private var monthlyBudget: Double = 10000
    @State private var selectedLanguage: AppLanguage = .hinglish
    
    @State private var showPhoneError = false
    @State private var isCompleting = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                if currentStep > 0 {
                    HStack(spacing: 8) {
                        ForEach(1...2, id: \.self) { step in
                            Capsule()
                                .fill(step <= currentStep ? Color.accent : Color.gray.opacity(0.3))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                TabView(selection: $currentStep) {
                    WelcomeStep(onStart: { withAnimation { currentStep = 1 } })
                        .tag(0)
                    
                    PersonalInfoStep(
                        name: $name,
                        phone: $phone,
                        age: $age,
                        gender: $gender,
                        showPhoneError: $showPhoneError,
                        onNext: validateAndProceed
                    )
                    .tag(1)
                    
                    CollegeStep(
                        college: $college,
                        monthlyBudget: $monthlyBudget,
                        selectedLanguage: $selectedLanguage,
                        isCompleting: $isCompleting,
                        onComplete: completeOnboarding
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .interactiveDismissDisabled()
    }
    
    // MARK: - Validation
    
    private func validateAndProceed() {
        let rawPhone = PhoneValidator.rawNumber(phone)
        
        if !PhoneValidator.isValid(rawPhone) {
            showPhoneError = true
            UIImpactFeedbackGenerator.fire(.heavy)
            return
        }
        
        showPhoneError = false
        withAnimation { currentStep = 2 }
    }
    
    // MARK: - Complete Onboarding
    
    private func completeOnboarding() {
        isCompleting = true
        UIImpactFeedbackGenerator.fire(.heavy)
        
        // Update localization
        loc.currentLanguage = selectedLanguage
        
        // Create user profile
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            phone: PhoneValidator.rawNumber(phone),
            age: age,
            gender: gender,
            college: college.trimmingCharacters(in: .whitespaces),
            monthlyBudget: monthlyBudget,
            language: selectedLanguage.rawValue,
            hasCompletedOnboarding: true
        )
        modelContext.insert(profile)
        
        // Create initial budget
        let budget = Budget(
            month: Budget.currentMonthKey(),
            totalBudget: monthlyBudget
        )
        modelContext.insert(budget)
        
        // Seed default categories
        ExpenseCategory.seedDefaults(in: modelContext)
        
        try? modelContext.save()
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    let onStart: () -> Void
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon area
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accent.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(animate ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
                
                VStack(spacing: 4) {
                    Text("💰")
                        .font(.system(size: 80))
                    
                    Text("KHARCHA")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color.accent)
                }
            }
            
            VStack(spacing: 12) {
                Text("Tera paisa, teri marzi,\ntera data")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    featurePill(icon: "bolt.fill", text: "Fast")
                    featurePill(icon: "lock.fill", text: "Private")
                    featurePill(icon: "wifi.slash", text: "Offline")
                }
                .padding(.top, 8)
            }
            
            Spacer()
            
            Button(action: onStart) {
                Text("Chalo Shuru Karte Hain! 🚀")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear { animate = true }
    }
    
    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Personal Info Step

struct PersonalInfoStep: View {
    
    @Binding var name: String
    @Binding var phone: String
    @Binding var age: Int
    @Binding var gender: String
    @Binding var showPhoneError: Bool
    let onNext: () -> Void
    
    private let genders = ["Male", "Female", "Other"]
    
    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2 &&
        phone.filter({ $0.isNumber }).count >= 10 &&
        !gender.isEmpty &&
        age >= 13 && age <= 99
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Apne baare mein bata 👋")
                    .font(.title.bold())
                    .padding(.top, 24)
                
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Label("Naam", systemImage: "person.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("Apna naam likh", text: $name)
                        .textContentType(.name)
                        .font(.body)
                        .padding(14)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Phone
                VStack(alignment: .leading, spacing: 8) {
                    Label("Phone Number", systemImage: "phone.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("+91")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        
                        TextField("98765 43210", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .font(.body)
                            .padding(14)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showPhoneError ? Color.red : Color.clear, lineWidth: 1.5)
                            )
                    }
                    
                    if showPhoneError {
                        Text("Valid Indian number daal bhai (10 digits, 6-9 se start)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                // Age
                VStack(alignment: .leading, spacing: 8) {
                    Label("Umar", systemImage: "calendar")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    Stepper("\(age) years", value: $age, in: 13...99)
                        .padding(14)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Gender
                VStack(alignment: .leading, spacing: 8) {
                    Label("Gender", systemImage: "person.2.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 10) {
                        ForEach(genders, id: \.self) { g in
                            Button {
                                gender = g
                                UIImpactFeedbackGenerator.fire(.light)
                            } label: {
                                Text(g)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        gender == g ? Color.accent : Color(.tertiarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 12)
                                    )
                                    .foregroundStyle(gender == g ? .white : .primary)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                // Next button
                Button(action: onNext) {
                    Text("Aage Badho →")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isValid ? Color.accent : Color.gray.opacity(0.4),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .disabled(!isValid)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - College Step

struct CollegeStep: View {
    
    @Binding var college: String
    @Binding var monthlyBudget: Double
    @Binding var selectedLanguage: AppLanguage
    @Binding var isCompleting: Bool
    let onComplete: () -> Void
    
    @State private var budgetText = "10000"
    
    private var isValid: Bool {
        college.trimmingCharacters(in: .whitespaces).count >= 3
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Thoda aur bata 🏫")
                    .font(.title.bold())
                    .padding(.top, 24)
                
                // College
                VStack(alignment: .leading, spacing: 8) {
                    Label("College / University", systemImage: "building.columns.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("IIT Delhi, BITS Pilani...", text: $college)
                        .textContentType(.organizationName)
                        .font(.body)
                        .padding(14)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Monthly Budget
                VStack(alignment: .leading, spacing: 8) {
                    Label("Monthly Budget (optional)", systemImage: "indianrupeesign.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("₹")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.accent)
                        
                        TextField("10000", text: $budgetText)
                            .keyboardType(.numberPad)
                            .font(.title3.weight(.medium))
                            .padding(14)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            .onChange(of: budgetText) { _, newValue in
                                if let val = Double(newValue.filter({ $0.isNumber })) {
                                    monthlyBudget = val
                                }
                            }
                    }
                    
                    // Quick presets
                    HStack(spacing: 8) {
                        ForEach([5000, 10000, 15000, 20000], id: \.self) { amount in
                            Button {
                                budgetText = "\(amount)"
                                monthlyBudget = Double(amount)
                                UIImpactFeedbackGenerator.fire(.light)
                            } label: {
                                Text("₹\(amount / 1000)k")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        monthlyBudget == Double(amount) ? Color.accent.opacity(0.2) : Color(.tertiarySystemGroupedBackground),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(monthlyBudget == Double(amount) ? Color.accent : .secondary)
                            }
                        }
                    }
                }
                
                // Language Preference
                VStack(alignment: .leading, spacing: 12) {
                    Label("Bhaasha Chuno", systemImage: "globe")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            selectedLanguage = lang
                            UIImpactFeedbackGenerator.fire(.light)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lang.displayName)
                                        .font(.body.weight(.medium))
                                    
                                    Text(languageDescription(lang))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: selectedLanguage == lang ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedLanguage == lang ? Color.accent : .secondary)
                                    .font(.title3)
                            }
                            .padding(14)
                            .background(
                                selectedLanguage == lang ? Color.accent.opacity(0.1) : Color(.tertiarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(.primary)
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                // Complete button
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        if isCompleting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Shuru Karte Hain! 🚀")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isValid ? Color.accent : Color.gray.opacity(0.4),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .disabled(!isValid || isCompleting)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private func languageDescription(_ lang: AppLanguage) -> String {
        switch lang {
        case .hinglish: return "Mixed Hindi-English — \"Aaj ka kharcha: ₹850\""
        case .english: return "Pure English — \"Today's spending: ₹850\""
        case .hindi: return "शुद्ध हिंदी — \"आज का खर्चा: ₹850\""
        }
    }
}
