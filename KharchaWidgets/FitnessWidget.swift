import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Fitness Timeline Provider

struct FitnessTimelineProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> FitnessWidgetEntry {
        FitnessWidgetEntry(date: Date(), data: WidgetData(todaySteps: 6420, stepGoal: 10000, waterGlasses: 5, waterGoal: 8))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FitnessWidgetEntry) -> Void) {
        let entry = FitnessWidgetEntry(date: Date(), data: loadData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FitnessWidgetEntry>) -> Void) {
        let entry = FitnessWidgetEntry(date: Date(), data: loadData())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadData() -> WidgetData {
        let suite = UserDefaults(suiteName: "group.com.kharchabsdk.app") ?? UserDefaults.standard
        if let data = suite.data(forKey: "kharcha_widget_data"),
           let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) {
            return decoded
        }
        return WidgetData(todaySteps: 6420, stepGoal: 10000, waterGlasses: 5, waterGoal: 8)
    }
}

// MARK: - Fitness Entry

struct FitnessWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Interactive Add Water AppIntent

struct AddWaterGlassIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water Glass"
    static var description: IntentDescription = IntentDescription("Increments your water intake for today by 1 glass.")
    
    func perform() async throws -> some IntentResult {
        let suite = UserDefaults(suiteName: "group.com.kharchabsdk.app") ?? UserDefaults.standard
        var currentData = WidgetData()
        if let data = suite.data(forKey: "kharcha_widget_data"),
           let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) {
            currentData = decoded
        }
        
        if currentData.waterGlasses < currentData.waterGoal {
            currentData.waterGlasses += 1
        }
        if let encoded = try? JSONEncoder().encode(currentData) {
            suite.set(encoded, forKey: "kharcha_widget_data")
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}

// MARK: - Fitness Widget View

struct FitnessWidgetEntryView: View {
    var entry: FitnessTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallFitnessView
        case .systemMedium:
            mediumFitnessView
        default:
            smallFitnessView
        }
    }
    
    // MARK: - Small Fitness View
    
    private var smallFitnessView: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Fitness", systemImage: "heart.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.pink)
                Spacer()
                Text("\(entry.data.todaySteps)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            
            // Steps Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                
                let progress = entry.data.stepGoal > 0 ? Double(entry.data.todaySteps) / Double(entry.data.stepGoal) : 0
                
                Circle()
                    .trim(from: 0, to: max(0, min(1, CGFloat(progress))))
                    .stroke(
                        AngularGradient(colors: [.green, .mint], center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 1) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
            .frame(width: 68, height: 68)
            
            // Water count
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.cyan)
                Text("\(entry.data.waterGlasses)/\(entry.data.waterGoal) glasses")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    // MARK: - Medium Fitness View (With Interactive + Water Button!)
    
    private var mediumFitnessView: some View {
        HStack(spacing: 16) {
            // Steps column
            VStack(alignment: .leading, spacing: 6) {
                Label("Daily Steps", systemImage: "figure.walk")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
                
                Spacer()
                
                Text("\(entry.data.todaySteps)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                
                let progress = entry.data.stepGoal > 0 ? Double(entry.data.todaySteps) / Double(entry.data.stepGoal) : 0
                
                Text("Goal: \(entry.data.stepGoal) (\(Int(progress * 100))%)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Water Column (Interactive)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Water Intake", systemImage: "drop.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan)
                    Spacer()
                    Text("\(entry.data.waterGlasses)/\(entry.data.waterGoal)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                
                // Glasses preview
                HStack(spacing: 3) {
                    ForEach(0..<entry.data.waterGoal, id: \.self) { i in
                        Image(systemName: i < entry.data.waterGlasses ? "cup.and.saucer.fill" : "cup.and.saucer")
                            .font(.system(size: 10))
                            .foregroundStyle(i < entry.data.waterGlasses ? .cyan : Color.gray.opacity(0.3))
                    }
                }
                
                Spacer()
                
                // Interactive Button to add water directly from Widget!
                Button(intent: AddWaterGlassIntent()) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Glass")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.cyan, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Widget Declaration

struct FitnessWidget: Widget {
    let kind: String = "FitnessWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitnessTimelineProvider()) { entry in
            FitnessWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fitness & Water")
        .description("Track your daily steps and log water intake right from your Home Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}
