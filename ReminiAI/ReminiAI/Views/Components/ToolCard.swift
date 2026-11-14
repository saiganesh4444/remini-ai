import SwiftUI

/// 2-Column Grid Tool Tile
struct ToolCard: View {
    let mode: EnhancementMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: ReminiDesign.space8) {
                // Top row: Icon & Selection indicator
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? ReminiDesign.primary : ReminiDesign.secondarySurface)
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: mode.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : ReminiDesign.primary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(ReminiDesign.primary)
                    } else if let badge = mode.badgeText {
                        Text(badge)
                            .font(.reminiBadge)
                            .foregroundColor(ReminiDesign.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ReminiDesign.background)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer(minLength: 2)
                
                // Title
                Text(mode.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ReminiDesign.text)
                    .lineLimit(1)
                
                // Description
                Text(mode.shortDescription)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(ReminiDesign.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ReminiDesign.space12)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                    .fill(isSelected ? ReminiDesign.secondarySurface.opacity(0.4) : ReminiDesign.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                    .stroke(
                        isSelected ? ReminiDesign.primary : ReminiDesign.borderSubtle,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.rawValue), \(mode.shortDescription)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}
