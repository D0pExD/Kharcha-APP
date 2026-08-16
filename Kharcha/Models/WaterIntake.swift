import Foundation
import SwiftData

@Model
final class WaterIntake {
    var date: String       // "2026-08-16"
    var glasses: Int
    var goal: Int
    
    init(date: String = "", glasses: Int = 0, goal: Int = 8) {
        self.date = date.isEmpty ? Self.todayKey() : date
        self.glasses = glasses
        self.goal = goal
    }
    
    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

@Model
final class Workout {
    var type: String          // "Push-ups", "Running", "Squats"
    var value: Double         // 30 reps, 2.5 km
    var unit: String          // "reps", "km", "min"
    var date: Date
    
    init(type: String, value: Double, unit: String = "reps") {
        self.type = type
        self.value = value
        self.unit = unit
        self.date = Date()
    }
    
    var displayValue: String {
        if value == Double(Int(value)) {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }
}
