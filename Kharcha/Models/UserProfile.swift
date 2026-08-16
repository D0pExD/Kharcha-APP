import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var phone: String
    var age: Int
    var gender: String
    var college: String
    var monthlyBudget: Double
    var language: String       // "hinglish", "english", "hindi"
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    
    init(
        name: String = "",
        phone: String = "",
        age: Int = 18,
        gender: String = "",
        college: String = "",
        monthlyBudget: Double = 10000,
        language: String = "hinglish",
        hasCompletedOnboarding: Bool = false
    ) {
        self.name = name
        self.phone = phone
        self.age = age
        self.gender = gender
        self.college = college
        self.monthlyBudget = monthlyBudget
        self.language = language
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = Date()
    }
}
