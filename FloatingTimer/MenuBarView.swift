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
    @State private var newTimerName: String = "Focus Time"
    @State private var newTimerDuration: Int = 25 // 25 minutes
    @AppStorage("savedTimers") private var savedTimersData: Data = Data()
    
    private var savedTimers: [SavedTimer] {
        (try? JSONDecoder().decode([SavedTimer].self, from: savedTimersData)) ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Timer")
                .font(.headline)
                .padding(.horizontal)
                .foregroundColor(timerManager.isRunning ? .secondary : .primary)
            
            HStack {
                FocusedTextField(
                    text: $newTimerName,
                    placeholder: "Timer Name",
                    shouldBecomeFirstResponder: !timerManager.isRunning
                )
                .frame(minWidth: 130, idealWidth: 150, maxWidth: .infinity)
                
                Picker("", selection: $newTimerDuration) {
                    Text("5m").tag(5)
                    Text("10m").tag(10)
                    Text("15m").tag(15)
                    Text("25m").tag(25)
                    Text("30m").tag(30)
                    Text("45m").tag(45)
                    Text("60m").tag(60)
                }
                .pickerStyle(.menu)
                .frame(width: 65)
                .clipped()
                
                Button("Start") {
                    timerManager.startNewTimer(name: newTimerName, minutes: newTimerDuration)
                }
                .frame(width: 55)
            }
            .disabled(timerManager.isRunning)
            .padding(.horizontal)
            .opacity(timerManager.isRunning ? 0.6 : 1.0)
            
            Divider()
            
            // Current timer status
            if timerManager.isRunning {
                HStack {
                    Text(timerManager.timerName)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(timerManager.timerName)
                    Spacer()
                    Text(timerManager.timeString())
                        .monospacedDigit()
                        .foregroundColor(.green)
                    
                    Button(action: {
                        timerManager.toggleTimer()
                    }) {
                        Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {
                        print("Floating window button clicked")
                        timerManager.toggleFloatingWindow()
                    }) {
                        Image(systemName: timerManager.showFloatingTimer ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {
                        timerManager.stopTimer()
                    }) {
                        Image(systemName: "xmark.circle")
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
                    Button(action: {
                        PreferencesWindowController.showWindow()
                    }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Edit saved timers")
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(savedTimers) { timer in
                            HStack {
                                Text(timer.name)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .help(timer.name)
                                Spacer()
                                Text("\(timer.minutes)m")
                                    .foregroundColor(.secondary)
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
                .disabled(newTimerName.isEmpty || timerManager.isRunning)
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
        // Avoid duplicates
        if !timers.contains(where: { $0.name == newTimerName && $0.minutes == newTimerDuration }) {
            let newSavedTimer = SavedTimer(id: UUID(), name: newTimerName, minutes: newTimerDuration)
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
