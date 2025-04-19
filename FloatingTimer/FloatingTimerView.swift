import SwiftUI
import AppKit

struct FloatingTimerView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var opacity: Double = 1.0
    @State private var showControls: Bool = false
    @State private var animatedBackgroundColor: Color = Color("212121")
    
    private let customGreen = Color("66BB6A")
    private let customRed = Color("EF5350")
  
    private let fontTitle = Font.custom("Oxygen-Regular", size: 24)
    private let fontSubtitle = Font.custom("Oxygen-Light", size: 16)
    
    private let bgColorBlack = Color("212121")
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self._animatedBackgroundColor = State(initialValue: bgColorBlack)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main timer content
            VStack(spacing: 0) {
                ZStack(alignment: .trailing) {
                    // Left side: Text content
                    VStack(spacing: 2) {
                        HStack() {
                            Text(timerManager.timerName.isEmpty ? "write the blog" : timerManager.timerName)
                                .font(fontTitle)
                                .onTapGesture(perform: {
                                    withAnimation {
                                        opacity = 0.3
                                    }
                                })
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.horizontal)
                                .padding(.top, 2)
                                .frame(alignment: .leading)
                            
                            Spacer(minLength: 60) // Ensure space for buttons
                        }
                        
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(formatDisplayTime())
                                .font(fontTitle)
                                .foregroundColor(timerColorState())
                                .lineLimit(1)
                            
                            // Total time in gray
                            Text("/ " + formatTotalTime())
                                .font(fontSubtitle)
                                .foregroundColor(timerManager.isCompleted ? bgColorBlack : .gray)
                                .lineLimit(1)
                            
                            Spacer(minLength: 100) // Ensure space for buttons
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                    // Right side: Control buttons container
                    ZStack {
                        if showControls {
                            HStack(spacing: 0) {
                                // Reset button
                                ButtonControl(action: {
                                    timerManager.resetTimer()
                                }, imageIcon: "arrow.counterclockwise", isCompleted: timerManager.isCompleted)
                                .transition(.opacity)
                                
                                // Close button
                                if !timerManager.isCompleted {
                                    ButtonControl(action: {
                                        timerManager.toggleFloatingWindow()
                                        timerManager.stopTimer()
                                    }, imageIcon: "checkmark", isCompleted: timerManager.isCompleted)
                                    .transition(.opacity)
                                }
                                
                                ButtonControl(action: {
                                    timerManager.toggleFloatingWindow()
                                }, imageIcon: "eye.slash", isCompleted: timerManager.isCompleted)
                                .transition(.opacity)

                                
                                if !timerManager.isCompleted {
                                    ButtonControl(action: {
                                        timerManager.toggleTimer()
                                    }, imageIcon: timerManager.isPaused ? "play" : "pause", isCompleted: timerManager.isCompleted)
                                } else {
                                    ButtonControl(action: {
                                        timerManager.closeFloatingWindow()
                                        timerManager.stopTimer()
                                    }, imageIcon: "checkmark", isCompleted: timerManager.isCompleted)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(getBackgroundColor())
                            )
                        } else {
                            // Only play/pause button when not hovering
                            if !timerManager.isCompleted {
                                ButtonControl(action: {
                                    timerManager.toggleTimer()
                                }, imageIcon: timerManager.isPaused ? "play" : "pause", isCompleted: timerManager.isCompleted)
                            } else {
                                ButtonControl(action: {
                                    timerManager.stopTimer()
                                }, imageIcon: "checkmark", isCompleted: timerManager.isCompleted)
                            }
                        }
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            showControls = hovering
                        }
                    }
                    .padding(.trailing, 10)
                    .zIndex(10) // Ensure buttons are above text
                }.padding(.bottom, 2)
                
                Spacer(minLength: 0)
            }.padding(.bottom, 4)
            
            // Progress bar at bottom
            if !timerManager.isCompleted {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .foregroundColor(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .foregroundColor(progressBarColor())
                            .frame(width: geometry.size.width * (1.0 - timerManager.progress), height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 4)
            }
        }
        .frame(width: 350, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(animatedBackgroundColor)
                .shadow(color: Color.black.opacity(0.2), radius: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(opacity)
        .onHover { isHovering in
            withAnimation {
                opacity = isHovering ? 1.0 : 0.7
            }
        }
        .onChange(of: timerManager.isCompleted) { newValue in
            if newValue {
                // Animate background color to green when timer completes
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedBackgroundColor = getBackgroundColor()
                }
            } else {
                // Reset background color to black when timer is reset
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedBackgroundColor = getBackgroundColor()
                }
            }
        }
        .onChange(of: timerManager.overtimeExceeded) { newValue in
            if newValue {
                // Animate background color to red when overtime exceeds 5 minutes
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedBackgroundColor = getBackgroundColor()
                }
            }
        }
        .onAppear {
            // Set initial background color based on timer state
            animatedBackgroundColor = getBackgroundColor()
        }
    }

    private func getBackgroundColor() -> Color {
        if timerManager.overtimeExceeded {
            return customRed
        } else if timerManager.isCompleted {
            return customGreen
        } else {
            return bgColorBlack
        }
    }
    
    // Helper function to determine timer color state
    private func timerColorState() -> Color {
        if timerManager.isCompleted {
            return bgColorBlack
        } else if timerManager.isPaused {
            return Color("FBC02D")
        } else {
            return customGreen
        }
    }
    
    // Helper function to determine progress bar color
    private func progressBarColor() -> Color {
        if timerManager.isCompleted {
            return customRed
        } else if timerManager.isPaused {
            return Color.orange
        } else {
            return customGreen
        }
    }
    
    // Format display time - uses the right time value based on timer state
    private func formatDisplayTime() -> String {
        let totalSeconds = timerManager.isCompleted ? timerManager.overTimeSeconds : timerManager.remainingSeconds
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
    
    // Format total time hiding zero values
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
}

// Simple inner button control
private struct ButtonControl: View {
    var action: () -> Void
    var imageIcon: String
    var isCompleted: Bool = false
    @State private var isHovering = false
    @Environment(\.colorScheme) var colorScheme
    
    private let grayColor = Color("9E9E9E")
    private let bgColorBlack = Color("212121")
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .padding(.vertical, 8)
                .padding(.leading, 6)
            
            Button(action: action) {
                Image(systemName: imageIcon)
                    .font(.system(size: 18))
                    .foregroundColor(buttonColor())
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderless)
            .padding(.leading, 8)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
        }
    }
    
    private func buttonColor() -> Color {
        if isCompleted {
            return isHovering ? .black : bgColorBlack.opacity(0.8)
        } else {
            return isHovering ? .white : grayColor
        }
    }
}

#Preview {
    FloatingTimerView(timerManager: TimerManager())
}
