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
import AVFoundation

class TimerManager: ObservableObject {
    @Published var timerName: String = ""
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var showFloatingTimer: Bool = false
    @Published var isCompleted: Bool = false
    @Published var overTimeSeconds: Int = 0
    @Published var overtimeExceeded: Bool = false
    
    private var timer: Timer?
    private var overtimeTimer: Timer?
    private var floatingWindow: NSWindow?
    private var player: AVAudioPlayer?
    
    private let timerOvertimeThreshold = 300 // 5 minutes in seconds
    
    var progress: Double {
        if totalSeconds == 0 { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }
    
    func startNewTimer(name: String, minutes: Int) {
        // Validate that the timer is not more than 4 hours (240 minutes)
        let validMinutes = min(minutes, 240)
        
        stopTimer()
        
        // Enforce maximum length for timer name (50 characters)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        timerName = trimmedName.count > 50 ? String(trimmedName.prefix(50)) : trimmedName
        
        totalSeconds = validMinutes * 60
        remainingSeconds = totalSeconds
        overTimeSeconds = 0
        isRunning = true
        isPaused = false
        isCompleted = false
        overtimeExceeded = false
        showFloatingTimer = true
        
        print("Starting timer and showing floating window")
        startTimer()
        
        // Create the window directly
        createAndShowFloatingWindow()
    }
    
    func startNewTimerAndCloseMenu(name: String, minutes: Int) {
        // Start timer as usual
        startNewTimer(name: name, minutes: minutes)
        
        // Dismiss the menu
        NSMenu.dismissActiveMenu()
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
        overTimeSeconds = 0
        isCompleted = false
        overtimeExceeded = false
        
        overtimeTimer?.invalidate()
        overtimeTimer = nil
        
        player?.stop()
        if !isPaused {
            startTimer()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        overtimeTimer?.invalidate()
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        overTimeSeconds = 0
        isCompleted = false
        overtimeExceeded = false
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
    
    private func startOvertimeTimer() {
        overtimeTimer?.invalidate()
        
        overtimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.overTimeSeconds += 1
            
            // Check if overtime reached 5 minutes (totalSeconds + 5 minutes in seconds)
            if !self.overtimeExceeded && 
               (self.overTimeSeconds - self.totalSeconds) >= self.timerOvertimeThreshold {
                self.overtimeExceeded = true
                self.playGongSound()
            }
        }
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        isRunning = false
        isPaused = false
        isCompleted = true
        overTimeSeconds = totalSeconds
        overtimeExceeded = false
        
        // Start counting overtime
        startOvertimeTimer()
        
        playGongSound()
        showNotification()
    }
    
    private func playGongSound() {
        // First try to load from bundle
        if let soundURL = Bundle.main.url(forResource: "gong", withExtension: "mp3") {
            playSound(from: soundURL)
            return
        }
        
        // If not in bundle, try to load from the Resources directory
        let resourcesPath = Bundle.main.bundlePath + "/Resources/gong.mp3"
        if FileManager.default.fileExists(atPath: resourcesPath) {
            playSound(from: URL(fileURLWithPath: resourcesPath))
            return
        }
        
        // If not found, try to load from a fixed URL as fallback
        if let url = URL(string: "https://freesound.org/data/previews/41/41169_187255-lq.mp3") {
            // Download and play
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, 
                      let data = data, 
                      error == nil else {
                    print("Failed to download sound: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                
                // Create a temporary file
                let tempDir = FileManager.default.temporaryDirectory
                let tempFile = tempDir.appendingPathComponent("gong.mp3")
                
                do {
                    try data.write(to: tempFile)
                    self.playSound(from: tempFile)
                } catch {
                    print("Failed to write temp file: \(error)")
                }
            }
            task.resume()
        } else {
            print("Could not create URL for gong sound")
        }
    }
    
    private func playSound(from url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Could not play sound: \(error)")
        }
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
        let totalSeconds = remainingSeconds
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        var result = ""
        
        if hours > 0 {
            result += "\(hours)h "
        }
        
        if minutes > 0 || (hours > 0 && seconds > 0) {
            result += "\(minutes)m "
        }
        
        if seconds > 0 || totalSeconds == 0 {
            result += "\(seconds)s"
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    func menuBarTimeString() -> String {
        if isCompleted {
            let minutes = overTimeSeconds / 60
            let seconds = overTimeSeconds % 60
            
            // If overtime is more than a minute
            if minutes > 0 {
                let hours = minutes / 60
                let mins = minutes % 60
                
                if hours > 0 {
                    // Format as "Xh Ym"
                    return String(format: "+%dh %dm", hours, mins)
                } else {
                    // Just show minutes
                    return String(format: "+%dm", mins)
                }
            } else {
                // For less than a minute, show seconds
                return String(format: "+%ds", seconds)
            }
        } else {
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            
            // If time is more than a minute, exclude seconds
            if minutes > 0 {
                let hours = minutes / 60
                let mins = minutes % 60
                
                if hours > 0 {
                    // Format as "Xh Ym"
                    return String(format: "%dh %dm", hours, mins)
                } else {
                    // Just show minutes
                    return String(format: "%dm", mins)
                }
            } else {
                // For less than a minute, show seconds
                return String(format: "%ds", seconds)
            }
        }
    }
    
    // Handle floating window
    func toggleFloatingWindow() {
        showFloatingTimer.toggle()
        
        if showFloatingTimer {
            createAndShowFloatingWindow()
        } else {
            closeFloatingWindow()
        }
    }
    
    func createAndShowFloatingWindow() {
        
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
    }
    
    func closeFloatingWindow() {
        if let window = floatingWindow {
            window.close()
            floatingWindow = nil
        }
        if isCompleted {
            player?.stop()
        }
    }
}
