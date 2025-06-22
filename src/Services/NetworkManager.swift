import Foundation
import UIKit

// API 回應結構
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
}

// 簡單的 API 回應結構（用於不需要特定資料的回應）
struct SimpleAPIResponse: Codable {
    let success: Bool
    let message: String
}

// 網路錯誤類型
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case networkError(Error)
    case notFound(String)
    case conflict(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .noData:
            return "沒有收到資料"
        case .decodingError:
            return "資料解析失敗"
        case .serverError(let message):
            return "伺服器錯誤: \(message)"
        case .networkError(let error):
            return "網路錯誤: \(error.localizedDescription)"
        case .notFound(let message):
            return "資源不存在: \(message)"
        case .conflict(let message):
            return "資源衝突: \(message)"
        }
    }
}

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // API 基礎 URL - 請根據您的服務器地址修改
    private let baseURL = "http://140.113.26.164:8000"
    
    // 裝置 ID (用於識別用戶)
    private var deviceId: String {
        // 檢查是否已經有儲存的裝置 ID
        if let savedDeviceId = UserDefaults.standard.string(forKey: "deviceId") {
            return savedDeviceId
        }
        
        // 生成新的裝置 ID - 使用 iOS 的 identifierForVendor
        let newDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        // 儲存裝置 ID
        UserDefaults.standard.set(newDeviceId, forKey: "deviceId")
        return newDeviceId
    }
    
    private init() {}
    
    // MARK: - 通用 HTTP 請求方法
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)/api\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 檢查 HTTP 狀態碼
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API 請求: \(method.rawValue) \(endpoint)")
                print("📊 狀態碼: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode >= 400 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "未知錯誤"
                    print("📄 錯誤回應: \(errorMessage)")
                    
                    // 根據狀態碼拋出特定錯誤
                    switch httpResponse.statusCode {
                    case 404:
                        throw NetworkError.notFound(errorMessage)
                    case 409:
                        throw NetworkError.conflict(errorMessage)
                    default:
                        throw NetworkError.serverError(errorMessage)
                    }
                }
            }
            
            // 解析回應
            let decoder = JSONDecoder()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // 嘗試不同格式
                let isoFormatter = ISO8601DateFormatter()
                if let date = isoFormatter.date(from: dateString) {
                    return date
                }
                
                let dateFormatter1 = DateFormatter()
                dateFormatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                if let date = dateFormatter1.date(from: dateString) {
                    return date
                }
                
                let dateFormatter2 = DateFormatter()
                dateFormatter2.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let date = dateFormatter2.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "無法解析日期: \(dateString)")
                )
            }
            
            do {
                let result = try decoder.decode(responseType, from: data)
                print("✅ API 回應成功")
                return result
            } catch let decodingError as DecodingError {
                print("❌ 解析錯誤: \(decodingError)")
                throw NetworkError.decodingError
            }
            
        } catch let networkError as NetworkError {
            // 重新拋出我們自定義的錯誤
            throw networkError
        } catch {
            print("❌ 網路錯誤: \(error)")
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - 裝置註冊
    
    func registerDevice() async throws -> SimpleAPIResponse {
        let body = ["device_id": deviceId]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        return try await makeRequest(
            endpoint: "/users",
            method: .POST,
            body: bodyData,
            responseType: SimpleAPIResponse.self
        )
    }
    
    // MARK: - 日記 API 方法
    
    func uploadDiaryEntry(_ entry: DiaryEntry) async throws -> SimpleAPIResponse {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let requestBody: [String: Any] = [
            "entry_uuid": entry.id.uuidString,
            "entry_date": dateFormatter.string(from: entry.date),
            "mood_score": entry.moodScore,
            "mood_percentage": entry.moodPercentage,
            "activities": entry.activities,
            "notes": entry.notes,
            "device_id": deviceId
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            print("🔄 嘗試上傳日記: \(entry.date)")
            return try await makeRequest(
                endpoint: "/diary-entries",
                method: .POST,
                body: bodyData,
                responseType: SimpleAPIResponse.self
            )
        } catch NetworkError.conflict(_) {
            // 409 衝突：同一天已有日記，強制覆蓋
            print("⚠️ 同一天已有日記，強制覆蓋: \(entry.date)")
            return try await forceUpdateDiaryEntry(entry)
        }
    }
    
    // 強制覆蓋更新日記（以本地為主）
    private func forceUpdateDiaryEntry(_ entry: DiaryEntry) async throws -> SimpleAPIResponse {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let requestBody: [String: Any] = [
            "entry_date": dateFormatter.string(from: entry.date),
            "mood_score": entry.moodScore,
            "mood_percentage": entry.moodPercentage,
            "activities": entry.activities,
            "notes": entry.notes
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔄 強制覆蓋更新日記: \(entry.id)")
        return try await makeRequest(
            endpoint: "/diary-entries/\(entry.id.uuidString)?device_id=\(deviceId)",
            method: .PUT,
            body: bodyData,
            responseType: SimpleAPIResponse.self
        )
    }
    
    func fetchDiaryEntries() async throws -> [DiaryEntry] {
        return try await makeRequest(
            endpoint: "/diary-entries?device_id=\(deviceId)",
            method: .GET,
            responseType: [DiaryEntry].self
        )
    }
    
    func updateDiaryEntry(_ entry: DiaryEntry) async throws -> SimpleAPIResponse {
        let requestBody: [String: Any] = [
            "mood_score": entry.moodScore,
            "mood_percentage": entry.moodPercentage,
            "activities": entry.activities,
            "notes": entry.notes
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            print("🔄 嘗試更新日記: \(entry.id)")
            return try await makeRequest(
                endpoint: "/diary-entries/\(entry.id.uuidString)?device_id=\(deviceId)",
                method: .PUT,
                body: bodyData,
                responseType: SimpleAPIResponse.self
            )
        } catch NetworkError.notFound(_) {
            // 404 不存在：日記不存在，直接上傳新日記
            print("⚠️ 日記不存在，直接上傳新日記: \(entry.id)")
            return try await uploadDiaryEntryDirect(entry)
        }
    }
    
    // 直接上傳日記（避免衝突檢查的無限循環）
    private func uploadDiaryEntryDirect(_ entry: DiaryEntry) async throws -> SimpleAPIResponse {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let requestBody: [String: Any] = [
            "entry_uuid": entry.id.uuidString,
            "entry_date": dateFormatter.string(from: entry.date),
            "mood_score": entry.moodScore,
            "mood_percentage": entry.moodPercentage,
            "activities": entry.activities,
            "notes": entry.notes,
            "device_id": deviceId
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔄 直接上傳日記（無衝突檢查）: \(entry.id)")
        return try await makeRequest(
            endpoint: "/diary-entries",
            method: .POST,
            body: bodyData,
            responseType: SimpleAPIResponse.self
        )
    }
    
    // 檢查日記是否存在於伺服器
    func checkDiaryEntryExists(_ entryId: UUID) async throws -> Bool {
        do {
            _ = try await makeRequest(
                endpoint: "/diary-entries?device_id=\(deviceId)",
                method: .GET,
                responseType: [DiaryEntry].self
            )
            // 如果能成功取得列表，檢查是否包含此 ID
            let entries = try await fetchDiaryEntries()
            return entries.contains { $0.id == entryId }
        } catch {
            return false
        }
    }
    
    // 獲取當前裝置 ID (供調試使用)
    func getCurrentDeviceId() -> String {
        return deviceId
    }
}

// HTTP 方法枚舉
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
} 