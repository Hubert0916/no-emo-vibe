import Foundation
import SwiftUI

class DiaryManager: ObservableObject {
    @Published var entries: [DiaryEntry] = []
    
    // UserDefaults 儲存鍵
    private let entriesKey = "diaryEntries"
    
    init() {
        loadEntries()
    }
    
    // 從 UserDefaults 加載日記條目
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey) {
            do {
                let decoder = JSONDecoder()
                let entries = try decoder.decode([DiaryEntry].self, from: data)
                self.entries = entries.sorted(by: { $0.date > $1.date }) // 按日期排序（最新的優先）
            } catch {
                print("無法解碼日記條目: \(error)")
            }
        }
    }
    
    // 保存日記條目到 UserDefaults
    private func saveEntries() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(entries)
            UserDefaults.standard.set(data, forKey: entriesKey)
        } catch {
            print("無法編碼日記條目: \(error)")
        }
    }
    
    // 添加新日記條目
    func addEntry(_ entry: DiaryEntry) {
        entries.append(entry)
        entries.sort(by: { $0.date > $1.date }) // 保持按日期排序
        saveEntries()
    }
    
    // 更新已有日記條目
    func updateEntry(_ entry: DiaryEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }
    
    // 刪除日記條目
    func deleteEntry(_ entry: DiaryEntry) {
        entries.removeAll(where: { $0.id == entry.id })
        saveEntries()
    }
    
    // 根據日期獲取條目
    func getEntryForDate(_ date: Date) -> DiaryEntry? {
        let calendar = Calendar.current
        return entries.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
    }
    
    // 檢查特定日期是否有條目
    func hasEntryForDate(_ date: Date) -> Bool {
        return getEntryForDate(date) != nil
    }
    
    // 獲取今天的條目，如果不存在則創建一個新的
    func getOrCreateTodayEntry() -> DiaryEntry {
        if let todayEntry = getEntryForDate(Date()) {
            return todayEntry
        } else {
            let newEntry = DiaryEntry(date: Date())
            return newEntry
        }
    }
} 