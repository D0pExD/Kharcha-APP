import Foundation
import SwiftUI

// MARK: - Language Enum

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case hinglish = "hinglish"
    case english = "english"
    case hindi = "hindi"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .hinglish: return "Hinglish"
        case .english: return "English"
        case .hindi: return "हिंदी"
        }
    }
}

// MARK: - Localization Keys

enum LocalizedKey: String {
    // Tabs
    case tabHome, tabBudget, tabAdd, tabSchedule, tabProfile
    
    // Greetings
    case greetingMorning, greetingAfternoon, greetingEvening, greetingNight
    
    // Dashboard
    case thisMonth, todaySpend, weekSpend, avgDaily, recentExpenses
    case categoryBreakdown, budgetLeft
    
    // Quick Add
    case newExpense, amountPlaceholder, notePlaceholder
    case selectCategory, paymentMode, addPhoto, autoLocation
    case saveButton, cancelButton
    
    // Budget
    case budgetInsights, spent, budget, remaining
    case dailyTrend, topCategories, topLocations, exportCSV
    
    // History
    case expenseHistory, searchPlaceholder, filterAll
    case today, yesterday
    
    // Fitness
    case fitness, steps, waterIntake, workout, sleep
    case addGlass, logWorkout, stepGoal
    
    // Settings
    case settings, profile, preferences, language
    case manageCategories, dataManagement
    case exportData, importData, clearData
    case about, madeWith
    
    // Onboarding
    case welcome, getStarted, next, letsGo
    case yourName, phoneNumber, age, gender, college
    case monthlyBudget, languagePref
    
    // Categories
    case categories, addCategory, editCategory, deleteCategory
    
    // Empty states
    case emptyExpenses, emptyFitness, emptySchedule
    
    // Misc
    case delete, edit, done, save, cancel
}

// MARK: - Localization Manager

@Observable
final class LocalizationManager {
    
    static let shared = LocalizationManager()
    
    var currentLanguage: AppLanguage = .hinglish {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"), let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        }
    }
    
    func string(for key: LocalizedKey) -> String {
        strings[key]?[currentLanguage] ?? strings[key]?[.english] ?? key.rawValue
    }
    
    func greeting(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let key: LocalizedKey
        
        switch hour {
        case 5..<12: key = .greetingMorning
        case 12..<17: key = .greetingAfternoon
        case 17..<21: key = .greetingEvening
        default: key = .greetingNight
        }
        
        let template = string(for: key)
        return template.replacingOccurrences(of: "{name}", with: name)
    }
    
    // MARK: - String Table
    
