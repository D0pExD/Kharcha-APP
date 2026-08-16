import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    // Core Metrics
    var todaySteps: Int = 0
    var activeCalories: Double = 0 // kcal
    var distanceKm: Double = 0 // km
    var exerciseMinutes: Int = 0 // mins
    var flightsClimbed: Int = 0
    var restingHeartRate: Double = 0 // BPM
    var sleepHours: Double = 0 // hours
    
    var weeklySteps: [DailySteps] = []
    var stepGoal: Int = 8000
    var calorieGoal: Double = 500
    var isAuthorized = false
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.flightsClimbed),
            HKQuantityType(.restingHeartRate),
            HKCategoryType(.sleepAnalysis)
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run { isAuthorized = true }
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Refresh All Data
    
    func refreshAll() async {
        guard isAvailable else { return }
        async let steps = fetchQuantity(.stepCount, unit: .count())
        async let calories = fetchQuantity(.activeEnergyBurned, unit: .kilocalorie())
        async let distance = fetchQuantity(.distanceWalkingRunning, unit: .meter())
        async let exercise = fetchQuantity(.appleExerciseTime, unit: .minute())
        async let flights = fetchQuantity(.flightsClimbed, unit: .count())
        async let heartRate = fetchLatestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let sleep = fetchSleepDuration()
        
        let (s, c, d, e, f, hr, slp) = await (steps, calories, distance, exercise, flights, heartRate, sleep)
        
        await MainActor.run {
            self.todaySteps = Int(s)
            self.activeCalories = c
            self.distanceKm = d / 1000.0 // meters to km
            self.exerciseMinutes = Int(e)
            self.flightsClimbed = Int(f)
            self.restingHeartRate = hr
            self.sleepHours = slp
        }
        
        await fetchWeeklySteps()
    }
    
    // MARK: - Generic Cumulative Sum Fetcher
    
    private func fetchQuantity(_ type: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let quantityType = HKQuantityType(type)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let val = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: val)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Latest Sample (e.g. Heart Rate)
    
    private func fetchLatestQuantity(_ type: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let quantityType = HKQuantityType(type)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Sleep Duration
    
    private func fetchSleepDuration() async -> Double {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let now = Date()
        let calendar = Calendar.current
        guard let yesterdayNoon = calendar.date(byAdding: .hour, value: -20, to: now) else { return 0 }
        
        let predicate = HKQuery.predicateForSamples(withStart: yesterdayNoon, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                var totalSeconds: TimeInterval = 0
                for sample in sleepSamples {
                    if sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                continuation.resume(returning: totalSeconds / 3600.0) // Seconds to hours
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Weekly Steps
    
    func fetchWeeklySteps() async {
        let stepType = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        
        let daily = await withCheckedContinuation { (continuation: CheckedContinuation<[DailySteps], Never>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, _ in
                var stepsArray: [DailySteps] = []
                results?.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                    let count = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    stepsArray.append(DailySteps(date: statistics.startDate, steps: Int(count)))
                }
                continuation.resume(returning: stepsArray)
            }
            healthStore.execute(query)
        }
        
        await MainActor.run {
            self.weeklySteps = daily
        }
    }
    
    var stepProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return min(Double(todaySteps) / Double(stepGoal), 1.0)
    }
}

// MARK: - Daily Steps Data

struct DailySteps: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
