import Foundation
import SwiftUI

// MARK: - Date Helpers

extension Date {
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components)!
    }
    
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
    }
    
    var monthYearKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: self)
    }
    
    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var daysRemainingInMonth: Int {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: self)!
        let currentDay = cal.component(.day, from: self)
        return range.count - currentDay
    }
    
    func relativeHeader(language: AppLanguage) -> String {
        if isToday {
            switch language {
            case .hinglish: return "Aaj"
            case .english: return "Today"
            case .hindi: return "आज"
            }
        }
        if isYesterday {
            switch language {
            case .hinglish: return "Kal"
            case .english: return "Yesterday"
            case .hindi: return "कल"
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, EEEE"
        return formatter.string(from: self)
    }
}

// MARK: - Currency Formatting

extension Double {
    
    var rupeesFormatted: String {
        if self >= 100000 {
            return "₹\(String(format: "%.1fL", self / 100000))"
        }
        if self >= 1000 {
            return "₹\(String(format: "%.1fk", self / 1000))"
        }
        if self == Double(Int(self)) {
            return "₹\(Int(self))"
        }
        return "₹\(String(format: "%.0f", self))"
    }
    
    var rupeesFullFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "₹\(formatted)"
    }
}

// MARK: - Color from Hex

extension Color {
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Colors

extension Color {
    static let accent = Color(hex: "#00C853")
    static let saffron = Color(hex: "#FF6D00")
    static let appPurple = Color(hex: "#7C4DFF")
    static let cardBackground = Color(.secondarySystemGroupedBackground)
}

// MARK: - Haptics

extension UIImpactFeedbackGenerator {
    static func fire(_ style: FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
