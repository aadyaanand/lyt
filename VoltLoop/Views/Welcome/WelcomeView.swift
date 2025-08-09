import SwiftUI
import AVKit

struct WelcomeView: View {
    @Binding var isShowingWelcome: Bool
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var isVideoPlaying = false
    
    var body: some View {
        ZStack {
            // Video Background
            VideoBackgroundView()
                .ignoresSafeArea()
            
            // Overlay gradient
            LinearGradient(
                colors: [
                    Color.voltLoopBlack.opacity(0.7),
                    Color.voltLoopBlack.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                VStack(spacing: 20) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.voltLoopWhite)
                        .voltLoopGlow(color: .voltLoopBlue, radius: 20)
                        .opacity(logoOpacity)
                        .scaleEffect(logoOpacity)
                    
                    Text("VoltLoop")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundColor(.voltLoopWhite)
                        .voltLoopGlow(color: .voltLoopBlue, radius: 15)
                        .opacity(logoOpacity)
                }
                
                // Tagline
                Text("Your smart, personal energy companion.")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundColor(.voltLoopWhite.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(taglineOpacity)
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowingWelcome = false
                    }
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                }
                .voltLoopButtonStyle()
                .opacity(buttonOpacity)
                .scaleEffect(buttonOpacity)
                
                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
            logoOpacity = 1.0
        }
        
        // Tagline animation
        withAnimation(.easeInOut(duration: 0.8).delay(1.2)) {
            taglineOpacity = 1.0
        }
        
        // Button animation
        withAnimation(.easeInOut(duration: 0.6).delay(1.8)) {
            buttonOpacity = 1.0
        }
    }
}

struct VideoBackgroundView: View {
    var body: some View {
        ZStack {
            // Fallback gradient background
            LinearGradient(
                colors: [
                    Color.voltLoopBlack,
                    Color.voltLoopBlue.opacity(0.1),
                    Color.voltLoopBlack
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated cityscape elements
            CityscapeView()
        }
    }
}

struct CityscapeView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Building silhouettes
                ForEach(0..<8, id: \.self) { index in
                    BuildingView(index: index, offset: animationOffset)
                }
                
                // Orange lights
                ForEach(0..<12, id: \.self) { index in
                    LightView(index: index, offset: animationOffset)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animationOffset = 100
            }
        }
    }
}

struct BuildingView: View {
    let index: Int
    let offset: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(Color.voltLoopBlack.opacity(0.8))
            .frame(width: CGFloat.random(in: 20...60), height: CGFloat.random(in: 100...300))
            .offset(x: CGFloat(index * 50) + offset, y: 0)
            .position(x: CGFloat(index * 50) + offset, y: 400)
    }
}

struct LightView: View {
    let index: Int
    let offset: CGFloat
    @State private var isGlowing = false
    
    var body: some View {
        Circle()
            .fill(Color.voltLoopOrange)
            .frame(width: 8, height: 8)
            .voltLoopGlow(color: .voltLoopOrange, radius: 15)
            .offset(x: CGFloat(index * 40) + offset, y: 0)
            .position(x: CGFloat(index * 40) + offset, y: CGFloat.random(in: 200...350))
            .opacity(isGlowing ? 1.0 : 0.6)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isGlowing.toggle()
                }
            }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(isShowingWelcome: .constant(true))
    }
} 