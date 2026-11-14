import SwiftUI

/// Interactive Background People Selection Sheet
///
/// Allows user to review detected people, protects the primary subject by default,
/// highlights selected background individuals, and allows user to tap to select/unselect.
struct PeopleSelectionSheet: View {
    let image: UIImage
    @Binding var detectedPeople: [DetectedPerson]
    @Binding var selectedPeopleIds: Set<UUID>
    let onApply: (Set<UUID>) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var workingSelection: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info Banner
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(ReminiDesign.primary)
                    Text("Tap background people to select them for removal. Your primary subject is protected.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                .padding(ReminiDesign.space12)
                .frame(maxWidth: .infinity)
                .background(ReminiDesign.secondarySurface.opacity(0.6))
                
                // Photo Canvas with People Bounding Boxes
                GeometryReader { geo in
                    let size = geo.size
                    
                    ZStack {
                        ReminiDesign.background.ignoresSafeArea()
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size.width, height: size.height)
                        
                        // People Bounding Boxes Overlay
                        ForEach(detectedPeople) { person in
                            let rect = calculatePixelRect(normBox: person.boundingBox, in: size, imageSize: image.size)
                            
                            PersonHighlightBox(
                                person: person,
                                rect: rect,
                                isSelected: workingSelection.contains(person.id)
                            ) {
                                if !person.isPrimarySubject {
                                    if workingSelection.contains(person.id) {
                                        workingSelection.remove(person.id)
                                    } else {
                                        workingSelection.insert(person.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom Action Bar
                VStack(spacing: 12) {
                    HStack {
                        Text("\(workingSelection.count) person(s) selected for removal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ReminiDesign.text)
                        
                        Spacer()
                        
                        if !workingSelection.isEmpty {
                            Button("Undo selection") {
                                workingSelection.removeAll()
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ReminiDesign.error)
                        }
                    }
                    
                    Button(action: {
                        selectedPeopleIds = workingSelection
                        onApply(workingSelection)
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.badge.minus")
                            Text(workingSelection.isEmpty ? "Keep All People" : "Remove \(workingSelection.count) Selected")
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
    
    private func calculatePixelRect(normBox: CGRect, in viewSize: CGSize, imageSize: CGSize) -> CGRect {
        // Calculate aspect fit image frame within viewSize
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
        
        return CGRect(
            x: offsetX + (normBox.origin.x * drawWidth),
            y: offsetY + (normBox.origin.y * drawHeight),
            width: normBox.width * drawWidth,
            height: normBox.height * drawHeight
        )
    }
}

private struct PersonHighlightBox: View {
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
                            : Color.white.opacity(0.10)
                    )
                
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        person.isPrimarySubject
                        ? Color.green
                        : isSelected
                            ? Color.red
                            : Color.white.opacity(0.85),
                        style: StrokeStyle(lineWidth: isSelected ? 2.5 : 1.5, dash: person.isPrimarySubject ? [] : [5])
                    )
                
                // Label Pill
                Text(person.isPrimarySubject ? "Protected Subject" : (isSelected ? "Selected" : "Tap to Remove"))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        person.isPrimarySubject
                        ? Color.green
                        : (isSelected ? Color.red : Color.black.opacity(0.7))
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .offset(x: 4, y: 4)
            }
            .frame(width: max(24, rect.width), height: max(24, rect.height))
            .position(x: rect.midX, y: rect.midY)
        }
        .buttonStyle(.plain)
        .disabled(person.isPrimarySubject)
    }
}
