import SwiftUI

extension Color {
    // MARK: - VoltLoop Color Palette
    static let voltLoopBlack = Color(red: 0.02, green: 0, blue: 0) // #050000
    static let voltLoopWhite = Color.white // #FFFFFF
    static let voltLoopBlue = Color(red: 0.43, green: 0.62, blue: 0.77) // #6e9ec4
    static let voltLoopOrange = Color(red: 1.0, green: 0.22, blue: 0) // #ff3700
    static let voltLoopYellow = Color(red: 0.996, green: 0.894, blue: 0.639) // #fee4a3
    
    // MARK: - Semantic Colors
    static let primaryText = voltLoopWhite
    static let secondaryText = voltLoopWhite.opacity(0.7)
    static let accentColor = voltLoopBlue
    static let warningColor = voltLoopOrange
    static let successColor = Color.green
    static let errorColor = voltLoopOrange
    
    // MARK: - Background Colors
    static let primaryBackground = voltLoopBlack
    static let secondaryBackground = voltLoopBlack.opacity(0.8)
    static let cardBackground = voltLoopBlack.opacity(0.6)
    
    // MARK: - Border Colors
    static let primaryBorder = voltLoopBlue
    static let secondaryBorder = voltLoopWhite.opacity(0.3)
    
    // MARK: - Glow Colors
    static let blueGlow = voltLoopBlue.opacity(0.3)
    static let orangeGlow = voltLoopOrange.opacity(0.3)
    static let yellowGlow = voltLoopYellow.opacity(0.3)
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let voltLoopGradient = LinearGradient(
        colors: [Color.voltLoopBlack, Color.voltLoopBlue.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let blueGlowGradient = LinearGradient(
        colors: [Color.voltLoopBlue.opacity(0.2), Color.clear],
        startPoint: .center,
        endPoint: .bottom
    )
    
    static let orangeGlowGradient = LinearGradient(
        colors: [Color.voltLoopOrange.opacity(0.2), Color.clear],
        startPoint: .center,
        endPoint: .bottom
    )
}

// MARK: - Shadow Extensions
extension View {
    func voltLoopGlow(color: Color = .voltLoopBlue, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
    }
    
    func voltLoopCardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primaryBorder.opacity(0.3), lineWidth: 1)
            )
            .voltLoopGlow()
    }
    
    func voltLoopButtonStyle(isPrimary: Bool = true) -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                isPrimary ? Color.clear : Color.voltLoopWhite
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.voltLoopWhite, lineWidth: 1)
            )
            .foregroundColor(isPrimary ? Color.voltLoopWhite : Color.voltLoopBlack)
            .font(.system(size: 16, weight: .medium, design: .default))
            .cornerRadius(14)
    }
} 