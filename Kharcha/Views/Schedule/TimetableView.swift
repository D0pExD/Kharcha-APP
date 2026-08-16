import SwiftUI
import SwiftData

struct TimetableView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \ClassSchedule.startTime) private var classes: [ClassSchedule]
    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]
    
    @State private var selectedDay: Int = {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Convert Sunday=1 to Monday=1 system
        return weekday == 1 ? 7 : weekday - 1
    }()
    @State private var showAddClass = false
    @State private var showAddAssignment = false
    
    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    private var todayClasses: [ClassSchedule] {
        classes.filter { $0.dayOfWeek == selectedDay }
    }
    
    private var upcomingAssignments: [Assignment] {
        assignments.filter { !$0.isCompleted && $0.dueDate >= Date() }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Day selector
                daySelector
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Classes
                        if todayClasses.isEmpty {
                            EmptyStateView(
                                emoji: "📚",
                                message: loc.string(for: .emptySchedule),
                                actionTitle: "Add Class",
                                action: { showAddClass = true }
                            )
                        } else {
                            classTimeline
                        }
                        
                        // Upcoming Assignments
                        if !upcomingAssignments.isEmpty {
                            assignmentSection
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(loc.string(for: .tabSchedule))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddClass = true
                        } label: {
                            Label("Add Class", systemImage: "book.fill")
                        }
                        
                        Button {
                            showAddAssignment = true
                        } label: {
                            Label("Add Assignment", systemImage: "doc.text.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddClass) {
                AddClassSheet()
            }
            .sheet(isPresented: $showAddAssignment) {
                AddAssignmentSheet()
            }
        }
    }
    
    // MARK: - Day Selector
    
    private var daySelector: some View {
        HStack(spacing: 4) {
            ForEach(1...7, id: \.self) { day in
                let isSelected = selectedDay == day
                let hasClasses = classes.contains(where: { $0.dayOfWeek == day })
                
                Button {
                    selectedDay = day
                    UIImpactFeedbackGenerator.fire(.light)
                } label: {
                    VStack(spacing: 4) {
                        Text(dayNames[day - 1])
                            .font(.caption.weight(.medium))
                        
                        if hasClasses {
                            Circle()
                                .fill(Color.accent)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        isSelected ? Color.accent : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .foregroundStyle(isSelected ? .white : .primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Class Timeline
    
    private var classTimeline: some View {
        VStack(spacing: 0) {
            ForEach(todayClasses) { classItem in
                HStack(alignment: .top, spacing: 12) {
                    // Time
                    VStack {
                        Text(classItem.startTime, format: .dateTime.hour().minute())
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 50)
                    
                    // Line
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color(hex: classItem.colorHex))
                            .frame(width: 10, height: 10)
                        
                        Rectangle()
                            .fill(Color(hex: classItem.colorHex).opacity(0.3))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                    
                    // Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(classItem.subject)
                            .font(.subheadline.weight(.semibold))
                        
                        if !classItem.room.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                Text(classItem.room)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        if !classItem.professor.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "person")
                                Text(classItem.professor)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: classItem.colorHex).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                }
                .frame(minHeight: 80)
                .padding(.horizontal)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(classItem)
                        try? modelContext.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - Assignments
    
    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ Upcoming Deadlines")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(upcomingAssignments) { assignment in
                HStack(spacing: 10) {
                    Button {
                        assignment.isCompleted.toggle()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(assignment.isCompleted ? .green : .secondary)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(assignment.title)
                            .font(.subheadline.weight(.medium))
                            .strikethrough(assignment.isCompleted)
                        
                        HStack(spacing: 6) {
                            if !assignment.subject.isEmpty {
                                Text(assignment.subject)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("\(assignment.daysRemaining) days left")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(assignment.daysRemaining <= 2 ? .red : .orange)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}

// MARK: - Add Class Sheet

struct AddClassSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var subject = ""
    @State private var room = ""
    @State private var professor = ""
    @State private var dayOfWeek = 1
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedColor = "#2196F3"
    
    private let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private let colorOptions = ["#2196F3", "#4CAF50", "#FF6D00", "#E91E63", "#9C27B0", "#00BCD4", "#FF9800", "#795548"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Subject", text: $subject)
                    TextField("Room (optional)", text: $room)
                    TextField("Professor (optional)", text: $professor)
                }
                
                Section("Schedule") {
                    Picker("Day", selection: $dayOfWeek) {
                        ForEach(1...7, id: \.self) { day in
                            Text(dayNames[day - 1]).tag(day)
                        }
                    }
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(.white, lineWidth: selectedColor == color ? 2.5 : 0)
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                }
            }
            .navigationTitle("Add Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let classItem = ClassSchedule(
                            subject: subject,
                            room: room,
                            professor: professor,
                            dayOfWeek: dayOfWeek,
                            startTime: startTime,
                            endTime: endTime,
                            colorHex: selectedColor
                        )
                        modelContext.insert(classItem)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(subject.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Assignment Sheet

struct AddAssignmentSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var subject = ""
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 3600) // 1 week
    @State private var priority = "medium"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Assignment Title", text: $title)
                    TextField("Subject (optional)", text: $subject)
                }
                
                Section("Deadline") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Priority", selection: $priority) {
                        Text("🟢 Low").tag("low")
                        Text("🟡 Medium").tag("medium")
                        Text("🔴 High").tag("high")
                    }
                }
            }
            .navigationTitle("Add Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let assignment = Assignment(
                            title: title, subject: subject,
                            dueDate: dueDate, priority: priority
                        )
                        modelContext.insert(assignment)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
