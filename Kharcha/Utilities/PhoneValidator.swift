import Foundation

struct PhoneValidator {
    
    /// Validates Indian phone number format
    /// Must be +91 followed by 10 digits starting with 6-9
    static func isValid(_ phone: String) -> Bool {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        // Pattern: +91 followed by 10 digits starting with 6,7,8,9
        let pattern = #"^\+91[6-9]\d{9}$"#
        
        return cleaned.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// Formats phone number to +91 XXXXX XXXXX
    static func format(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        
        let relevantDigits: String
        if digits.hasPrefix("91") && digits.count >= 12 {
            relevantDigits = String(digits.suffix(10))
        } else {
            relevantDigits = String(digits.suffix(10))
        }
        
        guard relevantDigits.count == 10 else {
            return phone
        }
        
        let first5 = relevantDigits.prefix(5)
        let last5 = relevantDigits.suffix(5)
        
        return "+91 \(first5) \(last5)"
    }
    
    /// Strips formatting to get raw +91XXXXXXXXXX
    static func rawNumber(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        if digits.hasPrefix("91") && digits.count == 12 {
            return "+\(digits)"
        }
        if digits.count == 10 {
            return "+91\(digits)"
        }
        return phone
    }
}
