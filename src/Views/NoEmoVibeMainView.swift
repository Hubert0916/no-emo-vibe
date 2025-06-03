import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if os(iOS)
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
    }
}
#endif

// 粒子系統
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var color: Color
}

// 漣漪效果
struct RippleEffect: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.7
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: false)) {
                    scale = 2.0
                    opacity = 0
                }
            }
    }
}

struct NoEmoVibeMainView: View {
    @State private var isRelaxationStarted = false
    @EnvironmentObject var diaryManager: DiaryManager
    
    @Binding var selectedTab: Int
    
    @State private var isHovered = false
    @State private var animatedBackground = false
    @State private var particles: [Particle] = []
    @State private var floatingLeaf = false
    @State private var pulseLeaf = false
    @State private var titleOffset: CGFloat = -50
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    @State private var buttonOpacity: Double = 0
    
    // 建立粒子
    private func setupParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        var newParticles: [Particle] = []
        for _ in 0..<20 {
            let randomX = CGFloat.random(in: 0...screenWidth)
            let randomY = CGFloat.random(in: 0...screenHeight)
            let size = CGFloat.random(in: 3...15)
            let opacity = Double.random(in: 0.2...0.7)
            let speed = Double.random(in: 1.0...3.0)
            
            let colors: [Color] = [.blue, .purple, .green]
            let color = colors.randomElement() ?? .blue
            
            newParticles.append(Particle(position: CGPoint(x: randomX, y: randomY), 
                                        size: size, 
                                        opacity: opacity,
                                        speed: speed,
                                        color: color))
        }
        particles = newParticles
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 複合漸層背景
                ZStack {
                    // 底層漸層
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.2, blue: 0.4),
                            Color(red: 0.2, green: 0.1, blue: 0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                    
                    // 動態漸層疊加
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.2),
                            Color.clear
                        ]),
                        center: animatedBackground ? .topLeading : .bottomTrailing,
                        startRadius: 150,
                        endRadius: 600
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                    .animation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animatedBackground)
                    
                    // 粒子效果
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color.opacity(particle.opacity))
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                            .blur(radius: 1)
                    }
                    
                    // 漣漪效果
                    RippleEffect()
                        .position(x: geometry.size.width * 0.7, 
                                 y: geometry.size.height * 0.2)
                    
                    RippleEffect()
                        .position(x: geometry.size.width * 0.3, 
                                 y: geometry.size.height * 0.7)
                }
                
                VStack(spacing: 30) {
                    // 標題
                    Text("NO EMO")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)
                        .padding(.top, 80)
                    
                    // 歡迎訊息
                    Text("讓我們一起放鬆心情，找回平靜")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        .opacity(subtitleOpacity)
                    
                    Spacer()
                    
                    // 放鬆圖示
                    ZStack {
                        // 背景光暈
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [.green.opacity(0.3), .clear]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 150, height: 150)
                            .scaleEffect(pulseLeaf ? 1.2 : 0.8)
                            .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseLeaf)
                        
                        Image(systemName: "leaf.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                            .rotationEffect(.degrees(floatingLeaf ? 5 : -5))
                            .offset(y: floatingLeaf ? -5 : 5)
                            .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: floatingLeaf)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 開始按鈕
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isRelaxationStarted = true
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "heart.fill")
                                .font(.title2)
                            Text("開始放鬆")
                                .fontWeight(.semibold)
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 30)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                // 主要漸層背景
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.6, blue: 1.0),
                                        Color(red: 0.5, green: 0.4, blue: 0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                // 光暈效果
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 150
                                )
                                
                                // 閃光效果
                                if isHovered {
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .white.opacity(0.2), .clear]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isHovered)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                .blur(radius: 2)
                        )
                        .shadow(color: Color.blue.opacity(0.5), radius: 15, x: 0, y: 10)
                    }
                    .padding(.horizontal, 40)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .scaleEffect(buttonScale)
                    .opacity(buttonOpacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                    #if os(iOS)
                    .pressEvents {
                        // 觸摸開始
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isHovered = true
                        }
                        
                        // 觸覺回饋
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    } onRelease: {
                        // 觸摸結束
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isHovered = false
                        }
                    }
                    #else
                    .onHover { hovering in
                        isHovered = hovering
                    }
                    #endif
                    
                    Spacer()
                        .frame(height: 100)
                }
                .frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .edgesIgnoringSafeArea(.all)
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $isRelaxationStarted) {
            RelaxationView()
                .environmentObject(diaryManager)
                .preferredColorScheme(.light)
        }
        .preferredColorScheme(.light)
        .onAppear {
            // 開始動畫
            withAnimation(.easeInOut(duration: 2)) {
                animatedBackground = true
            }
            
            // 產生粒子
            setupParticles()
            
            // 葉子動畫
            withAnimation(.easeInOut(duration: 1).delay(0.3)) {
                floatingLeaf = true
                pulseLeaf = true
            }
            
            // 標題動畫
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                titleOffset = 0
                titleOpacity = 1
            }
            
            // 副標題動畫
            withAnimation(.easeInOut(duration: 1).delay(0.7)) {
                subtitleOpacity = 1
            }
            
            // 按鈕動畫
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(1.0)) {
                buttonScale = 1.0
                buttonOpacity = 1
            }
        }
    }
}

#Preview {
    NoEmoVibeMainView(selectedTab: .constant(0))
        .environmentObject(DiaryManager())
} 
