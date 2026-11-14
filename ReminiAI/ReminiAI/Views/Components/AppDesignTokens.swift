import SwiftUI

/// ReminiAI Design Tokens & Metrics
/// Standardized for iOS 16+ (390 × 844 reference layout) and adaptable to Android
enum ReminiDesign {
    // MARK: - Color Tokens
    /// Primary Forest Green: #173D35
    static let primary = Color(hex: 0x173D35)
    
    /// Primary Pressed / Active: #102D27
    static let primaryPressed = Color(hex: 0x102D27)
    
    /// Secondary Surface (Soft Sage Mint): #E4EFE7
    static let secondarySurface = Color(hex: 0xE4EFE7)
    
    /// Background (Warm Off-White): #F8F7F4
    static let background = Color(hex: 0xF8F7F4)
    
    /// Card Surface (Pure White): #FFFFFF
    static let cardBackground = Color(hex: 0xFFFFFF)
    
    /// Text (Deep Spruce / Near Black): #172822
    static let text = Color(hex: 0x172822)
    
    /// Secondary Text (Muted Slate Green): #52625B
    static let secondaryText = Color(hex: 0x52625B)
    
    /// Error Accent: #9D302B
    static let error = Color(hex: 0x9D302B)
    
    /// Divider / Subtle Border
    static let borderSubtle = Color(hex: 0x173D35).opacity(0.08)
    
    // MARK: - Spacing Scale (8px system)
    static let space4: CGFloat = 4
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
    static let space40: CGFloat = 40
    static let space48: CGFloat = 48
    
    // MARK: - Corner Radii
    /// 16px for controls, cards, tiles, and text inputs
    static let corner16: CGFloat = 16
    
    /// 24px for the hero featured card
    static let corner24: CGFloat = 24
    
    // MARK: - Shadows
    /// Featured card: 0 4px 16px rgba(23, 40, 34, 0.08)
    static let featuredCardShadowColor = Color(hex: 0x172822).opacity(0.08)
    static let featuredCardShadowRadius: CGFloat = 16
    static let featuredCardShadowY: CGFloat = 4
    
    // MARK: - Minimum Touch Target
    /// Apple Human Interface Guidelines minimum touch target
    static let minTouchTarget: CGFloat = 44
}

// MARK: - Hex Color Helper
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Typography (Inter design metrics)
extension Font {
    /// Title: 28/34 semibold
    static let reminiTitle = Font.system(size: 28, weight: .semibold, design: .default)
    
    /// Section title: 20/28 semibold
    static let reminiSection = Font.system(size: 20, weight: .semibold, design: .default)
    
    /// Body: 16/24 regular
    static let reminiBody = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Button: 16/24 semibold
    static let reminiButton = Font.system(size: 16, weight: .semibold, design: .default)
    
    /// Tab label: 14/20 medium
    static let reminiTabLabel = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Caption / Subtitle: 12/16 regular
    static let reminiCaption = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Micro Badge: 10/14 bold
    static let reminiBadge = Font.system(size: 10, weight: .bold, design: .default)
}

// MARK: - Custom Button Styles
struct ReminiPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.reminiButton)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: ReminiDesign.minTouchTarget + 6)
            .background(
                RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                    .fill(
                        !isEnabled
                        ? ReminiDesign.secondaryText.opacity(0.4)
                        : configuration.isPressed
                            ? ReminiDesign.primaryPressed
                            : ReminiDesign.primary
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ReminiSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.reminiButton)
            .foregroundColor(ReminiDesign.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: ReminiDesign.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                    .fill(
                        configuration.isPressed
                        ? ReminiDesign.secondarySurface.opacity(0.7)
                        : ReminiDesign.secondarySurface
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
