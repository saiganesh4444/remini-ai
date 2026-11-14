import SwiftUI

struct ToolCard: View {
    let mode: EnhancementMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected
                            ? LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: mode.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .blue.opacity(0.9))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(mode.rawValue)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let badge = mode.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badge == "POPULAR" ? Color.pink : Color.indigo)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(mode.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
                    .font(.system(size: isSelected ? 18 : 13))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue.opacity(0.8) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
