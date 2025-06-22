import Foundation
import SwiftUI

class DiaryManager: ObservableObject {
    @Published var entries: [DiaryEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSyncing = false
    
    // UserDefaults 儲存鍵
    private let entriesKey = "diaryEntries"
    private let networkManager = NetworkManager.shared
    
    init() {
        loadEntries()
        // 啟動時註冊裝置並同步資料
        Task {
            await initializeSync()
        }
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
    
    // 保存日記條目到 UserDefaults（公開方法）
    func saveEntries() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(entries)
            UserDefaults.standard.set(data, forKey: entriesKey)
        } catch {
            print("無法編碼日記條目: \(error)")
        }
    }
    
    // MARK: - 初始化和同步
    
    @MainActor
    private func initializeSync() async {
        do {
            isLoading = true
            errorMessage = nil
            
            // 1. 註冊裝置
            _ = try await networkManager.registerDevice()
            print("✅ 裝置註冊成功")
            
            // 2. 執行完整雙向同步
            await retrySyncAll()
            
        } catch {
            errorMessage = "初始化失敗: \(error.localizedDescription)"
            print("❌ 初始化錯誤: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func syncFromServer() async {
        do {
            isSyncing = true
            print("🔄 開始從服務器同步...")
            print("📋 同步邏輯:")
            print("   • 本地有，遠端沒有 → 上傳本地到遠端")
            print("   • 本地有，遠端也有 → 以本地覆蓋遠端")
            print("   • 本地沒有，遠端有 → 下載到本地")
            
            let serverEntries = try await networkManager.fetchDiaryEntries()
            print("📥 從服務器獲取 \(serverEntries.count) 筆日記")
            
            // 執行智能同步邏輯
            await performIntelligentSync(serverEntries: serverEntries)
            
            print("✅ 同步完成")
            
        } catch {
            errorMessage = "同步失敗: \(error.localizedDescription)"
            print("❌ 同步錯誤: \(error)")
        }
        
        isSyncing = false
    }
    
    @MainActor
    private func performIntelligentSync(serverEntries: [DiaryEntry]) async {
        let calendar = Calendar.current
        
        // 按日期分組本地和服務器條目
        let localEntriesByDate = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        
        let serverEntriesByDate = Dictionary(grouping: serverEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        
        // 獲取所有涉及的日期
        let allDates = Set(localEntriesByDate.keys).union(Set(serverEntriesByDate.keys))
        
        var updatedEntries: [DiaryEntry] = []
        
        for date in allDates {
            let localEntry = localEntriesByDate[date]?.first
            let serverEntry = serverEntriesByDate[date]?.first
            
            switch (localEntry, serverEntry) {
            case (let local?, nil):
                // 本地有，遠端沒有 → 上傳本地到遠端
                print("📤 上傳本地日記到遠端 \(date)")
                await uploadEntryToServer(local)
                updatedEntries.append(local)
                
            case (let local?, let server?):
                // 本地有，遠端也有 → 以本地覆蓋遠端
                print("📤 以本地覆蓋遠端 \(date)")
                await uploadEntryToServer(local)
                updatedEntries.append(local)
                
            case (nil, let server?):
                // 本地沒有，遠端有 → 下載到本地
                print("📥 下載遠端日記到本地 \(date)")
                var downloadedEntry = server
                downloadedEntry.isUploaded = true
                downloadedEntry.lastSyncDate = Date()
                updatedEntries.append(downloadedEntry)
                
            case (nil, nil):
                // 不可能的情況
                break
            }
        }
        
        // 更新本地條目列表
        entries = updatedEntries.sorted(by: { $0.date > $1.date })
        saveEntries()
        
        print("📊 同步結果: 本地保留 \(entries.count) 筆日記")
    }
    
    @MainActor
    private func uploadEntryToServer(_ entry: DiaryEntry) async {
        do {
            _ = try await networkManager.uploadDiaryEntry(entry)
            
            // 更新本地狀態
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index].isUploaded = true
                entries[index].lastSyncDate = Date()
            }
            
            print("✅ 上傳成功: \(entry.date)")
            
        } catch {
            print("❌ 上傳失敗: \(entry.date) - \(error)")
            // 上傳失敗不影響同步邏輯，保持本地條目
        }
    }
    
    // MARK: - CRUD 操作 (支援 API 同步)
    
    // 添加新日記條目（確保同一天只有一個）
    func addEntry(_ entry: DiaryEntry) {
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: entry.date)
        
        // 檢查是否已有同一天的日記
        if let existingIndex = entries.firstIndex(where: { 
            calendar.isDate($0.date, inSameDayAs: entry.date) 
        }) {
            // 替換現有的同一天日記
            print("📝 替換同一天的日記: \(entryDate)")
            var newEntry = entry
            newEntry.isUploaded = false
            entries[existingIndex] = newEntry
        } else {
            // 添加新日記
            print("➕ 添加新日記: \(entryDate)")
            var newEntry = entry
            newEntry.isUploaded = false
            entries.append(newEntry)
        }
        
        entries.sort(by: { $0.date > $1.date })
        saveEntries()
        
        // 背景上傳到服務器
        Task {
            await uploadEntry(entry)
        }
    }
    
