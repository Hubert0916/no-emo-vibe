import Foundation

struct DiaryEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var moodScore: Int
    var moodPercentage: Int
    var activities: [String]
    var notes: String
    
    // 預設構造器
    init(date: Date = Date(), moodScore: Int = 0, moodPercentage: Int = 0, activities: [String] = [], notes: String = "") {
        self.date = date
        self.moodScore = moodScore
        self.moodPercentage = moodPercentage
        self.activities = activities
        self.notes = notes
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