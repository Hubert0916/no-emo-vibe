import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DiaryView: View {
    @EnvironmentObject var diaryManager: DiaryManager
    
    @State private var selectedMonth: Date = Date()  // 當前選中月份
    @State private var dragOffset: CGFloat = 0  // 滑動手勢的偏移量
    @State private var showingDatePicker = false  // 控制日期選擇器的顯示
    @State private var selectedDate = Date()  // 用於補記的日期
    
    // 漸層背景色 - 統一使用淺色模式的顏色
    private var gradientColors: [Color] = [
        Color(red: 0.8, green: 0.9, blue: 1.0), 
        Color(red: 0.7, green: 0.8, blue: 0.9)
    ]
    
    // 格式化月份顯示
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月"
        return formatter
    }
    
    // 根據選中月份篩選日記
    private var filteredEntries: [DiaryEntry] {
        let calendar = Calendar.current
        return diaryManager.entries.filter { entry in
            let entryComponents = calendar.dateComponents([.year, .month], from: entry.date)
            let selectedComponents = calendar.dateComponents([.year, .month], from: selectedMonth)
            return entryComponents.year == selectedComponents.year && entryComponents.month == selectedComponents.month
        }
    }
    
    var body: some View {
        ZStack {
            // 漸層背景
            LinearGradient(gradient: Gradient(colors: gradientColors),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                // 月份選擇器
                monthSelectorView
                
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    entriesListView
                }
                
                Spacer()
            }
            
            // 浮動添加按鈕
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .padding(.trailing, 25)
                    .padding(.bottom, 90) // 增加底部間距，避免被遮擋
                }
            }
        }
        // 添加水平滑動手勢
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    dragOffset = gesture.translation.width
                }
                .onEnded { gesture in
                    if gesture.translation.width > 100 {
                        // 右滑，上個月
                        withAnimation {
                            changeMonth(by: -1)
                        }
                    } else if gesture.translation.width < -100 {
                        // 左滑，下個月
                        withAnimation {
                            changeMonth(by: 1)
                        }
                    }
                    dragOffset = 0
                }
        )
        // 日期選擇器彈窗
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate, isPresented: $showingDatePicker, diaryManager: diaryManager)
                .preferredColorScheme(.light)
        }
        .preferredColorScheme(.light)
    }
    
    // 月份選擇器視圖
    private var monthSelectorView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    changeMonth(by: -1)
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding()
            
            Spacer()
            
            Text(monthFormatter.string(from: selectedMonth))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
                .offset(x: dragOffset / 10)  // 輕微跟隨滑動效果
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    changeMonth(by: 1)
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("本月尚未有日記記錄")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("完成放鬆活動後，您的體驗將自動記錄在這裡")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var entriesListView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(filteredEntries) { entry in
                    NavigationLink(destination: DiaryEntryDetailView(entry: entry)
                        .environmentObject(diaryManager)) {
                        DiaryEntryRow(entry: entry)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .offset(x: dragOffset / 3)  // 輕微跟隨滑動效果
        }
    }
    
    // 變更月份的方法
    private func changeMonth(by value: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}

