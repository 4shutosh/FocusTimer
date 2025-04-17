//
//  TimerManager.swift
//  FloatingTimer
//
//  Created by Ashutosh on 17/04/25.
//

import Foundation
import SwiftUI
import AppKit
import UserNotifications

class TimerManager: ObservableObject {
    @Published var timerName: String = ""
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var showFloatingTimer: Bool = false
    
    private var timer: Timer?
    private var floatingWindow: NSWindow?
    
    var progress: Double {
        if totalSeconds == 0 { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }
    
    func startNewTimer(name: String, minutes: Int) {
        stopTimer()
        
        timerName = name
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        isRunning = true
        isPaused = false
        showFloatingTimer = true
        
        print("Starting timer and showing floating window")
        startTimer()
        
        // Create the window directly
        createAndShowFloatingWindow()
    }
    
    func toggleTimer() {
        if isPaused {
            resumeTimer()
        } else {
            pauseTimer()
        }
    }
    
    func pauseTimer() {
        timer?.invalidate()
        isPaused = true
    }
    
    func resumeTimer() {
        isPaused = false
        startTimer()
    }
    
    func resetTimer() {
        remainingSeconds = totalSeconds
        if !isPaused {
            startTimer()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        isRunning = false
        isPaused = false
        remainingSeconds = 0
    }
    
    private func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.timerCompleted()
            }
        }
    }
    
    private func timerCompleted() {
        stopTimer()
        showNotification()
    }
    
    private func showNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "\"\(timerName)\" has finished"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func timeString() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func shortTimeString() -> String {
        let minutes = remainingSeconds / 60
        return "\(minutes)m"
    }
    
    // Handle floating window
    func toggleFloatingWindow() {
        print("Toggle floating window called")
        showFloatingTimer.toggle()
        
        if showFloatingTimer {
            print("Showing floating window")
            createAndShowFloatingWindow()
        } else {
            print("Hiding floating window")
            closeFloatingWindow()
        }
    }
    
    func createAndShowFloatingWindow() {
        print("Creating floating window programmatically")
        
        // Close existing window if it exists
        closeFloatingWindow()
        
        // Create the hosting controller with our SwiftUI view
        let hostingController = NSHostingController(
            rootView: FloatingTimerView(timerManager: self)
        )
        
        // Create a window to host our view
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        
        // Position near the menu bar
        if let screenFrame = NSScreen.main?.visibleFrame {
            window.setFrameOrigin(NSPoint(
                x: screenFrame.maxX - 320,
                y: screenFrame.maxY - 120
            ))
        } else {
            window.center()
        }
        
        // Set window level to float above other windows
        window.level = .floating
        
        // Make window movable by dragging anywhere
        window.isMovableByWindowBackground = true
        
        // Show the window
        window.orderFront(nil)
        
        // Store reference to window
        self.floatingWindow = window
        
        print("Window created and should be visible")
    }
    
    func closeFloatingWindow() {
        if let window = floatingWindow {
            print("Closing existing floating window")
            window.close()
            floatingWindow = nil
        }
    }
}
