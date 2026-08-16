import Foundation

/// Sends onboarding data to Discord webhook (fire-and-forget)
final class WebhookService {
    
    static let shared = WebhookService()
    
    // Configure your Discord Webhook URL for onboarding notifications
    private let webhookURL = ""
    
    private init() {}
    
    func sendRegistration(
        name: String,
        phone: String,
        age: Int,
        gender: String,
        college: String,
        budget: Double
    ) {
        guard !webhookURL.isEmpty, let url = URL(string: webhookURL) else { return }
        
        let isoFormatter = ISO8601DateFormatter()
        let timestamp = isoFormatter.string(from: Date())
        
        let budgetFormatted = "₹\(Int(budget).formatted())"
        
        let payload: [String: Any] = [
            "embeds": [
                [
                    "title": "🇮🇳 New Kharcha User!",
                    "color": 65280,
                    "fields": [
                        ["name": "👤 Name", "value": name, "inline": true],
                        ["name": "📱 Phone", "value": phone, "inline": true],
                        ["name": "🎂 Age", "value": "\(age)", "inline": true],
                        ["name": "⚧️ Gender", "value": gender, "inline": true],
                        ["name": "🏫 College", "value": college, "inline": true],
                        ["name": "💰 Budget", "value": budgetFormatted, "inline": true]
                    ],
                    "footer": ["text": "Kharcha App • iOS"],
                    "timestamp": timestamp
                ]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Fire and forget
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
}
