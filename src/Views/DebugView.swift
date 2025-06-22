import SwiftUI

struct DebugView: View {
    @EnvironmentObject var diaryManager: DiaryManager
    @State private var testResults: [String] = []
    @State private var isRunningTest = false
    private let networkManager = NetworkManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🛠️ 調試工具")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 基本信息
                VStack(alignment: .leading, spacing: 10) {
                    Text("📊 基本信息")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("裝置 ID: \(NetworkManager.shared.getCurrentDeviceId())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("本地日記數量: \(diaryManager.entries.count)")
                        .font(.body)
                    
                    Text("待同步數量: \(diaryManager.entries.filter { !$0.isUploaded }.count)")
                        .font(.body)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 同步邏輯說明
                VStack(alignment: .leading, spacing: 8) {
                    Text("📋 同步邏輯")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 本地有，遠端沒有 → 上傳本地到遠端")
                            .font(.caption)
                        Text("• 本地有，遠端也有 → 以本地覆蓋遠端")
                            .font(.caption)
                        Text("• 本地沒有，遠端有 → 下載到本地")
                            .font(.caption)
                        Text("• 同一天只能有一個日記")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 同步按鈕
                VStack(spacing: 10) {
                    Button("🔄 完整雙向同步") {
                        Task {
                            await diaryManager.retrySyncAll()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(diaryManager.isSyncing)
                    
                    Button("📤 僅上傳本地") {
                        Task {
                            await diaryManager.syncAllPendingEntries()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(diaryManager.isSyncing)
                    
                    Button("📥 僅從服務器同步") {
                        Task {
                            await diaryManager.syncFromServer()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(diaryManager.isSyncing)
                }
                
                // 測試功能
                VStack(spacing: 10) {
                    Text("🧪 測試功能")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Button("創建測試日記") {
                        createTestEntry()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("清空本地日記") {
                        clearLocalEntries()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                // 日記列表
                if !diaryManager.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("📝 本地日記列表")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 5) {
                                ForEach(diaryManager.entries.prefix(10), id: \.id) { entry in
                                    HStack {
                                        Text(DateFormatter.shortDate.string(from: entry.date))
                                            .font(.caption)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        Text("\(entry.moodPercentage)%")
                                            .font(.caption)
                                            .frame(width: 40, alignment: .leading)
                                        
                                        if entry.isUploaded {
                                            Image(systemName: "checkmark.icloud")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                        } else {
                                            Image(systemName: "icloud.and.arrow.up")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("調試")
        }
    }
    
    private func createTestEntry() {
        let testEntry = DiaryEntry(
            date: Date(),
            moodScore: Int.random(in: 5...20),
            moodPercentage: Int.random(in: 20...90),
            activities: ["🎵 聽音樂", "📚 閱讀"],
            notes: "測試日記 - \(Date())"
        )
        diaryManager.addEntry(testEntry)
    }
    
    private func clearLocalEntries() {
        diaryManager.entries.removeAll()
        diaryManager.saveEntries()
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
} 