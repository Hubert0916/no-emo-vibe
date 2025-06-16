import SwiftUI

// 問題卡片視圖
struct QuestionCard: View {
    let question: Question
    let questionIndex: Int
    let onOptionSelected: (Int) -> Void
    
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 0.9
    @State private var cardOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Q\(questionIndex + 1)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(question.text)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(0..<5) { index in
                    Button(action: {
                        withAnimation(.spring()) {
                            onOptionSelected(index)
                        }
                    }) {
                        Text(question.options[index])
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    .opacity(0.5)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .rotation3DEffect(
            .degrees(cardRotation),
            axis: (x: 0, y: 1, z: 0)
        )
        .scaleEffect(cardScale)
        .opacity(cardOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                cardRotation = 0
                cardScale = 1
                cardOpacity = 1
            }
        }
    }
}

// 按鈕縮放效果
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// 進度指示器
struct ProgressIndicator: View {
    let totalQuestions: Int
    let currentIndex: Int
    
    var body: some View {
        HStack {
            ForEach(0..<totalQuestions, id: \.self) { index in
                Circle()
                    .fill(index <= currentIndex ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: index == currentIndex ? 2 : 0)
                            .scaleEffect(1.3)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .scaleEffect(index == currentIndex ? 0.5 : 0)
                            .opacity(index == currentIndex ? 1 : 0)
                    )
                
                if index < totalQuestions - 1 {
                    Rectangle()
                        .fill(index < currentIndex ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 15)
        .animation(.spring(response: 0.3), value: currentIndex)
    }
}

// 結果轉場動畫視圖
struct ResultTransitionView: View {
    @Binding var isShowing: Bool
    let onFinished: () -> Void
    
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.5), .purple.opacity(0.8)]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .frame(width: 300, height: 300)
                .scaleEffect(scale)
                .opacity(opacity)
                .rotationEffect(.degrees(rotation))
                .blur(radius: 30)
                
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .opacity(opacity)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.2
                opacity = 0.8
                rotation = 360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 0
                    scale = 2
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowing = false
                    onFinished()
                }
            }
        }
    }
}

// 結果動態背景
struct AnimatedBackground: View {
    @State private var moveGradient = false
    
    var body: some View {
        ZStack {
            // 動態漸變背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: moveGradient ? .topLeading : .bottomTrailing,
                endPoint: moveGradient ? .bottomTrailing : .topLeading
            )
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    moveGradient.toggle()
                }
            }
            
            // 浮動粒子
            ForEach(0..<20) { index in
                FloatingParticle(index: index)
            }
        }
    }
}

// 浮動粒子
struct FloatingParticle: View {
    let index: Int
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                index % 3 == 0 ? Color.blue.opacity(0.5) :
                index % 3 == 1 ? Color.purple.opacity(0.5) :
                Color.green.opacity(0.5)
            )
            .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
            .offset(x: xOffset, y: yOffset)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // 隨機初始位置
                let randomX = CGFloat.random(in: -150...150)
                let randomY = CGFloat.random(in: -150...150)
                xOffset = randomX
                yOffset = randomY
                
                // 隨機透明度
                opacity = Double.random(in: 0.3...0.8)
                
                // 開始動畫循環
                withAnimation(Animation.easeInOut(duration: Double.random(in: 2...6)).repeatForever(autoreverses: true).delay(Double.random(in: 0...2))) {
                    yOffset = randomY + CGFloat.random(in: -30...30)
                    xOffset = randomX + CGFloat.random(in: -30...30)
                    scale = CGFloat.random(in: 0.8...1.2)
                    opacity = Double.random(in: 0.3...0.8)
                }
            }
    }
}

