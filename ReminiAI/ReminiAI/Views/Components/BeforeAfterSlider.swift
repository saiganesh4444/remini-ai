import SwiftUI

struct BeforeAfterSlider: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    
    @State private var sliderPosition: CGFloat = 0.5 // 0.0 (all before) to 1.0 (all after)
    @State private var isDragging: Bool = false
    
    // Zoom and Pan state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let splitX = width * sliderPosition
            
            ZStack(alignment: .leading) {
                // Background Layer: Before Image (Original)
                Image(uiImage: beforeImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                
                // Foreground Layer: After Image (Enhanced) masked by split line
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: max(0, splitX))
                            Spacer(minLength: 0)
                        }
                        .frame(width: width, height: height)
                    )
                
                // Vertical Divider Line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2.5)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 0)
                    .position(x: splitX, y: height / 2)
                
                // Circular Grab Handle in the Center
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .position(x: splitX, y: height / 2)
                .scaleEffect(isDragging ? 1.15 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
                
                // Badges: "AFTER" on Left side of divider, "BEFORE" on Right side of divider
                VStack {
                    HStack {
                        // After badge
                        Text("AFTER")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            .foregroundColor(.white)
                            .opacity(sliderPosition > 0.15 ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: sliderPosition)
                        
                        Spacer()
                        
                        // Before badge
                        Text("BEFORE")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(sliderPosition < 0.85 ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: sliderPosition)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            // Gesture handling for the split slider
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newPos = value.location.x / width
                        sliderPosition = min(max(newPos, 0.0), 1.0)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .scaleEffect(scale)
            .offset(offset)
            // Double tap to reset zoom
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    scale = 1.0
                    offset = .zero
                }
            }
        }
    }
}
