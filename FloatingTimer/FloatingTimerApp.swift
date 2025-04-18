//
//  FloatingTimerApp.swift
//  FloatingTimer
//
//  Created by Ashutosh on 17/04/25.
//

import SwiftUI
import AppKit
import CoreText

@main
struct FloatingTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager = TimerManager()
    
    init() {
        // Register custom fonts
        registerFonts()
    }
    
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
    
    // Register the custom fonts
    private func registerFonts() {
        // Font file names
        let fontNames = ["Oxygen-Regular", "Oxygen-Bold", "Oxygen-Light"]
        
        for fontName in fontNames {
            guard let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf"),
                  let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
                  let font = CGFont(fontDataProvider) else {
                print("Failed to load font: \(fontName)")
                continue
            }
            
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterGraphicsFont(font, &error) {
                print("Error registering font: \(fontName)")
            } else {
                print("Successfully registered font: \(fontName)")
            }
        }
    }
}

