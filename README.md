# ReminiAI — Native Mobile Photo Editor

**ReminiAI** is a mobile photo editor built for people who want to clean up portraits and everyday photos while preserving natural skin texture, color, and detail.

Designed with a clean, premium light aesthetic using a 390 × 844 reference layout (iOS 16+ on iPhone 13, and adaptable to Android).

---

## ✨ Features & Architecture

### 1. Natural Enhancement Defaults
* **Natural Enhance (Default):** Uses gentle denoising and mild sharpening (`CINoiseReduction` + `CIUnsharpMask`) to clear sensor grain while preserving organic skin texture, pore integrity, and eye reflections. Avoids blanket brightness, contrast, or saturation boosts.
* **HD Upscale:** Doubles pixel dimensions on-device using high-precision Lanczos resampling (`CILanczosScaleTransform`, 2× scale) with mild luminance crispness. Keeps export dimensions completely accurate (2× width, 2× height).
* **Soft Sharpen:** Restrained local edge definition without harsh ringing or white halos.
* **Vintage Tone:** Infuses subtle warm analog coloration into midtones while protecting skin tones and highlights.
* **Portrait Blur:** Normalizes orientation first, then employs subject segmentation (`VNGeneratePersonSegmentationRequest` on iOS 15+) to protect hair, clothing, and shoulders. Falls back to multi-face protected elliptical blur. Returns the original untouched if no subjects are detected.

### 2. Result Comparison & Strength Slider
* **Strength Slider (0% to 100%):** Real-time alpha blending between the original and processed image. Zero shows the original appearance; full strength shows the complete processed output.
* **Pixel-Aligned Comparison for Upscaled Photos:** When comparing or blending 2× HD Upscale photos, the original is automatically resampled to the exact same dimensions as the processed photo, ensuring zero misalignment, shift, or scale jump.
* **Export Consistency:** The selected strength is directly baked into the final saved or shared photo.

### 3. Home Screen & 5-Tab Navigation
* **Design System Tokens:**
  - Primary / Pressed: `#173D35` / `#102D27` (Deep Forest Green)
  - Secondary Surface: `#E4EFE7` (Soft Sage Mint)
  - Background / Cards: `#F8F7F4` / `#FFFFFF`
  - Text / Secondary Text: `#172822` / `#52625B`
  - Error: `#9D302B`
  - Spacing: 8 px scale, 16 px side margins, 8 px grid gaps
  - Corners: 16 px for controls/tiles, 24 px for featured card
* **Header:** Aperture logo brand mark, ReminiAI wordmark, and Profile button opening settings.
* **Search Tools Field:** Instant local filter with clear button and a dedicated "No tools found" state.
* **Featured Card:** 24 px rounded card featuring Natural Enhance with an interactive, draggable Before/After slider.
* **2-Column Tool Grid:** Direct selection of HD Upscale, Soft Sharpen, Vintage Tone, and Portrait Blur.
* **5 Tabs:**
  1. **Home:** Main discovery dashboard and tool grid.
  2. **Search:** Dedicated search screen with tool descriptions and direct photo import.
  3. **Add:** Action dialog offering Photos or Camera.
  4. **Activity:** History of recent edits with thumbnails, dates, strength, and dimensions. Includes an empty state with a "Choose photo" button.
  5. **Profile:** Settings, engine selector, and security controls.

### 4. Processing Engines & Security
* **On-Device Neural Engine (Default):** Runs 100% locally on the iPhone 13's Apple A15 Bionic 16-Core Neural Engine via CoreImage and Vision. Private, offline, instant.
* **Cloud AI (Replicate):**
  - GFPGAN v1.4 for Natural Enhance.
  - Real-ESRGAN for HD Upscale (face enhancement disabled by default).
  - Unsupported tools (Soft Sharpen, Vintage Tone, Portrait Blur) provide a clear "Switch to On-Device" action dialog.
* **Keychain Storage:** Replicate API tokens are encrypted in the iOS Keychain (`kSecClassGenericPassword`), never in cleartext.
* **Race Condition Protection:** Concurrency tracking using unique job IDs prevents late results from older jobs from overwriting the current photo.

---

## 📁 Repository Structure

```
ReminiAI/
├── .github/
│   └── workflows/
│       └── build-ios.yml             # GitHub Actions automated build
├── ReminiAI/
│   ├── App/
│   │   └── ReminiAIApp.swift         # App entry point (Light theme default)
│   ├── Models/
│   │   ├── EnhancementMode.swift     # Natural Enhance, HD Upscale, etc.
│   │   ├── EnhancementJob.swift      # Job state tracking
│   │   └── ActivityItem.swift        # Recent edits model
│   ├── Services/
│   │   ├── ImageEnhancerService.swift# CoreImage, Vision, & Lanczos engine
│   │   ├── CloudAIService.swift      # Replicate GFPGAN/Real-ESRGAN API
│   │   ├── KeychainManager.swift     # Secure token Keychain storage
│   │   ├── ActivityHistoryManager.swift # Recent edits storage
│   │   └── PhotoLibraryManager.swift # Camera roll saving & permissions
│   ├── ViewModels/
│   │   └── EnhanceViewModel.swift    # Reactive MVVM controller
│   ├── Views/
│   │   ├── HomeView.swift            # Aperture logo, search, featured card
│   │   ├── ComparisonView.swift      # Before/After slider & Strength slider
│   │   ├── ProcessingView.swift      # Precision scanline indicator
│   │   ├── SettingsView.swift        # Engine selector & Keychain token
│   │   ├── Tabs/
│   │   │   ├── MainTabView.swift     # 5-tab root container
│   │   │   ├── SearchView.swift      # Tool search & empty state
│   │   │   └── ActivityView.swift    # Recent edits & history
│   │   └── Components/
│   │       ├── AppDesignTokens.swift # Design tokens & Inter typography
│   │       ├── ApertureLogo.swift    # 6-blade aperture brand mark
│   │       ├── FeaturedToolCard.swift# 24px corner interactive featured card
│   │       ├── ToolCard.swift        # 2-column grid tiles
│   │       └── BeforeAfterSlider.swift# Accessible Before/After split slider
│   └── Resources/
│       └── Info.plist                # Privacy descriptions & bundle identifier
├── ANDROID_GUIDANCE.md               # Jetpack Compose & Material 3 specification
└── README.md                         # Project documentation
```

---

## 🚀 Installation & Build

### Option 1: GitHub Actions (Automated Cloud Build)
The workflow `.github/workflows/build-ios.yml` compiles the app using Apple's official `xcrun swiftc` compiler on `macos-15` runners whenever code is pushed or a pull request is opened.
* The build output produces an unsigned `ReminiAI.ipa` artifact.
* **Important:** Because Apple requires all apps installed on physical iOS devices to carry a personal or developer provisioning profile, the unsigned IPA must be signed with your Apple ID using **Sideloadly**, **AltStore**, or **Xcode** before it can execute on a physical iPhone.

### Option 2: Sideloading onto iPhone 13 via USB
1. Download **[Sideloadly for Windows or Mac](https://sideloadly.io/)**.
2. Connect your iPhone 13 via USB.
3. Drag & drop `ReminiAI.ipa` into Sideloadly, enter your Apple ID, and click **Start**.
4. On your iPhone: **Settings > General > VPN & Device Management > Trust Developer**.
5. Enable Developer Mode under **Settings > Privacy & Security > Developer Mode** and restart.

### Option 3: Local Mac Build via Xcode
1. Open the project in Xcode 15+.
2. Connect your iPhone 13 and select your personal team under **Signing & Capabilities**.
3. Press **Cmd + R** to run.
