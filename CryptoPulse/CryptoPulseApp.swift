//
//  CryptoPulseApp.swift
//  CryptoPulse
//
//  Created by Aнтон Гриц on 9.02.26.
//

import SwiftUI
import UserNotifications

@main
struct CryptoPulseApp: App {
    @StateObject private var appEnv = AppEnvironment()
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .id(appEnv.language)
                .environmentObject(appEnv)
                .preferredColorScheme(appEnv.colorSchemeOverride)
                .environment(\.locale, appEnv.localeOverride ?? Locale.current)
        }
    }
}
