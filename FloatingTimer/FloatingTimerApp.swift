//
//  FloatingTimerApp.swift
//  FloatingTimer
//
//  Created by Ashutosh on 17/04/25.
//

import SwiftUI
import AppKit

@main
struct FloatingTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager = TimerManager()
    
    var body: some Scene {
        // This makes it a menu bar app
        MenuBarExtra {
            MenuBarView(timerManager: timerManager)
        } label: {
            if timerManager.isRunning {
                // Show timer indicator when running
                HStack(spacing: 2) {
                    Image(systemName: "timer")
                    Text(timerManager.shortTimeString())
                        .font(.system(size: 10, weight: .medium))
                }
            } else {
                Image(systemName: "timer")
            }
        }
        .menuBarExtraStyle(.window)
        
        // We'll handle window creation manually rather than using WindowGroup
        Settings {
            EmptyView()
        }
    }
}

