import Foundation

struct DiaryEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var moodScore: Int
    var moodPercentage: Int
    var activities: [String]
    var notes: String
    
    // 網路同步相關屬性
    var isUploaded: Bool = false
    var lastSyncDate: Date?
    
    // 預設構造器
    init(date: Date = Date(), moodScore: Int = 0, moodPercentage: Int = 0, activities: [String] = [], notes: String = "", isUploaded: Bool = false, lastSyncDate: Date? = nil) {
        self.date = date
        self.moodScore = moodScore
        self.moodPercentage = moodPercentage
        self.activities = activities
        self.notes = notes
        self.isUploaded = isUploaded
        self.lastSyncDate = lastSyncDate
    }
    
    // 根據心情分數返回相應描述
    var moodDescription: String {
        let average = Double(moodScore) / 5.0 // 假設總共5個問題
        switch average {
        case 0..<1.5:
            return "需要關愛"
        case 1.5..<2.5:
            return "平靜修復"
        case 2.5..<3.5:
            return "穩定平衡"
        case 3.5..<4.5:
            return "積極向上"
        default:
            return "光芒四射"
        }
    }
}

// 新增：自定義 CodingKeys 與解碼邏輯
extension DiaryEntry {
    enum CodingKeys: String, CodingKey {
        case id = "entry_uuid"
        case date = "entry_date"
        case moodScore = "mood_score"
        case moodPercentage = "mood_percentage"
        case activities
        case notes
        case isUploaded
        case lastSyncDate
    }

    // 自訂解碼，處理 null 與遺漏欄位
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // entry_uuid -> UUID；若失敗則生成新 UUID 以免整體解碼失敗
        if let uuidString = try? container.decode(String.self, forKey: .id), let uuid = UUID(uuidString: uuidString) {
            self.id = uuid
        } else {
            self.id = UUID()
        }

        // 日期：嘗試 ISO8601 或常見格式
        let dateString = try container.decode(String.self, forKey: .date)
        if let parsedDate = ISO8601DateFormatter().date(from: dateString) {
            self.date = parsedDate
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            self.date = formatter.date(from: dateString) ?? Date()
        }

        self.moodScore = try container.decodeIfPresent(Int.self, forKey: .moodScore) ?? 0
        self.moodPercentage = try container.decodeIfPresent(Int.self, forKey: .moodPercentage) ?? 0
        self.activities = try container.decodeIfPresent([String].self, forKey: .activities) ?? []
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.isUploaded = try container.decodeIfPresent(Bool.self, forKey: .isUploaded) ?? true
        self.lastSyncDate = try container.decodeIfPresent(Date.self, forKey: .lastSyncDate)
    }

    // 自訂編碼，將屬性映射回後端欄位
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        try container.encode(formatter.string(from: date), forKey: .date)
        try container.encode(moodScore, forKey: .moodScore)
        try container.encode(moodPercentage, forKey: .moodPercentage)
        try container.encode(activities, forKey: .activities)
        try container.encode(notes, forKey: .notes)
    }
} 