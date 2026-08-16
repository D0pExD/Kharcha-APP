import Foundation
import SwiftData

@Model
final class ClassSchedule {
    var subject: String
    var room: String
    var professor: String
    var dayOfWeek: Int          // 1=Mon ... 7=Sun
    var startTime: Date
    var endTime: Date
    var colorHex: String
    
    init(
        subject: String,
        room: String = "",
        professor: String = "",
        dayOfWeek: Int = 1,
        startTime: Date = Date(),
        endTime: Date = Date(),
        colorHex: String = "#2196F3"
    ) {
        self.subject = subject
        self.room = room
        self.professor = professor
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.colorHex = colorHex
    }
    
    var dayName: String {
        let days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        guard dayOfWeek >= 1 && dayOfWeek <= 7 else { return "" }
        return days[dayOfWeek]
    }
}

@Model
final class Assignment {
    var title: String
    var subject: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: String       // "high", "medium", "low"
    
    init(
        title: String,
        subject: String = "",
        dueDate: Date = Date(),
        isCompleted: Bool = false,
        priority: String = "medium"
    ) {
        self.title = title
        self.subject = subject
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    var isOverdue: Bool {
        daysRemaining < 0 && !isCompleted
    }
}