    private let strings: [LocalizedKey: [AppLanguage: String]] = [
        // Tabs
        .tabHome: [
            .hinglish: "Ghar",
            .english: "Home",
            .hindi: "होम"
        ],
        .tabBudget: [
            .hinglish: "Budget",
            .english: "Budget",
            .hindi: "बजट"
        ],
        .tabAdd: [
            .hinglish: "Jodo",
            .english: "Add",
            .hindi: "जोड़ें"
        ],
        .tabSchedule: [
            .hinglish: "Schedule",
            .english: "Schedule",
            .hindi: "समय-सारणी"
        ],
        .tabProfile: [
            .hinglish: "Profile",
            .english: "Profile",
            .hindi: "प्रोफ़ाइल"
        ],
        
        // Greetings
        .greetingMorning: [
            .hinglish: "Subah subah, {name}! ☀️",
            .english: "Good morning, {name}! ☀️",
            .hindi: "सुप्रभात, {name}! ☀️"
        ],
        .greetingAfternoon: [
            .hinglish: "Kya haal hai, {name}! 👋",
            .english: "Good afternoon, {name}! 👋",
            .hindi: "नमस्ते, {name}! 👋"
        ],
        .greetingEvening: [
            .hinglish: "Kya scene hai, {name}! 🌇",
            .english: "Good evening, {name}! 🌇",
            .hindi: "शुभ संध्या, {name}! 🌇"
        ],
        .greetingNight: [
            .hinglish: "Abhi jaag raha hai, {name}? 🌙",
            .english: "Still up, {name}? 🌙",
            .hindi: "अभी जाग रहे हो, {name}? 🌙"
        ],
        
        // Dashboard
        .thisMonth: [
            .hinglish: "Is Mahine",
            .english: "This Month",
            .hindi: "इस महीने"
        ],
        .todaySpend: [
            .hinglish: "Aaj",
            .english: "Today",
            .hindi: "आज"
        ],
        .weekSpend: [
            .hinglish: "Hafta",
            .english: "Week",
            .hindi: "हफ़्ता"
        ],
        .avgDaily: [
            .hinglish: "Avg",
            .english: "Avg",
            .hindi: "औसत"
        ],
        .recentExpenses: [
            .hinglish: "Haal ke Kharche",
            .english: "Recent Expenses",
            .hindi: "हाल के खर्चे"
        ],
        .categoryBreakdown: [
            .hinglish: "Category Breakdown",
            .english: "Category Breakdown",
            .hindi: "श्रेणी विवरण"
        ],
        .budgetLeft: [
            .hinglish: "Bacha hai",
            .english: "Remaining",
            .hindi: "बचा है"
        ],
        
        // Quick Add
        .newExpense: [
            .hinglish: "Naya Kharcha",
            .english: "New Expense",
            .hindi: "नया खर्चा"
        ],
        .amountPlaceholder: [
            .hinglish: "Kitna laga?",
            .english: "Amount",
            .hindi: "कितना लगा?"
        ],
        .notePlaceholder: [
            .hinglish: "Kuch likho... (optional)",
            .english: "Add a note... (optional)",
            .hindi: "कुछ लिखो... (वैकल्पिक)"
        ],
        .selectCategory: [
            .hinglish: "Category Chuno",
            .english: "Select Category",
            .hindi: "श्रेणी चुनें"
        ],
        .paymentMode: [
            .hinglish: "Payment Mode",
            .english: "Payment Mode",
            .hindi: "भुगतान माध्यम"
        ],
        .addPhoto: [
            .hinglish: "Photo Add Karo",
            .english: "Add Photo",
            .hindi: "फ़ोटो जोड़ें"
        ],
        .autoLocation: [
            .hinglish: "Auto Location",
            .english: "Auto Location",
            .hindi: "स्वचालित लोकेशन"
        ],
        .saveButton: [
            .hinglish: "Save Karo",
            .english: "Save",
            .hindi: "सेव करें"
        ],
        .cancelButton: [
            .hinglish: "Chodo",
            .english: "Cancel",
            .hindi: "रद्द करें"
        ],
        
        // Budget
        .budgetInsights: [
            .hinglish: "Budget & Insights",
            .english: "Budget & Insights",
            .hindi: "बजट और जानकारी"
        ],
        .spent: [
            .hinglish: "Kharch",
            .english: "Spent",
            .hindi: "खर्च"
        ],
        .budget: [
            .hinglish: "Budget",
            .english: "Budget",
            .hindi: "बजट"
        ],
        .remaining: [
            .hinglish: "Bacha",
            .english: "Remaining",
            .hindi: "बचा"
        ],
        .dailyTrend: [
            .hinglish: "Daily Kharcha Trend",
            .english: "Daily Spending Trend",
            .hindi: "दैनिक खर्चा ट्रेंड"
        ],
        .topCategories: [
            .hinglish: "Top Categories",
            .english: "Top Categories",
            .hindi: "शीर्ष श्रेणियाँ"
        ],
        .topLocations: [
            .hinglish: "Top Locations",
            .english: "Top Locations",
            .hindi: "शीर्ष स्थान"
        ],
        .exportCSV: [
            .hinglish: "Export CSV",
            .english: "Export CSV",
            .hindi: "CSV निर्यात"
        ],
        
        // History
        .expenseHistory: [
            .hinglish: "Kharcha History",
            .english: "Expense History",
            .hindi: "खर्चा इतिहास"
        ],
        .searchPlaceholder: [
            .hinglish: "Dhoondo...",
            .english: "Search...",
            .hindi: "खोजें..."
        ],
        .filterAll: [
            .hinglish: "Sab",
            .english: "All",
            .hindi: "सब"
        ],
        .today: [
            .hinglish: "Aaj",
            .english: "Today",
            .hindi: "आज"
        ],
        .yesterday: [
            .hinglish: "Kal",
            .english: "Yesterday",
            .hindi: "कल"
        ],
        
        // Fitness
        .fitness: [
            .hinglish: "Fitness",
            .english: "Fitness",
            .hindi: "फ़िटनेस"
        ],
        .steps: [
            .hinglish: "Kadam",
            .english: "Steps",
            .hindi: "कदम"
        ],
        .waterIntake: [
            .hinglish: "Paani",
            .english: "Water Intake",
            .hindi: "पानी"
        ],
        .workout: [
            .hinglish: "Workout",
            .english: "Workout",
            .hindi: "व्यायाम"
        ],
        .sleep: [
            .hinglish: "Neend",
            .english: "Sleep",
            .hindi: "नींद"
        ],
        .addGlass: [
            .hinglish: "+ Glass",
            .english: "+ Glass",
            .hindi: "+ गिलास"
        ],
        .logWorkout: [
            .hinglish: "Workout Log Karo",
            .english: "Log Workout",
            .hindi: "व्यायाम लॉग करें"
        ],
        .stepGoal: [
            .hinglish: "ka goal",
            .english: "goal",
            .hindi: "का लक्ष्य"
        ],
        
        // Settings
        .settings: [
            .hinglish: "Settings",
            .english: "Settings",
            .hindi: "सेटिंग्स"
        ],
        .profile: [
            .hinglish: "Profile",
            .english: "Profile",
            .hindi: "प्रोफ़ाइल"
        ],
        .preferences: [
            .hinglish: "Preferences",
            .english: "Preferences",
            .hindi: "प्राथमिकताएँ"
        ],
        .language: [
            .hinglish: "Bhaasha",
            .english: "Language",
            .hindi: "भाषा"
        ],
        .manageCategories: [
            .hinglish: "Categories Manage Karo",
            .english: "Manage Categories",
            .hindi: "श्रेणियाँ प्रबंधित करें"
        ],
        .dataManagement: [
            .hinglish: "Data Management",
            .english: "Data Management",
            .hindi: "डेटा प्रबंधन"
        ],
        .exportData: [
            .hinglish: "Export Data",
            .english: "Export Data",
            .hindi: "डेटा निर्यात"
        ],
        .importData: [
            .hinglish: "Import Data",
            .english: "Import Data",
            .hindi: "डेटा आयात"
        ],
        .clearData: [
            .hinglish: "Sab Delete Karo",
            .english: "Clear All Data",
            .hindi: "सब डेटा हटाएँ"
        ],
        .about: [
            .hinglish: "About",
            .english: "About",
            .hindi: "जानकारी"
        ],
        .madeWith: [
            .hinglish: "Made with ❤️ aur chai",
            .english: "Made with ❤️ and chai",
            .hindi: "❤️ और चाय से बना"
        ],
        
        // Onboarding
        .welcome: [
            .hinglish: "Kharcha mein aapka swagat hai!",
            .english: "Welcome to Kharcha!",
            .hindi: "खर्चा में आपका स्वागत है!"
        ],
        .getStarted: [
            .hinglish: "Chalo Shuru Karte Hain!",
            .english: "Get Started!",
            .hindi: "चलो शुरू करते हैं!"
        ],
        .next: [
            .hinglish: "Aage Badho",
            .english: "Next",
            .hindi: "आगे बढ़ें"
        ],
        .letsGo: [
            .hinglish: "Shuru Karte Hain! 🚀",
            .english: "Let's Go! 🚀",
            .hindi: "शुरू करते हैं! 🚀"
        ],
        .yourName: [
            .hinglish: "Apna naam bata",
            .english: "Your Name",
            .hindi: "अपना नाम बताएँ"
        ],
        .phoneNumber: [
            .hinglish: "Phone Number",
            .english: "Phone Number",
            .hindi: "फ़ोन नंबर"
        ],
        .age: [
            .hinglish: "Umar",
            .english: "Age",
            .hindi: "उम्र"
        ],
        .gender: [
            .hinglish: "Gender",
            .english: "Gender",
            .hindi: "लिंग"
        ],
        .college: [
            .hinglish: "College / University",
            .english: "College / University",
            .hindi: "कॉलेज / विश्वविद्यालय"
        ],
        .monthlyBudget: [
            .hinglish: "Monthly Budget",
            .english: "Monthly Budget",
            .hindi: "मासिक बजट"
        ],
        .languagePref: [
            .hinglish: "Bhaasha Chuno",
            .english: "Choose Language",
            .hindi: "भाषा चुनें"
        ],
        
        // Categories
        .categories: [
            .hinglish: "Categories",
            .english: "Categories",
            .hindi: "श्रेणियाँ"
        ],
        .addCategory: [
            .hinglish: "Nayi Category",
            .english: "Add Category",
            .hindi: "नई श्रेणी"
        ],
        .editCategory: [
            .hinglish: "Edit Karo",
            .english: "Edit",
            .hindi: "संपादित करें"
        ],
        .deleteCategory: [
            .hinglish: "Delete Karo",
            .english: "Delete",
            .hindi: "हटाएँ"
        ],
        
        // Empty states
        .emptyExpenses: [
            .hinglish: "Abhi tak koi kharcha nahi?\nKya upwaas hai? 🕉️",
            .english: "No expenses yet.\nStart tracking! 📝",
            .hindi: "अभी तक कोई खर्चा नहीं?\nक्या उपवास है? 🕉️"
        ],
        .emptyFitness: [
            .hinglish: "Body banani hai ya nahi?\nStart kar! 💪",
            .english: "No fitness data yet.\nGet moving! 💪",
            .hindi: "बॉडी बनानी है या नहीं?\nशुरू करो! 💪"
        ],
        .emptySchedule: [
            .hinglish: "Bina schedule ke kaise chalega?\nAdd kar!",
            .english: "No classes yet.\nAdd your schedule!",
            .hindi: "बिना शेड्यूल के कैसे चलेगा?\nजोड़ो!"
        ],
        
        // Misc
        .delete: [
            .hinglish: "Delete",
            .english: "Delete",
            .hindi: "हटाएँ"
        ],
        .edit: [
            .hinglish: "Edit",
            .english: "Edit",
            .hindi: "बदलें"
        ],
        .done: [
            .hinglish: "Done",
            .english: "Done",
            .hindi: "हो गया"
        ],
        .save: [
            .hinglish: "Save",
            .english: "Save",
            .hindi: "सेव"
        ],
        .cancel: [
            .hinglish: "Cancel",
            .english: "Cancel",
            .hindi: "रद्द"
        ],
    ]
}
