# Remini AI — Native iPhone 13 Photo Enhancer

A complete, high-performance reconstruction of the **Remini AI Photo Enhancer** designed specifically for **iPhone 13** (Apple A15 Bionic Neural Engine).

---

## ✨ Features Reconstructed

1. **Remini Signature Before / After Split Slider:**
   - Real-time interactive vertical divider bar with gesture dragging and haptics.
   - Dynamic badges (`BEFORE` / `AFTER`).
   - Synced zoom & pan across both uncompressed layers.
   - Double-tap to reset zoom.

2. **Laser Scanning Animation:**
   - Glowing neon laser scanline that travels up and down the input photo during inference.
   - Dynamic stage notifications (*"Detecting facial landmarks...", "De-noising sensor grain...", "Restoring skin micro-textures..."*).
   - Real-time progress bar.

3. **Multi-Mode Enhancement Engine:**
   - **Face Enhance:** Recovers facial micro-details, skin pores, and eye clarity via Vision & unsharp bilateral filtering.
   - **HD 4x Upscale:** High-precision Lanczos scale transform + luminance edge enhancement.
   - **Unblur & Sharpen:** Corrects camera shake and motion blur.
   - **Vintage Colorize:** Restores saturation and tonal balance to old black-and-white photos.
   - **Portrait Depth:** Renders synthetic background bokeh defocus around subjects.

4. **Dual Execution Engine:**
   - **On-Device Engine (Default):** Runs 100% offline and privately on the iPhone 13's 16-core Apple Neural Engine & Metal 3 GPU via CoreImage and Vision. Zero API keys or cloud subscriptions needed.
   - **Cloud Neural Engine:** Plug-and-play integration with server-grade AI models (GFPGAN / CodeFormer / Real-ESRGAN via Replicate API) configurable in Settings.

5. **Direct Photos & Camera Integration:**
   - Native `PhotosPicker` and Camera capture.
   - 1-click Save to Camera Roll via `Photos` framework.
   - Native iOS Share Sheet (`UIActivityViewController`).

---

## 📁 Project Structure

```
ReminiAI/
├── ReminiAI.xcodeproj/
│   └── project.pbxproj               # Xcode project configuration
├── Package.swift                     # Swift Package Manager manifest
├── ReminiAI/
│   ├── App/
│   │   └── ReminiAIApp.swift         # App entry point
│   ├── Models/
│   │   ├── EnhancementMode.swift     # Modes (Enhance, 4x Upscale, Deblur, etc.)
│   │   └── EnhancementJob.swift      # Processing job state
│   ├── Services/
│   │   ├── ImageEnhancerService.swift # On-Device Metal/Vision/CoreImage pipeline
│   │   ├── CloudAIService.swift      # Cloud GFPGAN/CodeFormer/Real-ESRGAN API
│   │   └── PhotoLibraryManager.swift # Photos framework saving & permissions
│   ├── ViewModels/
│   │   └── EnhanceViewModel.swift    # App state & MVVM reactive controller
│   ├── Views/
│   │   ├── HomeView.swift            # Main dashboard & photo picker
│   │   ├── ProcessingView.swift      # Remini laser scanner screen
│   │   ├── ComparisonView.swift      # Before/After split comparison screen
│   │   ├── SettingsView.swift        # Neural engine & API key configuration
│   │   └── Components/
│   │       ├── BeforeAfterSlider.swift # Draggable split comparison slider
│   │       └── ToolCard.swift          # Enhancement mode selector cards
│   └── Resources/
│       └── Info.plist                # Camera & Photos privacy permissions
```

---

## 🚀 How to Run on your iPhone 13

### Option 1: Run with Mac & Xcode (Recommended)
1. Transfer the `ReminiAI` folder to your Mac (or open via shared drive / git).
2. Double-click `ReminiAI.xcodeproj` to open it in **Xcode**.
3. Plug in your **iPhone 13** with a USB-C / Lightning cable.
4. In Xcode:
   - Select your iPhone 13 in the target device selector (top bar).
   - In **Signing & Capabilities**, select your free Apple ID under **Team**.
   - Press **Cmd + R** (or click ▶ **Run**).
5. On your iPhone 13, go to **Settings > General > VPN & Device Management** and trust your Developer App certificate.
6. Launch **Remini AI** on your iPhone!

### Option 2: Sideloading without Mac (Sideloadly / AltStore)
If you build an `.ipa` from the project or export an archive, you can sideload it directly onto your iPhone 13 using **Sideloadly** or **AltStore** on Windows.
