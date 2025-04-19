//
//  FloatingTimerApp.swift
//  FloatingTimer
//
//  Created by Ashutosh on 17/04/25.
//

import SwiftUI
import AppKit
import CoreText
import AVFoundation

@main
struct FloatingTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager = TimerManager()
    
    init() {
        // Register custom fonts
        registerFonts()
        // Check if gong sound exists and log if not found
        if Bundle.main.url(forResource: "gong", withExtension: "mp3") == nil {
            print("WARNING: Gong sound file not found in bundle")
        }
    }
    
    var body: some Scene {
        // This makes it a menu bar app
        MenuBarExtra {
            MenuBarView(timerManager: timerManager)
        } label: {
            if timerManager.isRunning && !timerManager.showFloatingTimer {
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
        
        Settings {
            EmptyView()
        }
    }
    
    // Register the custom fonts
    private func registerFonts() {
        // Font file names
        let fontNames = ["Oxygen-Regular", "Oxygen-Bold", "Oxygen-Light"]
        
        for fontName in fontNames {
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf"),
               let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
               let font = CGFont(fontDataProvider) {
                
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterGraphicsFont(font, &error)
            }
        }
    }
}

