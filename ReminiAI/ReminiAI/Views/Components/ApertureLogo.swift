import SwiftUI

/// Aperture Brand Mark
/// Minimalist 6-blade camera aperture symbol rendered in SwiftUI shapes
struct ApertureLogo: View {
    var size: CGFloat = 28
    var color: Color = ReminiDesign.primary
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: size * 0.08)
                .frame(width: size, height: size)
            
            // 6 Aperture Blades
            ForEach(0..<6) { index in
                BladeShape()
                    .fill(color)
                    .frame(width: size * 0.38, height: size * 0.08)
                    .offset(x: size * 0.16)
                    .rotationEffect(.degrees(Double(index) * 60.0))
            }
            
            // Inner Aperture Opening
            Circle()
                .fill(ReminiDesign.background)
                .frame(width: size * 0.28, height: size * 0.28)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ReminiAI Aperture Logo")
    }
}

private struct BladeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
