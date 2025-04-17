//
//  PreferencesView.swift
//  FloatingTimer
//
//  Created by Ashutosh on 17/04/25.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage("savedTimers") private var savedTimersData: Data = Data()
    @Environment(\.dismiss) private var dismiss
    
    private var savedTimers: [SavedTimer] {
        (try? JSONDecoder().decode([SavedTimer].self, from: savedTimersData)) ?? []
    }
    
    private func updateSavedTimers(_ timers: [SavedTimer]) {
        if let encoded = try? JSONEncoder().encode(timers) {
            savedTimersData = encoded
        }
    }
    
    var body: some View {
        VStack {
            Text("Preferences")
                .font(.largeTitle)
                .padding(.top)
            
            Divider()
            
            // Saved timers management section
            VStack(alignment: .leading) {
                Text("Saved Timers")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                if savedTimers.isEmpty {
                    Text("No saved timers")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(savedTimers) { timer in
                            HStack {
                                Text(timer.name)
                                Spacer()
                                Text("\(timer.minutes)m")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            var timers = savedTimers
                            timers.remove(atOffsets: indexSet)
                            updateSavedTimers(timers)
                        }
                    }
                    .frame(minHeight: 150, maxHeight: 200)
                }
            }
            .padding()
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .padding(.bottom)
        }
        .frame(width: 400, height: 300)
    }
}

struct PreferencesWindowController {
    static var windowController: NSWindowController?
    
    static func showWindow() {
        if windowController == nil {
            let hostingController = NSHostingController(
                rootView: PreferencesView()
            )
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "Preferences"
            window.contentViewController = hostingController
            window.center()
            
            windowController = NSWindowController(window: window)
        }
        
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
} 