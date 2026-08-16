import SwiftUI
import SwiftData
import Charts
import WidgetKit

struct FitnessView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    
    @State private var healthKit = HealthKitManager.shared
    @State private var showAddWorkout = false
    
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query private var waterEntries: [WaterIntake]
    
    private var todayWater: WaterIntake? {
        waterEntries.first(where: { $0.date == WaterIntake.todayKey() })
    }
    
    private var todayWorkouts: [Workout] {
        workouts.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Step & Activity Ring Hero Card
                    activityHeroCard
                    
                    // Apple Health Metrics Grid (Calories, Distance, Heart Rate, Sleep)
                    healthMetricsGrid
                    
                    // Weekly Steps Chart
                    if !healthKit.weeklySteps.isEmpty {
                        weeklyStepsChart
                    }
                    
                    // Water Tracker
                    waterTrackerCard
                    
                    // Today's Workouts
                    workoutSection
                }
                .padding(.bottom, 100)
            }
            .navigationTitle(loc.string(for: .fitness))
            .task {
                syncWaterWithWidget()
                if healthKit.isAvailable {
                    let authorized = await healthKit.requestAuthorization()
                    if authorized {
                        await healthKit.refreshAll()
                        pushToWidget()
                    }
                }
            }
            .refreshable {
                await healthKit.refreshAll()
                pushToWidget()
            }
            .sheet(isPresented: $showAddWorkout) {
                AddWorkoutSheet()
            }
        }
    }
    
    // MARK: - Activity Hero Card
    
    private var activityHeroCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label(loc.string(for: .steps), systemImage: "figure.walk")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    Text("Apple Health")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }
            
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 18)
                    .frame(width: 160, height: 160)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: healthKit.stepProgress)
                    .stroke(
                        AngularGradient(
                            colors: [.green, .mint, Color.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 160, height: 160)
                    .animation(.spring(duration: 1), value: healthKit.stepProgress)
                
                VStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.title3)
                        .foregroundStyle(.green)
                    
                    Text("\(healthKit.todaySteps)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    
                    Text("\(healthKit.stepGoal) \(loc.string(for: .stepGoal))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Motivation message
            Text(DesiMessages.fitnessMotivation(
                steps: healthKit.todaySteps,
                goal: healthKit.stepGoal,
                language: loc.currentLanguage
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // MARK: - Apple Health Metrics Grid
    
    private var healthMetricsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apple Health Stats 🍎")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Active Calories
                HealthStatCard(
                    title: "Active Calories",
                    value: "\(Int(healthKit.activeCalories)) kcal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                // Distance
                HealthStatCard(
                    title: "Walking Distance",
                    value: String(format: "%.2f km", healthKit.distanceKm),
                    icon: "figure.walk.motion",
                    color: .blue
                )
                
                // Exercise Time
                HealthStatCard(
                    title: "Exercise Time",
                    value: "\(healthKit.exerciseMinutes) mins",
                    icon: "timer",
                    color: .green
                )
                
                // Resting Heart Rate
                HealthStatCard(
                    title: "Resting Heart Rate",
                    value: healthKit.restingHeartRate > 0 ? "\(Int(healthKit.restingHeartRate)) BPM" : "— BPM",
                    icon: "heart.fill",
                    color: .pink
                )
                
                // Sleep
                HealthStatCard(
                    title: "Sleep Duration",
                    value: healthKit.sleepHours > 0 ? String(format: "%.1f hrs", healthKit.sleepHours) : "— hrs",
                    icon: "bed.double.fill",
                    color: .indigo
                )
                
                // Flights Climbed
                HealthStatCard(
                    title: "Flights Climbed",
                    value: "\(healthKit.flightsClimbed) floors",
                    icon: "stairs",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Weekly Steps Chart
    
    private var weeklyStepsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Steps Trend 📊")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(healthKit.weeklySteps) { day in
                BarMark(
                    x: .value("Day", day.dayLabel),
                    y: .value("Steps", day.steps)
                )
                .foregroundStyle(
                    day.date.isToday ?
                    Color.accent.gradient :
                    Color.accent.opacity(0.4).gradient
                )
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let val = value.as(Int.self) {
                            Text("\(val / 1000)k")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // MARK: - Water Tracker
    
    private var waterTrackerCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label(loc.string(for: .waterIntake), systemImage: "drop.fill")
                    .font(.headline)
                    .foregroundStyle(.cyan)
                
                Spacer()
                
                Text("\(todayWater?.glasses ?? 0) / \(todayWater?.goal ?? 8)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            
            let glasses = todayWater?.glasses ?? 0
            let goal = todayWater?.goal ?? 8
            
            HStack(spacing: 6) {
                ForEach(0..<goal, id: \.self) { index in
                    Image(systemName: index < glasses ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .font(.title2)
                        .foregroundStyle(index < glasses ? .cyan : Color(.tertiaryLabel))
                        .scaleEffect(index < glasses ? 1.0 : 0.85)
                        .animation(.spring, value: glasses)
                }
            }
            
            Button {
                addGlass()
                UIImpactFeedbackGenerator.fire(.light)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text(loc.string(for: .addGlass))
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.cyan, in: Capsule())
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    private func addGlass() {
        let key = WaterIntake.todayKey()
        if let existing = waterEntries.first(where: { $0.date == key }) {
            if existing.glasses < existing.goal {
                existing.glasses += 1
            }
        } else {
            let entry = WaterIntake(date: key, glasses: 1, goal: 8)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        pushToWidget()
    }
    
    private func syncWaterWithWidget() {
        let key = WaterIntake.todayKey()
        let widgetData = WidgetDataManager.shared.load()
        if let existing = waterEntries.first(where: { $0.date == key }) {
            if widgetData.waterGlasses > existing.glasses {
                existing.glasses = widgetData.waterGlasses
                try? modelContext.save()
            }
        } else if widgetData.waterGlasses > 0 {
            let entry = WaterIntake(date: key, glasses: widgetData.waterGlasses, goal: 8)
            modelContext.insert(entry)
            try? modelContext.save()
        }
    }
    
    private func pushToWidget() {
        var current = WidgetDataManager.shared.load()
        current.todaySteps = healthKit.todaySteps
        current.stepGoal = healthKit.stepGoal
        current.waterGlasses = todayWater?.glasses ?? 0
        current.waterGoal = todayWater?.goal ?? 8
        WidgetDataManager.shared.save(data: current)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Workout Section
    
    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(loc.string(for: .workout), systemImage: "dumbbell.fill")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showAddWorkout = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal)
            
            if todayWorkouts.isEmpty {
                EmptyStateView(
                    emoji: "🏋️",
                    message: loc.string(for: .emptyFitness),
                    actionTitle: loc.string(for: .logWorkout),
                    action: { showAddWorkout = true }
                )
            } else {
                ForEach(todayWorkouts) { workout in
                    HStack(spacing: 12) {
                        Image(systemName: workoutIcon(workout.type))
                            .font(.title3)
                            .foregroundStyle(Color.accent)
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.type)
                                .font(.subheadline.weight(.medium))
                            Text(workout.displayValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    private func workoutIcon(_ type: String) -> String {
        let lower = type.lowercased()
        if lower.contains("run") { return "figure.run" }
        if lower.contains("walk") { return "figure.walk" }
        if lower.contains("push") { return "figure.strengthtraining.traditional" }
        if lower.contains("squat") { return "figure.cooldown" }
        if lower.contains("yoga") { return "figure.yoga" }
        if lower.contains("cycl") || lower.contains("bike") { return "figure.outdoor.cycle" }
        if lower.contains("swim") { return "figure.pool.swim" }
        return "figure.strengthtraining.functional"
    }
}

// MARK: - Health Stat Card

struct HealthStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Add Workout Sheet

struct AddWorkoutSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var type = ""
    @State private var value = ""
    @State private var unit = "reps"
    
    private let workoutPresets = [
        ("Push-ups", "reps"), ("Squats", "reps"), ("Running", "km"),
        ("Pull-ups", "reps"), ("Plank", "min"), ("Cycling", "km"),
        ("Sit-ups", "reps"), ("Yoga", "min"), ("Walking", "km"),
        ("Jumping Jacks", "reps"), ("Swimming", "min"), ("Stretching", "min")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Pick") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(workoutPresets, id: \.0) { preset in
                            Button {
                                type = preset.0
                                unit = preset.1
                                UIImpactFeedbackGenerator.fire(.light)
                            } label: {
                                Text(preset.0)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        type == preset.0 ? Color.accent.opacity(0.2) : Color(.tertiarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                    .foregroundStyle(type == preset.0 ? Color.accent : .primary)
                            }
                        }
                    }
                }
                
                Section("Details") {
                    TextField("Exercise", text: $type)
                    
                    HStack {
                        TextField("Value", text: $value)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $unit) {
                            Text("reps").tag("reps")
                            Text("km").tag("km")
                            Text("min").tag("min")
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let val = Double(value), !type.isEmpty {
                            let workout = Workout(type: type, value: val, unit: unit)
                            modelContext.insert(workout)
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(type.isEmpty || value.isEmpty)
                }
            }
        }
    }
}
