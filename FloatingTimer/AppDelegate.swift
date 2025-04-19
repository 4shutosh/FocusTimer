import SwiftUI
import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}

// Extension to provide menu dismissal functionality
extension NSMenu {
    static func dismissActiveMenu() {
        NSApp.mainMenu?.cancelTracking()
        NSApp.windows.forEach { window in
            if window.className.contains("MenuBarExtraWindow") {
                window.close()
            }
        }
    }
}
