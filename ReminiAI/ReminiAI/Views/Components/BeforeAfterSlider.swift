import SwiftUI

/// Accessible, Gesture-Driven Split Before/After Slider
struct BeforeAfterSlider: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    
    @State private var sliderPosition: CGFloat = 0.50
    @State private var isDragging: Bool = false
    
    // Zoom and Pan
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let splitX = max(0, min(width, width * sliderPosition))
            
            ZStack(alignment: .leading) {
                // Before Image (Original on Right)
                Image(uiImage: beforeImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                
                // After Image (Enhanced on Left)
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: splitX)
                            Spacer(minLength: 0)
                        }
                        .frame(width: width, height: height)
                    )
                
                // Divider Line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2.5)
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 0)
                    .position(x: splitX, y: height / 2)
                
                // Grab Handle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 2)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ReminiDesign.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ReminiDesign.primary)
                    }
                }
                .position(x: splitX, y: height / 2)
                .scaleEffect(isDragging ? 1.15 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isDragging)
                
                // Badges
                VStack {
                    HStack {
                        Text("AFTER")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.92))
                            .foregroundColor(ReminiDesign.primary)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.12), radius: 3)
                            .opacity(sliderPosition > 0.15 ? 1 : 0)
                        
                        Spacer()
                        
                        Text("BEFORE")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .opacity(sliderPosition < 0.85 ? 1 : 0)
                    }
                    .padding(ReminiDesign.space12)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newPos = value.location.x / width
                        sliderPosition = max(0.02, min(0.98, newPos))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .scaleEffect(scale)
            .offset(offset)
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    scale = 1.0
                    offset = .zero
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Before and after comparison slider")
            .accessibilityValue("\(Int(sliderPosition * 100)) percent after")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    sliderPosition = min(1.0, sliderPosition + 0.1)
                case .decrement:
                    sliderPosition = max(0.0, sliderPosition - 0.1)
                @unknown default:
                    break
                }
            }
        }
    }
}
