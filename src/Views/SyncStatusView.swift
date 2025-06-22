import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var diaryManager: DiaryManager
    
    private var pendingCount: Int {
        diaryManager.entries.filter { !$0.isUploaded }.count
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 同步狀態圖示
            if diaryManager.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                Text("初始化中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if diaryManager.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
                Text("同步中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if pendingCount > 0 {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.orange)
                Text("待同步 \(pendingCount) 筆")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.green)
                Text("已同步")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 手動同步按鈕
            Button(action: {
                Task {
                    await diaryManager.retrySyncAll()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
            .disabled(diaryManager.isLoading || diaryManager.isSyncing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// 條目同步狀態指示器
struct EntryStatusIndicator: View {
    let entry: DiaryEntry
    
    var body: some View {
        HStack(spacing: 4) {
            if entry.isUploaded {
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            
            if let syncDate = entry.lastSyncDate {
                Text(DateFormatter.shortTime.string(from: syncDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 錯誤提示視圖
struct ErrorBannerView: View {
    let errorMessage: String
    let onDismiss: () -> Void
    @ObservedObject var diaryManager: DiaryManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("關閉") {
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // 重試按鈕
            HStack {
                Spacer()
                Button("重試同步") {
                    Task {
                        await diaryManager.retrySyncAll()
                    }
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(4)
                .disabled(diaryManager.isSyncing)
            }
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemYellow), lineWidth: 1)
        )
    }
}

// DateFormatter 擴展
extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
} 