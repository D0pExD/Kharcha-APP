import Foundation
import SwiftData

final class CSVExporter {
    
    static func exportExpenses(_ expenses: [Expense], language: AppLanguage = .hinglish) -> String {
        var csv = "Date,Time,Amount (₹),Category,Note,Payment Mode,Location,Latitude,Longitude\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for expense in expenses.sorted(by: { $0.createdAt > $1.createdAt }) {
            let date = dateFormatter.string(from: expense.createdAt)
            let time = timeFormatter.string(from: expense.createdAt)
            let amount = String(format: "%.2f", expense.amount)
            let category = expense.category?.localizedName(for: language) ?? "Uncategorized"
            let note = expense.note.replacingOccurrences(of: ",", with: ";")
            let paymentMode = expense.paymentMode.capitalized
            let location = (expense.locationName ?? "").replacingOccurrences(of: ",", with: ";")
            let lat = expense.latitude.map { String(format: "%.6f", $0) } ?? ""
            let lng = expense.longitude.map { String(format: "%.6f", $0) } ?? ""
            
            csv += "\(date),\(time),\(amount),\(category),\(note),\(paymentMode),\(location),\(lat),\(lng)\n"
        }
        
        return csv
    }
    
    static func saveToFile(_ csv: String, filename: String = "kharcha_export") -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(filename)_\(formattedDate()).csv")
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
    
    private static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter.string(from: Date())
    }
}