// 動態心情指數環
struct AnimatedMoodRing: View {
    let percentage: Int
    let color: Color
    @State private var animatedPercentage: Double = 0
    @State private var ringScale: CGFloat = 0.9
    @State private var ringRotation: Double = -90
    @State private var pulseOpacity: Double = 0.7
    @State private var pulseScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    @State private var textScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // 外環脈動效果
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 20)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
            
            // 發光效果
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 25)
                .blur(radius: 15)
                .scaleEffect(0.85)
            
            // 背景環
            Circle()
                .stroke(lineWidth: 15)
                .opacity(0.3)
                .foregroundColor(color)
            
            // 進度環 - 使用單一顏色
            Circle()
                .trim(from: 0.0, to: CGFloat(min(animatedPercentage / 100, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: ringRotation))
                .scaleEffect(ringScale)
            
            // 百分比文字
            VStack(spacing: 5) {
                Text("\(percentage)%")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text("心情指數")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .scaleEffect(textScale)
            .opacity(textOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedPercentage = Double(percentage)
                ringRotation = 270
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                ringScale = 1.0
                textScale = 1.0
            }
            
            withAnimation(.easeIn.delay(0.3)) {
                textOpacity = 1
            }
            
            // 脈動效果
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
                pulseOpacity = 0.4
            }
        }
    }
}

// 活動卡片視圖
struct ActivityCard: View {
    let activity: String
    let color: Color
    @State private var cardScale: CGFloat = 0.95
    @State private var cardOpacity: Double = 0
    @State private var iconRotation: Double = -5
    
    var body: some View {
        HStack(spacing: 15) {
            // 取得表情符號
            Text(activity.prefix(2))
                .font(.system(size: 30))
                .rotationEffect(.degrees(iconRotation))
            
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1.5)
        )
        .scaleEffect(cardScale)
        .opacity(cardOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double.random(in: 0.1...0.3))) {
                cardScale = 1.0
                cardOpacity = 1.0
                iconRotation = Double.random(in: -3...3)
            }
        }
    }
}

// 活動推薦分組視圖
struct ActivityRecommendationGroup: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let activities: [String]
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 標題區域
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 5)
            .opacity(titleOpacity)
            .offset(y: titleOffset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    titleOpacity = 1
                    titleOffset = 0
                }
            }
            
            // 活動列表
            VStack(spacing: 15) {
                ForEach(activities, id: \.self) { activity in
                    ActivityCard(activity: activity, color: color)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal)
    }
}

