//
//  no_emo_vibeApp.swift
//  no-emo-vibe
//
//  Created by 邱宇涵 on 2025/5/21.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct NoEmoVibeApp: App {
    init() {
        #if canImport(UIKit)
        // 強制使用淺色模式，不支援深色模式
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = .light
        }
        
        // 配置全局導航欄樣式
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear
        
        // 設置所有導航欄樣式
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // 隱藏所有標籤欄
        UITabBar.appearance().isHidden = true
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
                .preferredColorScheme(.light) // 強制使用淺色模式
        }
    }
}
