import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider

struct ExpenseTimelineProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> ExpenseWidgetEntry {
        ExpenseWidgetEntry(date: Date(), data: WidgetData(todaySpend: 450, monthlyBudgetLeft: 6800, monthlyBudgetTotal: 10000))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ExpenseWidgetEntry) -> Void) {
        let entry = ExpenseWidgetEntry(date: Date(), data: loadData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpenseWidgetEntry>) -> Void) {
        let entry = ExpenseWidgetEntry(date: Date(), data: loadData())
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
        return WidgetData()
    }
}

// MARK: - Entry

struct ExpenseWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Widget View

struct ExpenseWidgetEntryView: View {
    var entry: ExpenseTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .accessoryCircular:
            circularLockScreenView
        case .accessoryInline:
            inlineLockScreenView
        case .accessoryRectangular:
            rectangularLockScreenView
        default:
            smallWidgetView
        }
    }
    
    // MARK: - Small Widget
    
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("💸 Kharcha")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Spend")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text("₹\(Int(entry.data.todaySpend))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // Budget Left Progress
            VStack(alignment: .leading, spacing: 4) {
                let ratio = entry.data.monthlyBudgetTotal > 0 ? (entry.data.monthlyBudgetLeft / entry.data.monthlyBudgetTotal) : 0
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(ratio < 0.2 ? Color.red : Color.green)
                            .frame(width: geo.size.width * max(0, min(1, CGFloat(ratio))), height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("₹\(Int(entry.data.monthlyBudgetLeft)) left")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    // MARK: - Medium Widget
    
    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            // Left Column: Today's Spend
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("💸 Kharcha")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                Spacer()
                
                Text("Today's Kharcha")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("₹\(Int(entry.data.todaySpend))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("Updated just now")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Right Column: Monthly Budget Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Budget")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("₹\(Int(entry.data.monthlyBudgetLeft))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.data.monthlyBudgetLeft < 1000 ? .red : .green)
                    Text("left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                let ratio = entry.data.monthlyBudgetTotal > 0 ? (entry.data.monthlyBudgetLeft / entry.data.monthlyBudgetTotal) : 0
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(ratio < 0.2 ? Color.red : Color.green)
                            .frame(width: geo.size.width * max(0, min(1, CGFloat(ratio))), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("Total: ₹\(Int(entry.data.monthlyBudgetTotal))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(ratio * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    // MARK: - Lock Screen Accessories
    
    private var circularLockScreenView: some View {
        ZStack {
            let ratio = entry.data.monthlyBudgetTotal > 0 ? (entry.data.monthlyBudgetLeft / entry.data.monthlyBudgetTotal) : 0
            
            AccessoryWidgetBackground()
            
            VStack(spacing: 1) {
                Text("₹\(Int(entry.data.todaySpend))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text("spent")
                    .font(.system(size: 8))
            }
        }
    }
    
    private var inlineLockScreenView: some View {
        Text("₹\(Int(entry.data.todaySpend)) spent today • ₹\(Int(entry.data.monthlyBudgetLeft)) left")
    }
    
    private var rectangularLockScreenView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: "indianrupeesign.circle.fill")
                Text("Kharcha Today")
                    .font(.caption.weight(.bold))
            }
            Text("₹\(Int(entry.data.todaySpend)) spent • ₹\(Int(entry.data.monthlyBudgetLeft)) budget left")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Declaration

struct ExpenseWidget: Widget {
    let kind: String = "ExpenseWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExpenseTimelineProvider()) { entry in
            ExpenseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Kharcha Tracker")
        .description("Track today's spend and monthly budget balance right from your Home Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}
