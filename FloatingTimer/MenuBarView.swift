//
//  MenuBarView.swift
//  FloatingTimer
//
//  Created by Ashutosh on 17/04/25.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var newTimerName: String = "do the thing"
    @State private var newTimerDuration: Int = 25
    @State private var hours: String = "0"
    @State private var minutes: String = "25"
    @AppStorage("savedTimers") private var savedTimersData: Data = Data()
    
    // Define custom fonts to match FloatingTimerView
    private let fontTitle = Font.custom("Oxygen-Regular", size: 14)
    private let fontSubtitle = Font.custom("Oxygen-Light", size: 12)
    private let customGreen = Color("66BB6A")
    
    // Maximum length for timer name
    private let maxTimerNameLength = 50
    
    private var savedTimers: [SavedTimer] {
        (try? JSONDecoder().decode([SavedTimer].self, from: savedTimersData)) ?? []
    }
    
    // Calculate total minutes while enforcing limits (max 4 hours)
    private var totalMinutes: Int {
        let hoursVal = Int(hours) ?? 0
        let minutesVal = Int(minutes) ?? 0
        
        // Convert to total minutes
        let total = (hoursVal * 60) + minutesVal
        
        // Enforce limits (max 4 hours = 240 minutes)
        return min(max(total, 0), 240)
    }
    
    // Check if the entered time exceeds the limit
    private var exceedsTimeLimit: Bool {
        let hoursVal = Int(hours) ?? 0
        let minutesVal = Int(minutes) ?? 0
        
        // Calculate total minutes without capping
        let total = (hoursVal * 60) + minutesVal
        
        return total > 240
    }
    
    // Format time like in FloatingTimerView
    private func formatCurrentTime() -> String {
        let totalSeconds = timerManager.remainingSeconds
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
    
    // Format total time like in FloatingTimerView
    private func formatTotalTime() -> String {
        let totalSeconds = timerManager.totalSeconds
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        var result = ""
        
        if hours > 0 {
            result += "\(hours)h "
        }
        
        if minutes > 0 || totalSeconds == 0 {
            result += "\(minutes)m"
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Timer")
                .font(.headline)
                .padding(.horizontal)
                .foregroundColor(timerManager.isRunning ? .secondary : .primary)
            
            // Timer name and time input
            VStack(spacing: 8) {
                FocusedTextField(
                    text: $newTimerName,
                    placeholder: "Timer Name",
                    shouldBecomeFirstResponder: !timerManager.isRunning
                )
                .frame(minWidth: 130, idealWidth: 150, maxWidth: .infinity)
                .onChange(of: newTimerName) { newValue in
                    if newValue.count > maxTimerNameLength {
                        newTimerName = String(newValue.prefix(maxTimerNameLength))
                    }
                }
                
                // Time input with hours and minutes
                HStack {
                    // Hours input
                    TextField("0", text: $hours)
                        .frame(width: 40)
                        .multilineTextAlignment(.trailing)
                        .cornerRadius(8)
                        .foregroundColor(exceedsTimeLimit ? .red : .primary)
                        .onChange(of: hours) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                hours = filtered
                            }
                            // Update newTimerDuration when hours change
                            newTimerDuration = totalMinutes
                        }
                    Text("h")
                        .foregroundColor(exceedsTimeLimit ? .red : .secondary)
                    
                    // Minutes input
                    TextField("25", text: $minutes)
                        .frame(width: 40)
                        .multilineTextAlignment(.trailing)
                        .cornerRadius(8)
                        .foregroundColor(exceedsTimeLimit ? .red : .primary)
                        .onChange(of: minutes) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                minutes = filtered
                            }
                            // Update newTimerDuration when minutes change
                            newTimerDuration = totalMinutes
                        }
                    Text("m")
                        .foregroundColor(exceedsTimeLimit ? .red : .secondary)
                    
                    Spacer()
                    
                    Button("Start") {
                        timerManager.startNewTimer(name: newTimerName, minutes: totalMinutes)
                    }
                    .frame(width: 55)
                    .disabled(totalMinutes <= 0)
                }
                
                // Helper text for limits
                Text(exceedsTimeLimit ? "You cannot focus for more than 4 hours, keep your sessions as short and clear as possible" : "Maximum 4 hours")
                    .font(.caption)
                    .foregroundColor(exceedsTimeLimit ? .orange : .secondary)
            }
            .disabled(timerManager.isRunning)
            .padding(.horizontal)
            .opacity(timerManager.isRunning ? 0.6 : 1.0)
            
            Divider()
            
            // Current timer status - only show when timer is running AND floating window is not visible
            if timerManager.isRunning && !timerManager.showFloatingTimer {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timerManager.timerName.isEmpty ? "focus" : timerManager.timerName)
                            .font(fontTitle)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .help(timerManager.timerName.isEmpty ? "focus" : timerManager.timerName)
                        
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(timerManager.shortTimeString())
                                .font(fontTitle)
                                .foregroundColor(timerManager.isPaused ? Color.orange : customGreen)
                                .lineLimit(1)
                            
                            // Total time in gray
                            Text("/ " + formatTotalTime())
                                .font(fontSubtitle)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            timerManager.toggleTimer()
                        }) {
                            Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            timerManager.toggleFloatingWindow()
                        }) {
                            Image(systemName: timerManager.showFloatingTimer ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle")
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            timerManager.closeFloatingWindow()
                            timerManager.stopTimer()
                        }) {
                            Image(systemName: "xmark.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal)
                
                Divider()
            } else if timerManager.isRunning {
                // Show minimal info if timer is running but floating window is visible
                HStack {
                    Text("Timer is running in floating window")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        timerManager.toggleFloatingWindow()
                    }) {
                        Image(systemName: "rectangle.on.rectangle.slash")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                
                Divider()
            }
            
            // Saved timers section
            if !savedTimers.isEmpty {
                HStack {
                    Text("Saved Timers")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(savedTimers) { timer in
                            HStack {
                                Text(timer.name.isEmpty ? "focus" : timer.name)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .help(timer.name)
                                Spacer()
                                
                                // Format time display to match the style
                                if timer.minutes >= 60 {
                                    Text("\(timer.minutes / 60)h \(timer.minutes % 60)m")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("\(timer.minutes)m")
                                        .foregroundColor(.secondary)
                                }
                                
                                Button("Start") {
                                    timerManager.startNewTimer(name: timer.name, minutes: timer.minutes)
                                }
                                .buttonStyle(.borderless)
                                .disabled(timerManager.isRunning)
                                Button(action: {
                                    deleteTimer(id: timer.id)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.red)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !timerManager.isRunning {
                                    timerManager.startNewTimer(name: timer.name, minutes: timer.minutes)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 150)
                
                Divider()
            }
            
            // Save current timer settings
            if !newTimerName.isEmpty {
                Button("Save This Timer") {
                    saveTimer()
                }
                .disabled(newTimerName.isEmpty || timerManager.isRunning || totalMinutes <= 0)
                .padding(.horizontal)
                
                Divider()
            }
            
            // App controls
            HStack {
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .frame(width: 300)
    }
    
    private func saveTimer() {
        var timers = savedTimers
        // Trim name and ensure it's not too long
        let trimmedName = newTimerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let validName = trimmedName.count > maxTimerNameLength ? String(trimmedName.prefix(maxTimerNameLength)) : trimmedName
        
        // Avoid duplicates and ensure timer is valid
        if !timers.contains(where: { $0.name == validName && $0.minutes == newTimerDuration }) && totalMinutes > 0 {
            let newSavedTimer = SavedTimer(id: UUID(), name: validName, minutes: newTimerDuration)
            timers.append(newSavedTimer)
            if let encoded = try? JSONEncoder().encode(timers) {
                savedTimersData = encoded
            }
        }
    }
    
    private func deleteTimer(id: UUID) {
        var timers = savedTimers
        timers.removeAll { $0.id == id }
        if let encoded = try? JSONEncoder().encode(timers) {
            savedTimersData = encoded
        }
    }
}
