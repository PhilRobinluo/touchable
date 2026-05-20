import Foundation
import TouchAbleCore

struct DebugEvent: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let detail: String
    let zone: HapticZone?

    init(date: Date = Date(), title: String, detail: String, zone: HapticZone? = nil) {
        self.date = date
        self.title = title
        self.detail = detail
        self.zone = zone
    }

    var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
