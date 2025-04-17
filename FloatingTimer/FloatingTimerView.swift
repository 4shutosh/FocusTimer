import SwiftUI

struct FloatingTimerView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            // Timer title
            Text(timerManager.timerName)
                .font(.headline)
                .padding(.top, 8)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .foregroundColor(timerManager.isPaused ? Color.orange : Color.green)
                        .frame(width: geometry.size.width * (1.0 - timerManager.progress), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
            
            // Timer display
            Text(timerManager.timeString())
                .font(.system(size: 24, weight: .bold, design: .monospaced))
            
            // Control buttons
            HStack {
                Button(action: {
                    timerManager.toggleTimer()
                }) {
                    Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(.borderless)
                
                Button(action: {
                    timerManager.resetTimer()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        opacity = 0.3
                    }
                }) {
                    Image(systemName: "eye.slash")
                }
                .buttonStyle(.borderless)
                
                Button(action: {
                    timerManager.toggleFloatingWindow()
                }) {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 300, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 5)
        )
        .opacity(opacity)
        .onHover { isHovering in
            withAnimation {
                opacity = isHovering ? 1.0 : 0.7
            }
        }
    }
}

#Preview {
    FloatingTimerView(timerManager: TimerManager())
}
