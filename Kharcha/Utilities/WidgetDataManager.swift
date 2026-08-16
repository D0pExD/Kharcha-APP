import Foundation
import WidgetKit

struct WidgetData: Codable {
    var todaySpend: Double = 0
    var monthlyBudgetLeft: Double = 10000
    var monthlyBudgetTotal: Double = 10000
    var todaySteps: Int = 0
    var stepGoal: Int = 10000
    var waterGlasses: Int = 0
    var waterGoal: Int = 8
    var currencySymbol: String = "₹"
    var lastUpdated: Date = Date()
}

final class WidgetDataManager {
    
    static let shared = WidgetDataManager()
    static let suiteName = "group.com.kharchabsdk.app"
    
    private var suiteDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetDataManager.suiteName)
    }
    
    private init() {}
    
    func save(data: WidgetData) {
        if let encoded = try? JSONEncoder().encode(data) {
            suiteDefaults?.set(encoded, forKey: "kharcha_widget_data")
            UserDefaults.standard.set(encoded, forKey: "kharcha_widget_data")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func load() -> WidgetData {
        let rawData = suiteDefaults?.data(forKey: "kharcha_widget_data") ?? UserDefaults.standard.data(forKey: "kharcha_widget_data")
        if let rawData, let decoded = try? JSONDecoder().decode(WidgetData.self, from: rawData) {
            return decoded
        }
        return WidgetData()
    }
    
    func update(todaySpend: Double, budgetLeft: Double, budgetTotal: Double, steps: Int = 0, waterGlasses: Int = 0) {
        var current = load()
        current.todaySpend = todaySpend
        current.monthlyBudgetLeft = budgetLeft
        current.monthlyBudgetTotal = budgetTotal
        if steps > 0 { current.todaySteps = steps }
        current.waterGlasses = waterGlasses
        current.lastUpdated = Date()
        save(data: current)
    }
}
