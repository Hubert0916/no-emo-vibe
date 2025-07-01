import SwiftUI
import UIKit
import Combine

// MARK: - 鍵盤管理器
class KeyboardManager: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false
    @Published var keyboardAnimationDuration: Double = 0.3
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupKeyboardNotifications()
    }
    
    private func setupKeyboardNotifications() {
        // 鍵盤將要顯示
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> (CGFloat, Double)? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                    return nil
                }
                return (keyboardFrame.height, duration)
            }
            .sink { [weak self] (height, duration) in
                DispatchQueue.main.async {
                    self?.keyboardAnimationDuration = duration
                    withAnimation(.easeInOut(duration: duration)) {
                        self?.keyboardHeight = height
                        self?.isKeyboardVisible = true
                    }
                }
            }
            .store(in: &cancellables)
        
        // 鍵盤將要隱藏
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap { notification -> Double? in
                return notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            }
            .sink { [weak self] duration in
                DispatchQueue.main.async {
                    self?.keyboardAnimationDuration = duration
                    withAnimation(.easeInOut(duration: duration)) {
                        self?.keyboardHeight = 0
                        self?.isKeyboardVisible = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - 智能文字編輯器
struct SmartTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let onTextChange: (() -> Void)?
    
    @State private var isEditing = false
    @FocusState private var isTextEditorFocused: Bool
    @State private var textHeight: CGFloat = 0
    @EnvironmentObject private var keyboardManager: KeyboardManager
    
    init(
        text: Binding<String>,
        placeholder: String = "輸入內容...",
        minHeight: CGFloat = 120,
        onTextChange: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.onTextChange = onTextChange
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 背景與邊框
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEditing ? Color.blue.opacity(0.6) : Color.gray.opacity(0.2), lineWidth: isEditing ? 2 : 1)
                )
            
            // 文字編輯器
            TextEditor(text: $text)
                .font(.system(.body, design: .rounded))
                .focused($isTextEditorFocused)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                .frame(minHeight: max(minHeight, textHeight + 24))
                .onChange(of: text) { _, newValue in
                    // 計算文本高度
                    DispatchQueue.main.async {
                        updateTextHeight()
                    }
                    onTextChange?()
                }
                .onChange(of: isTextEditorFocused) { _, focused in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isEditing = focused
                    }
                    
                    // 當文字框獲得焦點時，觸發滾動
                    if focused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: .textEditorFocused, object: nil)
                        }
                    }
                }
                .onAppear {
                    updateTextHeight()
                }
            
            // 佔位符
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .font(.system(.body, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .onTapGesture {
                        isTextEditorFocused = true
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
    
    private func updateTextHeight() {
        let font = UIFont.systemFont(ofSize: 16)
        let width = UIScreen.main.bounds.width - 80 // 考慮padding和邊距
        let boundingRect = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        textHeight = max(boundingRect.height, minHeight - 24)
    }
}

// MARK: - 改良的鍵盤避讓容器
struct KeyboardAvoidingContainer<Content: View>: View {
    @StateObject private var keyboardManager = KeyboardManager()
    @ViewBuilder let content: Content
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        content
                            .environmentObject(keyboardManager)
                        
                        // 動態底部間距，確保內容不被鍵盤遮擋
                        Spacer()
                            .frame(height: keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight + 100 : 20)
                            .animation(.easeInOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
                    }
                    .frame(minWidth: geometry.size.width)
                }
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            keyboardManager.hideKeyboard()
                        }
                )
                .onReceive(NotificationCenter.default.publisher(for: .textEditorFocused)) { _ in
                    // 當收到文字編輯器獲得焦點的通知時，滾動到錨點
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            scrollProxy.scrollTo("textInputAnchor", anchor: .center)
                        }
                    }
                }
                .onChange(of: keyboardManager.isKeyboardVisible) { _, isVisible in
                    if isVisible {
                        print("鍵盤顯示，嘗試滾動到文字輸入區域")
                        // 當鍵盤顯示時，滾動到錨點位置
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scrollProxy.scrollTo("textInputAnchor", anchor: .center)
                            }
                        }
                    }
                }
                .coordinateSpace(name: "keyboardAvoidingContainer")
            }
        }
    }
}

// MARK: - View 擴展
extension View {
    /// 統一的鍵盤適應功能
    func adaptiveKeyboard() -> some View {
        KeyboardAvoidingContainer {
            self
        }
    }
    
    /// 簡單的鍵盤取消手勢
    func hideKeyboardOnTap() -> some View {
        background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
    
    /// 點擊取消鍵盤（別名）
    func dismissKeyboardOnTap() -> some View {
        hideKeyboardOnTap()
    }
}

// MARK: - 智能鍵盤避讓修飾符
struct SmartKeyboardAvoidingModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager()
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    content
                        .environmentObject(keyboardManager)
                        .padding(.bottom, keyboardManager.keyboardHeight)
                }
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            keyboardManager.hideKeyboard()
                        }
                )
                .onChange(of: keyboardManager.isKeyboardVisible) { _, isVisible in
                    if isVisible {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                scrollProxy.scrollTo("textInputAnchor", anchor: .center)
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
            }
        }
    }
}

// MARK: - 舊版智能鍵盤適應修飾符（已棄用）
struct SmartKeyboardAdaptiveModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager()
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardManager.keyboardHeight)
            .animation(.easeInOut(duration: 0.3), value: keyboardManager.keyboardHeight)
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        keyboardManager.hideKeyboard()
                    }
            )
            .environmentObject(keyboardManager)
    }
}

// MARK: - 浮動工具欄
struct FloatingKeyboardToolbar: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    let onDone: () -> Void
    
    var body: some View {
        if keyboardManager.isKeyboardVisible {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("完成") {
                        onDone()
                        keyboardManager.hideKeyboard()
                    }
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
                .padding()
                .padding(.bottom, max(keyboardManager.keyboardHeight - 50, 20))
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: keyboardManager.isKeyboardVisible)
        }
    }
}

// MARK: - 文字輸入錨點視圖
struct TextInputAnchor: View {
    var body: some View {
        Color.clear
            .frame(height: 1)
            .id("textInputAnchor")
            .onAppear {
                print("TextInputAnchor 已出現，ID: textInputAnchor")
            }
    }
}

// MARK: - 鍵盤錨點視圖（保持向後兼容）
struct KeyboardAnchor: View {
    var body: some View {
        TextInputAnchor()
    }
}

// MARK: - 通知名稱擴展
extension Notification.Name {
    static let textEditorFocused = Notification.Name("textEditorFocused")
} 