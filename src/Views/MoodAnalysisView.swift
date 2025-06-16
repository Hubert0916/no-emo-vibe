import SwiftUI
import Charts

struct MoodAnalysisView: View {
    @EnvironmentObject var diaryManager: DiaryManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMonth: Date = Date()
    
    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }
    
    // 漸層背景色 - 統一使用淺色模式的顏色
    private var gradientColors: [Color] = [
        Color(red: 0.8, green: 0.9, blue: 1.0), 
        Color(red: 0.7, green: 0.8, blue: 0.9)
    ]
    
    // 時間範圍選項
    enum TimeRange: String, CaseIterable {
        case week = "週"
        case month = "月"
        case year = "年"
    }
    
    // 獲取分析數據
    private var analysisData: [MoodDataPoint] {
        switch selectedTimeRange {
        case .week:
            return getWeeklyData()
        case .month:
            return getMonthlyData()
        case .year:
            return getYearlyData()
        }
    }
    
    // 計算平均心情分數
    private var averageMoodScore: Double {
        let filteredEntries = getFilteredEntries()
        guard !filteredEntries.isEmpty else { return 0 }
        
        let sum = filteredEntries.reduce(0) { $0 + Double($1.moodPercentage) }
        return sum / Double(filteredEntries.count)
    }
    
    // 獲取最常見的心情描述
    private var mostCommonMood: String {
        let filteredEntries = getFilteredEntries()
        guard !filteredEntries.isEmpty else { return "尚無數據" }
        
        var moodCounts: [String: Int] = [:]
        for entry in filteredEntries {
            moodCounts[entry.moodDescription, default: 0] += 1
        }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key ?? "尚無數據"
    }
    
    // 獲取最高和最低心情日
    private var moodExtremes: (highest: DiaryEntry?, lowest: DiaryEntry?) {
        let filteredEntries = getFilteredEntries()
        guard !filteredEntries.isEmpty else { return (nil, nil) }
        
        let highest = filteredEntries.max(by: { $0.moodPercentage < $1.moodPercentage })
        let lowest = filteredEntries.min(by: { $0.moodPercentage < $1.moodPercentage })
        
        return (highest, lowest)
    }
    
    var body: some View {
        ZStack {
            // 漸層背景
            LinearGradient(gradient: Gradient(colors: gradientColors),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 標題
                Text("心情分析")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20) // 增加頂部間距，避免與動態島碰撞
                
                // 時間範圍選擇器
                timeRangeSelector
                
                if diaryManager.entries.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            // 心情圖表
                            moodChartView
                            
                            // 心情統計摘要
                            moodSummaryView
                            
                            // 心情高低點
                            moodExtremesView
                            
                            // 心情模式分析
                            moodPatternView
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light) // 強制使用淺色模式
    }
    
    // 時間範圍選擇器
    private var timeRangeSelector: some View {
        HStack {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation {
                        selectedTimeRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(selectedTimeRange == range ? 
                                      Color.blue : 
                                      Color.gray.opacity(0.2))
                        )
                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 心情圖表視圖
    private var moodChartView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("心情趨勢")
                .font(.title2)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(analysisData) { dataPoint in
                        LineMark(
                            x: .value("日期", dataPoint.date),
                            y: .value("心情", dataPoint.moodPercentage)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        
                        AreaMark(
                            x: .value("日期", dataPoint.date),
                            y: .value("心情", dataPoint.moodPercentage)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .blue.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        PointMark(
                            x: .value("日期", dataPoint.date),
                            y: .value("心情", dataPoint.moodPercentage)
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 220)
                .chartYScale(domain: 0...100)
            } else {
                // iOS 16以下的替代視圖
                Text("圖表需要iOS 16或更高版本")
                    .foregroundColor(.secondary)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // 心情統計摘要
    private var moodSummaryView: some View {
        HStack(spacing: 15) {
            // 平均心情
            VStack(spacing: 10) {
                Text("平均心情")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("\(Int(averageMoodScore))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(moodColor(for: Int(averageMoodScore)))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            // 常見心情
            VStack(spacing: 10) {
                Text("常見心情")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(mostCommonMood)
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    // 心情高低點
    private var moodExtremesView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("心情高低點")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 15) {
                // 最高心情
                extremeCard(
                    title: "最佳狀態",
                    icon: "arrow.up.circle.fill",
                    iconColor: .green,
                    entry: moodExtremes.highest
                )
                
                // 最低心情
                extremeCard(
                    title: "需要關注",
                    icon: "arrow.down.circle.fill",
                    iconColor: .red,
                    entry: moodExtremes.lowest
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // 心情模式分析
    private var moodPatternView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("心情模式")
                .font(.title2)
                .fontWeight(.bold)
            
            let patterns = analyzeMoodPatterns()
            
            if patterns.isEmpty {
                Text("需要更多數據來分析心情模式")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(patterns, id: \.self) { pattern in
                        HStack(spacing: 15) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 20))
                            
                            Text(pattern)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // 空數據視圖
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("尚無足夠數據進行分析")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("完成更多放鬆活動後，您將在這裡看到心情分析")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // 極值卡片
    private func extremeCard(title: String, icon: String, iconColor: Color, entry: DiaryEntry?) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            if let entry = entry {
                VStack(spacing: 5) {
                    Text("\(entry.moodPercentage)%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(moodColor(for: entry.moodPercentage))
                    
                    Text(dateFormatter.string(from: entry.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("尚無數據")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 獲取週數據
    private func getWeeklyData() -> [MoodDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(byAdding: .day, value: -6, to: today)!
        
        var result: [MoodDataPoint] = []
        var currentDate = startOfWeek
        
        while currentDate <= today {
            if let entry = diaryManager.getEntryForDate(currentDate) {
                result.append(MoodDataPoint(date: currentDate, moodPercentage: entry.moodPercentage))
            } else {
                // 沒有數據的日期添加空點
                result.append(MoodDataPoint(date: currentDate, moodPercentage: 0, hasData: false))
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return result
    }
    
    // 獲取月數據
    private func getMonthlyData() -> [MoodDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        // 獲取當月的第一天
        var components = calendar.dateComponents([.year, .month], from: today)
        let startOfMonth = calendar.date(from: components)!
        
        // 獲取當月的天數
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let numberOfDays = range.count
        
        var result: [MoodDataPoint] = []
        
        for day in 1...numberOfDays {
            components.day = day
            if let date = calendar.date(from: components),
               date <= today {
                if let entry = diaryManager.getEntryForDate(date) {
                    result.append(MoodDataPoint(date: date, moodPercentage: entry.moodPercentage))
                } else {
                    // 沒有數據的日期添加空點
                    result.append(MoodDataPoint(date: date, moodPercentage: 0, hasData: false))
                }
            }
        }
        
        return result
    }
    
    // 獲取年數據
    private func getYearlyData() -> [MoodDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        // 獲取當年的第一天
        var components = calendar.dateComponents([.year], from: today)
        components.month = 1
        components.day = 1
        let startOfYear = calendar.date(from: components)!
        
        var result: [MoodDataPoint] = []
        var currentDate = startOfYear
        
        // 按月計算平均心情
        while currentDate <= today {
            let month = calendar.component(.month, from: currentDate)
            components.month = month
            
            // 獲取該月的所有條目
            let entriesInMonth = diaryManager.entries.filter { entry in
                let entryMonth = calendar.component(.month, from: entry.date)
                let entryYear = calendar.component(.year, from: entry.date)
                return entryMonth == month && entryYear == components.year
            }
            
            if !entriesInMonth.isEmpty {
                // 計算月平均心情
                let sum = entriesInMonth.reduce(0) { $0 + $1.moodPercentage }
                let average = sum / entriesInMonth.count
                
                result.append(MoodDataPoint(date: currentDate, moodPercentage: average))
            } else {
                // 沒有數據的月份添加空點
                result.append(MoodDataPoint(date: currentDate, moodPercentage: 0, hasData: false))
            }
            
            // 移至下個月
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }
        
        return result
    }
    
    // 獲取根據選定時間範圍過濾的條目
    private func getFilteredEntries() -> [DiaryEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        switch selectedTimeRange {
        case .week:
            let startOfWeek = calendar.date(byAdding: .day, value: -6, to: today)!
            return diaryManager.entries.filter { $0.date >= startOfWeek && $0.date <= today }
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: today)
            let startOfMonth = calendar.date(from: components)!
            return diaryManager.entries.filter { $0.date >= startOfMonth && $0.date <= today }
            
        case .year:
            var components = calendar.dateComponents([.year], from: today)
            components.month = 1
            components.day = 1
            let startOfYear = calendar.date(from: components)!
            return diaryManager.entries.filter { $0.date >= startOfYear && $0.date <= today }
        }
    }
    
    // 分析心情模式
    private func analyzeMoodPatterns() -> [String] {
        let filteredEntries = getFilteredEntries()
        guard filteredEntries.count >= 3 else { return [] }
        
        var patterns: [String] = []
        
        // 檢測心情波動
        if let fluctuation = detectMoodFluctuation(entries: filteredEntries) {
            patterns.append(fluctuation)
        }
        
        // 檢測心情趨勢
        if let trend = detectMoodTrend(entries: filteredEntries) {
            patterns.append(trend)
        }
        
        // 檢測週期性模式
        if let cyclical = detectCyclicalPattern(entries: filteredEntries) {
            patterns.append(cyclical)
        }
        
        return patterns
    }
    
    // 檢測心情波動
    private func detectMoodFluctuation(entries: [DiaryEntry]) -> String? {
        guard entries.count >= 3 else { return nil }
        
        let sortedEntries = entries.sorted(by: { $0.date < $1.date })
        var differences: [Int] = []
        
        for i in 1..<sortedEntries.count {
            let diff = abs(sortedEntries[i].moodPercentage - sortedEntries[i-1].moodPercentage)
            differences.append(diff)
        }
        
        let averageDiff = differences.reduce(0, +) / differences.count
        
        if averageDiff > 30 {
            return "您的心情波動較大，可能需要更多的穩定活動"
        } else if averageDiff > 15 {
            return "您的心情有適度波動，這是健康的情緒表現"
        } else {
            return "您的心情相對穩定，保持這種平衡狀態"
        }
    }
    
    // 檢測心情趨勢
    private func detectMoodTrend(entries: [DiaryEntry]) -> String? {
        guard entries.count >= 5 else { return nil }
        
        let sortedEntries = entries.sorted(by: { $0.date < $1.date })
        let firstHalf = Array(sortedEntries.prefix(sortedEntries.count / 2))
        let secondHalf = Array(sortedEntries.suffix(sortedEntries.count / 2))
        
        let firstHalfAvg = firstHalf.reduce(0) { $0 + $1.moodPercentage } / firstHalf.count
        let secondHalfAvg = secondHalf.reduce(0) { $0 + $1.moodPercentage } / secondHalf.count
        
        let difference = secondHalfAvg - firstHalfAvg
        
        if difference > 10 {
            return "您的心情呈上升趨勢，繼續保持良好習慣"
        } else if difference < -10 {
            return "您的心情近期有所下降，建議多關注自我照顧"
        }
        
        return nil
    }
    
    // 檢測週期性模式
    private func detectCyclicalPattern(entries: [DiaryEntry]) -> String? {
        guard entries.count >= 7 else { return nil }
        
        let calendar = Calendar.current
        var weekdayMoods: [Int: [Int]] = [:]
        
        // 按星期幾分組
        for entry in entries {
            let weekday = calendar.component(.weekday, from: entry.date)
            weekdayMoods[weekday, default: []].append(entry.moodPercentage)
        }
        
        // 計算每個星期幾的平均心情
        var weekdayAverages: [Int: Int] = [:]
        for (weekday, moods) in weekdayMoods {
            if moods.count >= 2 {  // 至少有兩個數據點
                weekdayAverages[weekday] = moods.reduce(0, +) / moods.count
            }
        }
        
        // 找出最高和最低的星期幾
        if let maxDay = weekdayAverages.max(by: { $0.value < $1.value }),
           let minDay = weekdayAverages.min(by: { $0.value < $1.value }),
           maxDay.value - minDay.value >= 15 {
            
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            
            var maxDayString = "星期日"
            var minDayString = "星期日"
            
            switch maxDay.key {
            case 1: maxDayString = "星期日"
            case 2: maxDayString = "星期一"
            case 3: maxDayString = "星期二"
            case 4: maxDayString = "星期三"
            case 5: maxDayString = "星期四"
            case 6: maxDayString = "星期五"
            case 7: maxDayString = "星期六"
            default: break
            }
            
            switch minDay.key {
            case 1: minDayString = "星期日"
            case 2: minDayString = "星期一"
            case 3: minDayString = "星期二"
            case 4: minDayString = "星期三"
            case 5: minDayString = "星期四"
            case 6: minDayString = "星期五"
            case 7: minDayString = "星期六"
            default: break
            }
            
            return "您在\(maxDayString)通常心情最佳，而在\(minDayString)可能需要更多關注"
        }
        
        return nil
    }
    
    // 根據心情分數返回顏色
    private func moodColor(for percentage: Int) -> Color {
        switch percentage {
        case 0..<20:
            return Color.red.opacity(0.8)
        case 20..<40:
            return Color.orange.opacity(0.8)
        case 40..<60:
            return Color.yellow.opacity(0.8)
        case 60..<80:
            return Color.green.opacity(0.8)
        default:
            return Color.blue.opacity(0.8)
        }
    }
}

// 心情數據點結構
struct MoodDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let moodPercentage: Int
    var hasData: Bool = true
}

#Preview {
    MoodAnalysisView()
        .environmentObject(DiaryManager())
} 