// 日期選擇器視圖
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @ObservedObject var diaryManager: DiaryManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingRelaxationView = false
    @State private var navigateToEdit = false
    @State private var entryToEdit: DiaryEntry?
    @State private var showOverwriteAlert = false  // 控制覆蓋確認提示的顯示
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 25) {
                // 標題
                Text("選擇日期")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                Text("為過去的日期添加心情記錄")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                
                // 日期選擇器
                DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                
                // 按鈕
                HStack(spacing: 20) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("取消")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        if diaryManager.hasEntryForDate(selectedDate) {
                            showOverwriteAlert = true
                        } else {
                            showingRelaxationView = true
                        }
                    }) {
                        Text("確認")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
            )
            .padding()
        }
        .alert(isPresented: $showOverwriteAlert) {
            Alert(
                title: Text("已有記錄"),
                message: Text("該日期已有心情記錄，是否要覆蓋？"),
                primaryButton: .default(Text("覆蓋")) {
                    showingRelaxationView = true
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .fullScreenCover(isPresented: $showingRelaxationView, onDismiss: {
            isPresented = false
        }) {
            BackdatedRelaxationView(selectedDate: selectedDate)
                .environmentObject(diaryManager)
        }
    }
}

// 為過去日期創建的放鬆視圖
struct BackdatedRelaxationView: View {
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var diaryManager: DiaryManager
    
    var body: some View {
        RelaxationView(customDate: selectedDate)
            .environmentObject(diaryManager)
            .interactiveDismissDisabled(true)  // 防止用戶通過下滑關閉視圖
    }
}

struct DiaryEntryRow: View {
    let entry: DiaryEntry
    @Environment(\.colorScheme) private var colorScheme
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // 心情指示器
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(moodColor)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Double(entry.moodPercentage) / 100, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(moodColor)
                    .rotationEffect(Angle(degrees: 270.0))
                
                Text("\(entry.moodPercentage)%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(moodColor)
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(dateFormatter.string(from: entry.date))
                    .font(.system(.headline, design: .rounded))
                
                Text(entry.moodDescription)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                
                if !entry.activities.isEmpty {
                    Text(entry.activities.prefix(2).joined(separator: ", "))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(.body, design: .rounded))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var moodColor: Color {
        switch entry.moodPercentage {
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

struct DiaryEntryDetailView: View {
    @EnvironmentObject var diaryManager: DiaryManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let entry: DiaryEntry
    @State private var notes: String
    @State private var showingSaveSuccess = false
    
    init(entry: DiaryEntry) {
        self.entry = entry
        _notes = State(initialValue: entry.notes)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.95, green: 0.95, blue: 1.0)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // 日期和心情
                    Text(dateFormatter.string(from: entry.date))
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 30)
                    
                    // 心情卡片
                    ZStack {
                        // 卡片背景
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // 內容
                        HStack(spacing: 25) {
                            // 環形進度
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 10)
                                    .opacity(0.3)
                                    .foregroundColor(moodColor)
                                
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(min(Double(entry.moodPercentage) / 100, 1.0)))
                                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                                    .foregroundColor(moodColor)
                                    .rotationEffect(Angle(degrees: 270.0))
                                
                                VStack(spacing: 5) {
                                    Text("\(entry.moodPercentage)%")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(moodColor)
                                    
                                    Text("心情指數")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 110, height: 110)
                            
                            // 文字說明區
                            VStack(alignment: .leading, spacing: 10) {
                                Text(entry.moodDescription)
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(moodColor)
                                
                                Text(getMoodMessage(for: entry.moodPercentage))
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 30)
                        .frame(height: 160)
                    }
                    .padding(.horizontal)
                    
                    // 活動推薦
                    VStack(alignment: .leading, spacing: 15) {
                        Text("今日活動")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(entry.activities, id: \.self) { activity in
                                HStack(spacing: 15) {
                                    // 表情符號
                                    Text(activity.prefix(2))
                                        .font(.system(size: 30))
                                    
                                    // 活動文字
                                    Text(activity.dropFirst(2))
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 筆記
                    VStack(alignment: .leading, spacing: 10) {
                        Text("我的感受")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        TextEditor(text: $notes)
                            .font(.system(.body, design: .rounded))
                            .frame(minHeight: 150)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal)
                            .onChange(of: notes) { _, newValue in
                                saveNotes()
                            }
                    }
                    
                    // 底部間距
                    Spacer(minLength: 30)
                }
            }
            
            // 保存成功提示
            if showingSaveSuccess {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                        
                        Text("筆記已保存")
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(25)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    private var moodColor: Color {
        switch entry.moodPercentage {
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
    
    private func getMoodMessage(for percentage: Int) -> String {
        switch percentage {
        case 0..<20:
            return "今天可能有些困難，請善待自己"
        case 20..<40:
            return "保持耐心，慢慢調整"
        case 40..<60:
            return "維持現狀，尋找小確幸"
        case 60..<80:
            return "保持良好狀態，持續成長"
        default:
            return "分享您的能量，帶動他人"
        }
    }
    
    private func saveNotes() {
        var updatedEntry = entry
        updatedEntry.notes = notes
        diaryManager.updateEntry(updatedEntry)
        
        // 顯示保存成功提示（暫時隱藏，避免頻繁彈出）
        // withAnimation {
        //     showingSaveSuccess = true
        // }
        
        // DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        //     withAnimation {
        //         showingSaveSuccess = false
        //     }
        // }
    }
}

#Preview {
    DiaryView()
        .environmentObject(DiaryManager())
} 