struct RelaxationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var diaryManager: DiaryManager
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [Int] = []
    @State private var showResult = false
    @State private var moodScore = 0
    @State private var notes: String = ""
    @State private var showThreadsShare = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isShareButtonDisabled = false
    @State private var preparedImage: UIImage? = nil
    @State private var recommendedDynamicActivities: [String] = []
    @State private var recommendedStaticActivities: [String] = []
    
    // 轉場動畫狀態
    @State private var showTransition = false
    @State private var slideOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1
    
    // 添加自定義日期屬性，默認為當前日期
    var customDate: Date
    
    // 初始化器，允許傳入自定義日期
    init(customDate: Date = Date()) {
        self.customDate = customDate
    }
    
    // 改良的漸層背景色
    private var gradientColors: [Color] {
        colorScheme == .dark ?
            [Color(red: 0.1, green: 0.2, blue: 0.3), Color(red: 0.2, green: 0.3, blue: 0.4)] :
            [Color(red: 0.8, green: 0.9, blue: 1.0), Color(red: 0.7, green: 0.8, blue: 0.9)]
    }
    
    // 強化深度的問題列表
    private let questions = [
        Question(
            text: "當你回顧今天的經歷時，整體情緒如何？",
            options: [
                "感到失落與無助 😢",
                "有些沮喪與疲憊 😕",
                "平靜但有些波動 😐",
                "大致愉快與滿足 🙂",
                "充滿活力與幸福 😊"
            ]
        ),
        Question(
            text: "面對今天的挑戰與壓力，你的心理狀態是？",
            options: [
                "不堪重負，難以承受 😫",
                "感到壓力，但勉強應對 😓",
                "有些緊張，但能保持平衡 😌",
                "從容應對，保持樂觀 😊",
                "視為成長機會，充滿動力 😎"
            ]
        ),
        Question(
            text: "關於你與自我的連結，今天感受如何？",
            options: [
                "感到迷失，不了解自己 😵‍💫",
                "有些混亂，難以聚焦 😔",
                "基本清晰，但有疑惑 🤔",
                "了解自己的需求與感受 🧘‍♀️",
                "深刻感受自我，充滿自信 ✨"
            ]
        ),
        Question(
            text: "在人際關係互動中，今天的體驗是？",
            options: [
                "感到疏離與不理解 😣",
                "有些尷尬與不安 😕",
                "平常交流，無特別感受 😐",
                "溫暖的連結與交流 🙂",
                "深刻的共鳴與快樂 🥰"
            ]
        ),
        Question(
            text: "對於未來的期望，你現在的心態是？",
            options: [
                "感到恐懼與擔憂 😰",
                "有些不確定與猶豫 😟",
                "保持中立，順其自然 😌",
                "有信心，期待美好 🌟",
                "充滿熱情與願景 🚀"
            ]
        )
    ]
    
    // 根據分數推薦的動態活動
    private func getRecommendedDynamicActivities() -> [String] {
        let averageScore = Double(moodScore) / Double(questions.count)
        
        // 更細緻的分數區間和更多活動選項
        let activities: [[String]] = [
            // 0-0.9 分 - 極度低落
            [
                "🚶‍♀️ 緩慢散步10分鐘，專注於呼吸",
                "🧘‍♂️ 進行5分鐘簡單伸展運動",
                "🌳 在窗邊靜靜坐著，感受陽光",
                "💧 喝一杯溫水，感受它流過身體",
                "🌬️ 練習深呼吸，每次5次，重複3組",
                "🧠 進行簡單的身體掃描冥想"
            ],
            // 1.0-1.9 分 - 低落
            [
                "🚶‍♀️ 緩慢散步15分鐘，專注於呼吸",
                "🧘‍♂️ 進行溫和的伸展運動",
                "🌳 在自然環境中靜靜漫步",
                "🌸 照料植物或整理花園",
                "🧹 輕鬆整理房間，創造舒適空間",
                "🐾 與寵物互動，感受無條件的愛"
            ],
            // 2.0-2.9 分 - 平靜
            [
                "🏊‍♀️ 輕鬆游泳或泡溫水澡",
                "🚲 適度的騎自行車活動",
                "💃 跟隨輕柔音樂自由舞動",
                "🧶 嘗試手工藝活動，如編織或繪畫",
                "🥗 準備健康的餐點，享受烹飪過程",
                "🌿 在公園進行緩慢瑜伽練習"
            ],
            // 3.0-3.9 分 - 積極
            [
                "🏃‍♂️ 慢跑20-30分鐘",
                "🧗‍♀️ 嘗試室內攀岩",
                "🏸 約朋友打羽毛球或網球",
                "🚵‍♂️ 騎自行車探索新路線",
                "💪 進行中等強度的力量訓練",
                "🏄‍♂️ 嘗試新的水上運動"
            ],
            // 4.0-5.0 分 - 充滿活力
            [
                "🤸‍♀️ 參加團體健身課程",
                "🏄‍♂️ 嘗試新的運動挑戰",
                "🚵‍♂️ 規劃一次戶外騎行冒險",
                "🏊‍♂️ 挑戰長距離游泳",
                "🧗‍♂️ 組織戶外團體活動",
                "🏃‍♀️ 參加社區運動賽事"
            ]
        ]
        
        // 確定分數區間
        let index = min(Int(averageScore), activities.count - 1)
        
        // 從該區間隨機選擇3個活動
        var selectedActivities = Set<String>()
        let optionsForThisLevel = activities[index]
        
        while selectedActivities.count < 3 && selectedActivities.count < optionsForThisLevel.count {
            if let randomActivity = optionsForThisLevel.randomElement() {
                selectedActivities.insert(randomActivity)
            }
        }
        
        return Array(selectedActivities)
    }
    
    // 根據分數推薦的靜態活動
    private func getRecommendedStaticActivities() -> [String] {
        let averageScore = Double(moodScore) / Double(questions.count)
        
        // 更細緻的分數區間和更多活動選項
        let activities: [[String]] = [
            // 0-0.9 分 - 極度低落
            [
                "🧘‍♀️ 進行引導式冥想減壓",
                "🎵 聆聽治癒系音樂",
                "☕ 品嚐一杯舒緩的花草茶",
                "📱 使用正念冥想應用5分鐘",
                "🛌 允許自己小睡20分鐘",
                "🌈 寫下三件今天感恩的小事"
            ],
            // 1.0-1.9 分 - 低落
            [
                "📝 寫下內心感受與反思",
                "📚 閱讀心理健康相關書籍",
                "🎨 進行無壓力的塗鴉",
                "🧩 專注於簡單的拼圖活動",
                "📞 與親近的朋友通話",
                "🧠 練習正念呼吸10分鐘"
            ],
            // 2.0-2.9 分 - 平靜
            [
                "📷 靜心攝影記錄生活美好",
                "🧩 專注完成一個拼圖",
                "🌱 照顧植物，觀察其成長",
                "📓 寫日記，記錄當下感受",
                "🎭 觀看輕鬆的喜劇電影",
                "🎧 創建新的音樂播放列表"
            ],
            // 3.0-3.9 分 - 積極
            [
                "📖 閱讀啟發性的書籍",
                "✍️ 創意寫作或寫日記",
                "🎧 聆聽有深度的播客",
                "🎬 觀看紀錄片，學習新知識",
                "🎹 嘗試演奏樂器或唱歌",
                "🧠 學習新語言的基礎詞彙"
            ],
            // 4.0-5.0 分 - 充滿活力
            [
                "🧠 學習新知識或技能",
                "🎭 欣賞藝術表演或展覽",
                "💭 規劃未來目標與願景",
                "👥 組織小型社交聚會",
                "📊 開始一個創意項目",
                "🌍 規劃下一次旅行或冒險"
            ]
        ]
        
        // 確定分數區間
        let index = min(Int(averageScore), activities.count - 1)
        
        // 從該區間隨機選擇3個活動
        var selectedActivities = Set<String>()
        let optionsForThisLevel = activities[index]
        
        while selectedActivities.count < 3 && selectedActivities.count < optionsForThisLevel.count {
            if let randomActivity = optionsForThisLevel.randomElement() {
                selectedActivities.insert(randomActivity)
            }
        }
        
        return Array(selectedActivities)
    }
    
    // 合併所有推薦活動
    private func getAllRecommendedActivities() -> [String] {
        return recommendedDynamicActivities + recommendedStaticActivities
    }
    
    // 生成分享內容
    private func generateShareContent() -> String {
        let percentage = Int(Double(moodScore) / Double(questions.count) / 4 * 100)
        let mood = getMoodDescription(for: percentage)
        let randomEmojis = ["✨", "🌈", "🎯", "💫", "🌟", "⭐️", "🔆", "🎨"].shuffled().prefix(2)
        
        // 根據心情分數選擇不同的描述語
        let moodPhrase: String
        switch percentage {
        case 0..<20:
            moodPhrase = "每個人都有低潮時刻，讓我們一起加油！💪"
        case 20..<40:
            moodPhrase = "保持希望，明天會更好！🌅"
        case 40..<60:
            moodPhrase = "平穩前行，繼續保持！🚶‍♂️"
        case 60..<80:
            moodPhrase = "今天狀態很棒呢！繼續保持！🎯"
        default:
            moodPhrase = "太棒了！請繼續保持這份好心情！🎉"
        }
        
        // 隨機選擇一個正向標語
        let positiveQuotes = [
            "每一天都是新的開始 🌱",
            "保持正向，擁抱生活 🤗",
            "相信自己，你最棒！💫",
            "微笑面對每一天 😊",
            "一步一步，穩健前進 👣"
        ]
        let randomQuote = positiveQuotes.randomElement() ?? ""
        
        return """
\(randomEmojis.joined()) 今日心情追蹤 \(randomEmojis.joined())

💭 心情指數：\(percentage)%
✨ 心情狀態：\(mood.0)
🎯 心情描述：\(mood.1)

💫 每日小語：
\(randomQuote)

\(moodPhrase)

#NoEmoVibe #心情追蹤 #情緒健康
"""
    }
    
    // 根據心情百分比取得心情描述
    private func getMoodDescription(for percentage: Int) -> (String, String, Color) {
        switch percentage {
        case 0..<20:
            return ("需要關愛", "今天可能有些困難，請善待自己", Color.red.opacity(0.8))
        case 20..<40:
            return ("心潮微湧", "保持耐心，慢慢調整", Color.orange.opacity(0.8))
        case 40..<60:
            return ("穩定平衡", "維持現狀，尋找小確幸", Color.yellow.opacity(0.8))
        case 60..<80:
            return ("積極向上", "保持良好狀態，持續成長", Color.green.opacity(0.8))
        default:
            return ("光芒四射", "分享您的能量，帶動他人", Color.blue.opacity(0.8))
        }
    }
    
    var body: some View {
        ZStack {
            // 漸層背景
            LinearGradient(gradient: Gradient(colors: gradientColors),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // 浮動背景粒子
            ForEach(0..<15) { index in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.05...0.2)))
                    .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 2)
            }
            
            if showResult {
                ScrollView {
                    VStack(spacing: 25) {
                        // 結果標題
                        Text("心情評估結果")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .padding(.top, 30)
                            .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
                            .transition(.scale.combined(with: .opacity))
                        
                        // 心情圓環和描述
                        moodResultView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showResult)
                        
                        // 分享按鈕
                        Button(action: {
                            guard !isShareButtonDisabled else { return }
                            isShareButtonDisabled = true
                            
                            // 準備分享內容
                            let shareText = generateShareContent()
                            let shareImage = preparedImage ?? createShareImage()
                            
                            shareItems = [shareText, shareImage]
                            showShareSheet = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isShareButtonDisabled = false
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("分享")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                ZStack {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.98, green: 0.36, blue: 0.53),
                                            Color(red: 0.91, green: 0.27, blue: 0.73),
                                            Color(red: 0.51, green: 0.28, blue: 0.96)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    
                                    // 光效
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .opacity(isShareButtonDisabled ? 0.6 : 1.0)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showShareSheet, onDismiss: {
                            // 確保分享表單關閉後重置按鈕狀態
                            isShareButtonDisabled = false
                        }) {
                            ShareSheet(activityItems: shareItems)
                        }
                        .onAppear {
                            // 在結果頁面顯示時預先準備分享資源
                            prepareShareResources()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showResult)
                        
                        // 活動推薦
                        Group {
                            // 動態活動推薦
                            activityRecommendationsView(
                                title: "動態活動推薦",
                                subtitle: "適合您當前心情的體能活動",
                                icon: "figure.run",
                                activities: recommendedDynamicActivities
                            )
                            .padding(.top)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showResult)
                            
                            // 靜態活動推薦
                            activityRecommendationsView(
                                title: "靜態活動推薦",
                                subtitle: "適合您當前心情的靜心活動",
                                icon: "brain.head.profile",
                                activities: recommendedStaticActivities
                            )
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showResult)
                        }
                        
                        // 筆記和按鈕
                        Group {
                            // 筆記輸入區
                            VStack(alignment: .leading, spacing: 10) {
                                Text("添加筆記")
                                    .font(.system(.headline, design: .rounded))
                                    .padding(.horizontal)
                                
                                TextEditor(text: $notes)
                                    .padding()
                                    .frame(minHeight: 100)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                    .onChange(of: notes) { _, newValue in
                                        // 筆記內容變更時自動保存
                                        saveToJournal()
                                    }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showResult)
                            
                            // 返回按鈕
                            Button(action: {
                                // 在返回前再次保存，確保最新內容已儲存
                                saveToJournal()
                                dismiss()
                            }) {
                                Text("完成並返回")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        ZStack {
                                            LinearGradient(
                                                gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            
                                            // 按鈕光效
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0),
                                                    Color.white.opacity(0.3)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        }
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: showResult)
                        }
                    }
                    .opacity(showTransition ? 0 : 1)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale),
                        removal: .opacity
                    ))
                    .animation(.easeInOut(duration: 0.5), value: showTransition)
                }
            } else {
                questionView
                    .offset(x: slideOffset)
            }
            
            // 轉場動畫
            if showTransition {
                ResultTransitionView(isShowing: $showTransition) {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        showResult = true
                    }
                }
            }
        }
        .onAppear {
            performMoodAnalysis()
        }
        .preferredColorScheme(.light) // 強制使用淺色模式
    }
    
    private var questionView: some View {
        VStack(spacing: 30) {
            // 進度指示器
            ProgressIndicator(totalQuestions: questions.count, currentIndex: currentQuestionIndex)
            
            Spacer()
            
            // 問題卡片 - 添加索引檢查
            if currentQuestionIndex >= 0 && currentQuestionIndex < questions.count {
                QuestionCard(
                    question: questions[currentQuestionIndex],
                    questionIndex: currentQuestionIndex,
                    onOptionSelected: selectAnswer
                )
                .padding(.horizontal)
            } else {
                // 顯示備用視圖，防止索引超出範圍
                Text("加載問題中...")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Spacer()
        }
    }
    
    private var moodResultView: some View {
        let averageScore = Double(moodScore) / Double(questions.count)
        let percentage = Int(averageScore / 4 * 100)
        
        let moodDescription: (String, String, Color) = {
            switch averageScore {
            case 0..<1.5:
                return ("需要關愛", "今天可能有些困難，請善待自己", Color.red.opacity(0.8))
            case 1.5..<2.5:
                return ("心潮微湧", "保持耐心，慢慢調整", Color.orange.opacity(0.8))
            case 2.5..<3.5:
                return ("穩定平衡", "維持現狀，尋找小確幸", Color.yellow.opacity(0.8))
            case 3.5..<4.5:
                return ("積極向上", "保持良好狀態，持續成長", Color.green.opacity(0.8))
            default:
                return ("光芒四射", "分享您的能量，帶動他人", Color.blue.opacity(0.8))
            }
        }()
        
        return VStack(spacing: 15) {
            ZStack {
                // 卡片背景
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                // 內容
                HStack(spacing: 25) {
                    // 環形進度
                    AnimatedMoodRing(percentage: percentage, color: moodDescription.2)
                        .frame(width: 110, height: 110)
                    
                    // 文字說明區
                    VStack(alignment: .leading, spacing: 10) {
                        Text(moodDescription.0)
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(moodDescription.2)
                        
                        Text(moodDescription.1)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 30)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
    }
    
    private func activityRecommendationsView(
        title: String,
        subtitle: String,
        icon: String,
        activities: [String]
    ) -> some View {
        let color: Color = {
            switch title {
            case "動態活動推薦":
                return .green
            case "靜態活動推薦":
                return .blue
            default:
                return .purple
            }
        }()
        
        return ActivityRecommendationGroup(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
            activities: activities
        )
    }
    
    private func selectAnswer(_ index: Int) {
        // 確保 index 在有效範圍內
        let safeIndex = max(0, min(index, 4))
        answers.append(safeIndex)
        moodScore += safeIndex
        
        if currentQuestionIndex < questions.count - 1 {
            // 問題滑動轉場 - 保持一致的向左滑動效果
            withAnimation(.easeInOut(duration: 0.2)) {
                slideOffset = -UIScreen.main.bounds.width
                cardOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 安全地遞增問題索引
                currentQuestionIndex = min(currentQuestionIndex + 1, questions.count - 1)
                
                withAnimation(.easeInOut(duration: 0.01)) {
                    slideOffset = UIScreen.main.bounds.width
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        slideOffset = 0
                        cardOpacity = 1
                    }
                }
            }
        } else {
            // 在顯示結果前先生成活動建議
            recommendedDynamicActivities = getRecommendedDynamicActivities()
            recommendedStaticActivities = getRecommendedStaticActivities()
            
            // 顯示完成動畫
            withAnimation {
                showTransition = true
            }
        }
    }
    
    // 保存評估結果到日記
    private func saveToJournal() {
        let averageScore = Double(moodScore) / Double(questions.count)
        let percentage = Int(averageScore / 4 * 100)
        
        let entry = DiaryEntry(
            date: customDate,  // 使用自定義日期而不是當前日期
            moodScore: moodScore,
            moodPercentage: percentage,
            activities: getAllRecommendedActivities(),
            notes: notes
        )
        
        // 檢查是否已有該日記錄，如果有則更新，否則添加新記錄
        if let existingEntry = diaryManager.getEntryForDate(customDate) {  // 使用自定義日期
            var updatedEntry = existingEntry
            updatedEntry.moodScore = moodScore
            updatedEntry.moodPercentage = percentage
            updatedEntry.activities = getAllRecommendedActivities()
            updatedEntry.notes = notes
            diaryManager.updateEntry(updatedEntry)
        } else {
            diaryManager.addEntry(entry)
        }
    }
    
    // 預先準備分享資源
    private func prepareShareResources() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            preparedImage = createShareImage()
        }
    }
    
    // 創建分享圖片
    private func createShareImage() -> UIImage {
        let averageScore = Double(moodScore) / Double(questions.count)
        let percentage = Int(averageScore / 4 * 100)
        let moodDescription = getMoodDescription(for: percentage)
        
        // 創建分享卡片視圖
        let shareCardView = VStack(spacing: 20) {
            // 標題
            Text("NoEmoVibe 心情追蹤")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 心情結果
            VStack(spacing: 15) {
                // 心情環形圖
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(percentage) / 100)
                        .stroke(moodDescription.2, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 5) {
                        Text("\(percentage)%")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(moodDescription.2)
                        
                        Text("心情指數")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 心情描述
                VStack(spacing: 8) {
                    Text(moodDescription.0)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(moodDescription.2)
                    
                    Text(moodDescription.1)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            // 底部標語
            Text("每一天都是新的開始 🌱")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(30)
        .frame(width: 350, height: 450)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.95, green: 0.97, blue: 1.0),
                            Color(red: 0.9, green: 0.95, blue: 0.98)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        
        return shareCardView.snapshot()
    }
    
    private func performMoodAnalysis() {
        // 實現心情分析的邏輯
    }
}

// 新增 ShareSheet 結構體
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // 排除其他分享選項，保留 Threads 相關
        controller.excludedActivityTypes = [
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .message,
            .mail,
            .print,
            .copyToPasteboard,
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .airDrop,
            .markupAsPDF
        ]
        
        // 設置完成回調
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if let error = error {
                print("分享時發生錯誤：\(error.localizedDescription)")
            }
        }
        
        // 確保在主線程上顯示分享表單
        if let popoverController = controller.popoverPresentationController {
            popoverController.permittedArrowDirections = .any
            popoverController.sourceView = UIView()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct Question {
    let text: String
    let options: [String]
}

// 新增 View 轉 UIImage 的擴充
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        // 設置固定大小，避免 intrinsicContentSize 問題
        let targetSize = CGSize(width: 350, height: 450)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        // 強制佈局更新
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            // 設置白色背景
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            // 繪製視圖
            view?.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
    }
}

#Preview {
    RelaxationView()
        .environmentObject(DiaryManager())
} 
