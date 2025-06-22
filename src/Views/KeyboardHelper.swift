import SwiftUI
import UIKit
import Combine

// MARK: - 鍵盤管理器
class KeyboardManager: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupKeyboardNotifications()
    }
    
    private func setupKeyboardNotifications() {
        // 鍵盤將要顯示
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return keyboardFrame.height
            }
            .sink { [weak self] height in
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.keyboardHeight = height
                        self?.isKeyboardVisible = true
                    }
                }
            }
            .store(in: &cancellables)
        
        // 鍵盤將要隱藏
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
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
            
            // 文字編輯器（始終存在）
            TextEditor(text: $text)
                .font(.system(.body, design: .rounded))
                .focused($isTextEditorFocused)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                .frame(minHeight: minHeight)
                .onChange(of: text) { _, _ in
                    onTextChange?()
                }
                .onChange(of: isTextEditorFocused) { _, focused in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = focused
                    }
                }
            
            // 佔位符
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .font(.system(.body, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .onTapGesture {
                        isTextEditorFocused = true
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}

// MARK: - 鍵盤避讓容器
struct KeyboardAvoidingContainer<Content: View>: View {
    @StateObject private var keyboardManager = KeyboardManager()
    @ViewBuilder let content: Content
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    content
                        .padding(.bottom, keyboardManager.isKeyboardVisible ? 20 : 0)
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
                        // 當鍵盤顯示時，稍微延遲後滾動到底部
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .environmentObject(keyboardManager)
    }
}

// MARK: - View 擴展
extension View {
    /// 為視圖添加鍵盤避讓功能
    func keyboardAvoiding() -> some View {
        KeyboardAvoidingContainer {
            self
        }
    }
    
    /// 簡單的鍵盤取消手勢
    func hideKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// 點擊取消鍵盤（別名）
    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// 智能鍵盤適應（包含避讓和取消功能）
    func smartKeyboardAdaptive() -> some View {
        modifier(SmartKeyboardAdaptiveModifier())
    }
}

// MARK: - 智能鍵盤適應修飾符
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
                .padding(.bottom, keyboardManager.keyboardHeight - 50)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: keyboardManager.isKeyboardVisible)
        }
    }
} 