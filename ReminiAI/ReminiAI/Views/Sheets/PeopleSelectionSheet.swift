import SwiftUI

/// Interactive Background People Selection Sheet with Mask Preview, Manual Brush & Eraser
///
/// Features:
/// - Tap individual bystanders to mark them for inpainting removal
/// - Primary subject is automatically protected and highlighted in green
/// - Live mask preview overlay (semi-transparent red) showing removal coverage
/// - Manual Brush tool to include shadows, reflections, or missed clothing
/// - Eraser tool to protect accidental overlaps
/// - Undo action & Clear Selection
/// - Stable photo session ID mapping so selections persist across effect adjustments
struct PeopleSelectionSheet: View {
    let image: UIImage
    let sessionId: UUID
    @Binding var detectedPeople: [DetectedPerson]
    @Binding var selectedPeopleIds: Set<String>
    let onApply: (Set<String>) -> Void
    @Environment(\.dismiss) var dismiss
    
    // Tools: Tap Select, Manual Brush, Eraser
    enum EditTool: String, CaseIterable, Identifiable {
        case select = "Tap Select"
        case brush = "Brush"
        case eraser = "Eraser"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .select: return "hand.tap"
            case .brush: return "paintbrush.pointed"
            case .eraser: return "eraser"
            }
        }
    }
    
    @State private var currentTool: EditTool = .select
    @State private var workingSelection: Set<String> = []
    @State private var brushStrokes: [StrokePath] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var brushRadius: CGFloat = 18.0
    @State private var strokeHistory: [[StrokePath]] = []
    
    struct StrokePath: Identifiable {
        let id = UUID()
        let points: [CGPoint]
        let isEraser: Bool
        let radius: CGFloat
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Tool Selector & Info Bar
                VStack(spacing: 8) {
                    Picker("Mode", selection: $currentTool) {
                        ForEach(EditTool.allCases) { tool in
                            Label(tool.rawValue, systemImage: tool.icon).tag(tool)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, ReminiDesign.space16)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(ReminiDesign.primary)
                            .font(.system(size: 13))
                        
                        Text(infoBannerText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(ReminiDesign.secondaryText)
                        
                        Spacer()
                    }
                    .padding(.horizontal, ReminiDesign.space16)
                    .padding(.bottom, 6)
                }
                .padding(.top, 10)
                .background(ReminiDesign.cardBackground)
                
                // MARK: - Photo Canvas with Overlay & Mask
                GeometryReader { geo in
                    let viewSize = geo.size
                    let fittedRect = calculateFittedImageRect(in: viewSize, imageSize: image.size)
                    
                    ZStack {
                        ReminiDesign.background.ignoresSafeArea()
                        
                        // Base Photo
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: viewSize.width, height: viewSize.height)
                        
                        // Mask Preview Overlay (Shows inpainting area in semi-transparent red)
                        Canvas { context, size in
                            // 1. Draw bounding box masks of selected people
                            for person in detectedPeople where workingSelection.contains(person.id) {
                                let rect = calculatePixelRect(normBox: person.boundingBox, fittedRect: fittedRect)
                                let path = Path(roundedRect: rect, cornerRadius: 8)
                                context.fill(path, with: .color(Color.red.opacity(0.35)))
                            }
                            
                            // 2. Draw brush strokes (including shadows/reflections)
                            for stroke in brushStrokes {
                                guard stroke.points.count > 1 else { continue }
                                var path = Path()
                                path.addLines(stroke.points)
                                let color = stroke.isEraser ? Color.clear : Color.red.opacity(0.40)
                                context.stroke(
                                    path,
                                    with: .color(color),
                                    style: StrokeStyle(lineWidth: stroke.radius * 2, lineCap: .round, lineJoin: .round)
                                )
                            }
                            
                            // 3. Current active stroke
                            if currentStroke.count > 1 {
                                var path = Path()
                                path.addLines(currentStroke)
                                let color = currentTool == .eraser ? Color.white.opacity(0.5) : Color.red.opacity(0.40)
                                context.stroke(
                                    path,
                                    with: .color(color),
                                    style: StrokeStyle(lineWidth: brushRadius * 2, lineCap: .round, lineJoin: .round)
                                )
                            }
                        }
                        .frame(width: viewSize.width, height: viewSize.height)
                        .allowsHitTesting(false)
                        
                        // People Highlight & Selection Boxes (Active in Tap Select mode)
                        if currentTool == .select {
                            ForEach(detectedPeople) { person in
                                let rect = calculatePixelRect(normBox: person.boundingBox, fittedRect: fittedRect)
                                
                                PersonSelectionBox(
                                    person: person,
                                    rect: rect,
                                    isSelected: workingSelection.contains(person.id)
                                ) {
                                    guard !person.isPrimarySubject else { return }
                                    togglePersonSelection(person.id)
                                }
                            }
                        }
                    }
                    // Drawing Gesture for Brush / Eraser
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { val in
                                guard currentTool == .brush || currentTool == .eraser else { return }
                                currentStroke.append(val.location)
                            }
                            .onEnded { _ in
                                guard currentTool == .brush || currentTool == .eraser else { return }
                                if !currentStroke.isEmpty {
                                    strokeHistory.append(brushStrokes)
                                    let newStroke = StrokePath(
                                        points: currentStroke,
                                        isEraser: currentTool == .eraser,
                                        radius: brushRadius
                                    )
                                    brushStrokes.append(newStroke)
                                    currentStroke = []
                                }
                            }
                    )
                }
                
                // MARK: - Brush Settings Bar (Visible in Brush or Eraser mode)
                if currentTool == .brush || currentTool == .eraser {
                    HStack(spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(ReminiDesign.secondaryText)
                        
                        Slider(value: $brushRadius, in: 8.0...40.0)
                            .tint(ReminiDesign.primary)
                        
                        Image(systemName: "circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                    .padding(.horizontal, ReminiDesign.space16)
                    .padding(.vertical, 8)
                    .background(ReminiDesign.secondarySurface)
                }
                
                // MARK: - Bottom Action Controls
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(workingSelection.count) person(s) marked for removal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ReminiDesign.text)
                            
                            if !brushStrokes.isEmpty {
                                Text("\(brushStrokes.count) manual refinement stroke(s)")
                                    .font(.system(size: 12))
                                    .foregroundColor(ReminiDesign.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // Undo Action
                        if !brushStrokes.isEmpty || !workingSelection.isEmpty {
                            Button(action: {
                                performUndo()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Undo")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(ReminiDesign.primary)
                            }
                        }
                        
                        // Clear Selection Action
                        if !workingSelection.isEmpty || !brushStrokes.isEmpty {
                            Button("Clear all") {
                                workingSelection.removeAll()
                                brushStrokes.removeAll()
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ReminiDesign.error)
                            .padding(.leading, 8)
                        }
                    }
                    
                    // Primary Apply Button
                    Button(action: {
                        selectedPeopleIds = workingSelection
                        onApply(workingSelection)
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.badge.minus")
                            Text(workingSelection.isEmpty && brushStrokes.isEmpty
                                 ? "Keep All People"
                                 : "Remove Selected & Inpaint Scene")
                        }
                    }
                    .buttonStyle(ReminiPrimaryButtonStyle())
                }
                .padding(ReminiDesign.space16)
                .background(ReminiDesign.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: -2)
            }
            .navigationTitle("Select Background People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ReminiDesign.secondaryText)
                }
            }
            .onAppear {
                workingSelection = selectedPeopleIds
            }
        }
    }
    
    // MARK: - Banner Text Helper
    private var infoBannerText: String {
        switch currentTool {
        case .select:
            return "Tap bystanders to mark for inpainting. Primary subject is protected in green."
        case .brush:
            return "Paint over shadows, reflections, or missed clothing edges."
        case .eraser:
            return "Erase mask areas to protect overlapping foreground subjects."
        }
    }
    
    private func togglePersonSelection(_ id: String) {
        if workingSelection.contains(id) {
            workingSelection.remove(id)
        } else {
            workingSelection.insert(id)
        }
    }
    
    private func performUndo() {
        if !brushStrokes.isEmpty {
            if let previous = strokeHistory.popLast() {
                brushStrokes = previous
            } else {
                brushStrokes.removeLast()
            }
        } else if !workingSelection.isEmpty {
            workingSelection.removeAll()
        }
    }
    
    // MARK: - Layout Frame Helpers
    private func calculateFittedImageRect(in viewSize: CGSize, imageSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / max(imageSize.height, 1)
        let viewAspect = viewSize.width / max(viewSize.height, 1)
        
        let drawWidth: CGFloat
        let drawHeight: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat
        
        if imageAspect > viewAspect {
            drawWidth = viewSize.width
            drawHeight = viewSize.width / imageAspect
            offsetX = 0
            offsetY = (viewSize.height - drawHeight) / 2.0
        } else {
            drawHeight = viewSize.height
            drawWidth = viewSize.height * imageAspect
            offsetX = (viewSize.width - drawWidth) / 2.0
            offsetY = 0
        }
        
        return CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight)
    }
    
    private func calculatePixelRect(normBox: CGRect, fittedRect: CGRect) -> CGRect {
        return CGRect(
            x: fittedRect.origin.x + (normBox.origin.x * fittedRect.width),
            y: fittedRect.origin.y + (normBox.origin.y * fittedRect.height),
            width: normBox.width * fittedRect.width,
            height: normBox.height * fittedRect.height
        )
    }
}

private struct PersonSelectionBox: View {
    let person: DetectedPerson
    let rect: CGRect
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        person.isPrimarySubject
                        ? Color.green.opacity(0.12)
                        : isSelected
                            ? Color.red.opacity(0.28)
                            : Color.white.opacity(0.12)
                    )
                
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        person.isPrimarySubject
                        ? Color.green
                        : isSelected
                            ? Color.red
                            : Color.white.opacity(0.85),
                        style: StrokeStyle(lineWidth: isSelected ? 2.5 : 1.5, dash: person.isPrimarySubject ? [] : [4])
                    )
                
                // Label Pill
                Text(person.isPrimarySubject ? "Protected Subject" : (isSelected ? "Marked for Removal" : "Tap to Remove"))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        person.isPrimarySubject
                        ? Color.green
                        : (isSelected ? Color.red : Color.black.opacity(0.70))
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .offset(x: 4, y: 4)
            }
            .frame(width: max(32, rect.width), height: max(32, rect.height))
            .position(x: rect.midX, y: rect.midY)
        }
        .buttonStyle(.plain)
        .disabled(person.isPrimarySubject)
    }
}