    // 更新已有日記條目
    func updateEntry(_ entry: DiaryEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updatedEntry = entry
            updatedEntry.isUploaded = false // 標記為需要重新上傳
            entries[index] = updatedEntry
            saveEntries()
            
            // 背景上傳（統一使用上傳而非更新）
            Task {
                await uploadEntry(updatedEntry)
            }
        }
    }
    
    // 刪除日記條目 (暫時只從本地刪除)
    func deleteEntry(_ entry: DiaryEntry) {
        entries.removeAll(where: { $0.id == entry.id })
        saveEntries()
        // 注意: API 目前不支援刪除，所以只從本地移除
    }
    
    // MARK: - 網路同步方法
    
    @MainActor
    private func uploadEntry(_ entry: DiaryEntry) async {
        do {
            print("🔄 開始上傳日記: \(entry.id)")
            _ = try await networkManager.uploadDiaryEntry(entry)
            
            // 標記為已上傳
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index].isUploaded = true
                entries[index].lastSyncDate = Date()
                saveEntries()
            }
            
            print("✅ 上傳日記成功: \(entry.id)")
            
            // 清除錯誤訊息
            errorMessage = nil
            
        } catch {
            let errorMsg = "上傳失敗: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ 上傳錯誤: \(error)")
            print("❌ 錯誤詳情: \(errorMsg)")
            
            // 即使上傳失敗，也保持本地資料
            print("💾 本地資料已保存，稍後會重試同步")
        }
    }
    
    @MainActor
    private func updateEntryOnServer(_ entry: DiaryEntry) async {
        do {
            print("🔄 開始更新日記到伺服器: \(entry.id)")
            _ = try await networkManager.updateDiaryEntry(entry)
            
            // 標記為已上傳並更新同步時間
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index].isUploaded = true
                entries[index].lastSyncDate = Date()
                saveEntries()
            }
            
            print("✅ 更新日記成功: \(entry.id)")
            
            // 清除錯誤訊息
            errorMessage = nil
            
        } catch {
            let errorMsg = "更新失敗: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ 更新錯誤: \(error)")
            print("❌ 錯誤詳情: \(errorMsg)")
        }
    }
    
    // 根據日期獲取條目（確保同一天只有一個）
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
    
    @MainActor
    func syncAllPendingEntries() async {
        let pendingEntries = entries.filter { !$0.isUploaded }
        
        if pendingEntries.isEmpty {
            print("✅ 沒有待同步的日記")
            return
        }
        
        print("🔄 開始同步 \(pendingEntries.count) 筆待上傳日記")
        isSyncing = true
        
        for entry in pendingEntries {
            await uploadEntryToServer(entry)
            // 稍微延遲避免請求過於頻繁
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        }
        
        isSyncing = false
        print("✅ 本地待同步日記處理完成")
    }
    
    // 完整的雙向同步
    @MainActor
    func retrySyncAll() async {
        errorMessage = nil
        print("🔄 開始完整同步...")
        
        // 1. 先上傳本地未同步的日記
        await syncAllPendingEntries()
        
        // 2. 再執行雙向智能同步
        await syncFromServer()
        
        print("✅ 完整同步完成")
    }
} 