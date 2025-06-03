import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// 自定義TabBar項目視圖
struct CustomTabItem: View {
    let systemName: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? systemName : systemName.replacingOccurrences(of: ".fill", with: ""))
                .font(.system(size: 24))
                .foregroundStyle(
                    isSelected ? 
                    LinearGradient(
                        colors: [.blue, .purple.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ) : 
                    LinearGradient(
                        colors: [.gray.opacity(0.7), .gray.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 44, height: 44)
                .background(
                    isSelected ? 
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 4)
                        .frame(width: 40, height: 40)
                    : nil
                )
                .overlay(
                    isSelected ? 
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .blue.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                    : nil
                )
                .animation(.spring(response: 0.3), value: isSelected)
        }
        .frame(width: 80)
    }
}

// 添加 View 條件修飾符擴展
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct MainTabView: View {
    @StateObject private var diaryManager = DiaryManager()
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var tabBarVisible = false
    
    init() {
        // 完全隱藏原生標籤欄
        UITabBar.appearance().isHidden = true
        
        // 配置導航欄外觀
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear
        
        // 應用於所有導航欄
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    NoEmoVibeMainView(selectedTab: $selectedTab)
                        .environmentObject(diaryManager)
                        .edgesIgnoringSafeArea(.all)
                        .tag(0)
                    
                    NavigationView {
                        DiaryView()
                            .environmentObject(diaryManager)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .edgesIgnoringSafeArea(.all)
                    .tag(1)
                    
                    NavigationView {
                        MoodAnalysisView()
                            .environmentObject(diaryManager)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .edgesIgnoringSafeArea(.all)
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // 自定義TabBar
                HStack(spacing: 0) {
                    Spacer()
                    
                    CustomTabItem(systemName: "house.fill", isSelected: selectedTab == 0)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                previousTab = selectedTab
                                selectedTab = 0
                            }
                        }
                    
                    Spacer()
                    
                    CustomTabItem(systemName: "book.fill", isSelected: selectedTab == 1)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                previousTab = selectedTab
                                selectedTab = 1
                            }
                        }
                    
                    Spacer()
                    
                    CustomTabItem(systemName: "chart.bar.fill", isSelected: selectedTab == 2)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                previousTab = selectedTab
                                selectedTab = 2
                            }
                        }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        // 背景模糊 - 更輕微的模糊效果和透明度
                        BlurView(style: .systemThinMaterial)
                            .opacity(0.7)
                            .cornerRadius(30)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
                        
                        // 背景漸層
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.05),
                                        Color.black.opacity(0.15)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // 淡化的邊框
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    }
                )
                .offset(y: tabBarVisible ? 0 : 100)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: tabBarVisible)
                .padding(.horizontal, 40)
                .padding(.bottom, 8)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .edgesIgnoringSafeArea(.all)
        .preferredColorScheme(.light)
        .onAppear {
            // 延遲顯示TabBar來創造入場動畫
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    tabBarVisible = true
                }
            }
        }
    }
}

// UIKit 模糊視圖
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        let blurEffect = UIBlurEffect(style: style)
        uiView.effect = blurEffect
    }
}

#Preview {
    MainTabView()
} 