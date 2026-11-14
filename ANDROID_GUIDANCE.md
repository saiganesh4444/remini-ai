# ReminiAI — Android Layout & Interaction Guidance

This specification defines how the **ReminiAI** design system and architecture (originally prototyped for iOS 16+ on an iPhone 13 390 × 844 pt reference viewport) translate natively to **Android 13+ (API 33+)** using **Jetpack Compose**, **Material 3**, and modern Android graphics APIs.

---

## 1. Viewport & Density Translation

| Metric | iOS (iPhone 13 Reference) | Android Translation | Notes |
| :--- | :--- | :--- | :--- |
| **Reference Viewport** | 390 × 844 pt | 390 × 844 dp (`sw390dp`) | Standard modern Android aspect (~19.5:9 to 20:9) |
| **Minimum Touch Target** | 44 × 44 pt | **48 × 48 dp** | Material Design Accessibility requirement |
| **Side Margins** | 16 pt | 16 dp | Outer padding for standard phone form factors |
| **Grid Spacing** | 8 pt | 8 dp | 8-dp layout grid scale |
| **Corner Radius (Tiles/Inputs)** | 16 pt | 16 dp (`RoundedCornerShape(16.dp)`) | Cards, input fields, and buttons |
| **Corner Radius (Featured Card)** | 24 pt | 24 dp (`RoundedCornerShape(24.dp)`) | Featured interactive card |
| **Typography Scale** | Points (pt) | Scaled Pixels (sp) | Respects Android system font scaling |

---

## 2. Design Tokens in Jetpack Compose

```kotlin
package com.saiganesh.reminiai.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.TextStyle

object ReminiTokens {
    // Colors
    val Primary = Color(0xFF173D35)            // Deep Forest Green
    val PrimaryPressed = Color(0xFF102D27)     // Pressed/Active Forest
    val SecondarySurface = Color(0xFFE4EFE7)   // Soft Sage Mint
    val Background = Color(0xFFF8F7F4)         // Warm Off-White
    val CardBackground = Color(0xFFFFFFFF)     // Pure White
    val Text = Color(0xFF172822)               // Deep Spruce
    val SecondaryText = Color(0xFF52625B)      // Muted Slate Green
    val Error = Color(0xFF9D302B)              // Error Red
    val BorderSubtle = Color(0x14173D35)       // 8% Forest border

    // Spacing
    val Space4 = 4.dp
    val Space8 = 8.dp
    val Space12 = 12.dp
    val Space16 = 16.dp
    val Space24 = 24.dp
    val Space32 = 32.dp

    // Touch Targets
    val MinTouchTarget = 48.dp

    // Corner Radii
    val Corner16 = 16.dp
    val Corner24 = 24.dp
}

// Typography (Inter)
val InterFontFamily = FontFamily(
    Font(R.font.inter_regular, FontWeight.Normal),
    Font(R.font.inter_medium, FontWeight.Medium),
    Font(R.font.inter_semibold, FontWeight.SemiBold),
    Font(R.font.inter_bold, FontWeight.Bold)
)

object ReminiTypography {
    val Title = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 28.sp,
        lineHeight = 34.sp,
        color = ReminiTokens.Text
    )
    val SectionTitle = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        lineHeight = 28.sp,
        color = ReminiTokens.Text
    )
    val Body = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        color = ReminiTokens.Text
    )
    val Button = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        color = Color.White
    )
    val TabLabel = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp
    )
    val Caption = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        color = ReminiTokens.SecondaryText
    )
}
```

---

## 3. Screen Structure & Layout Hierarchy

### A. NavigationBar & Bottom Tabs
On Android, use a custom `NavigationBar` with Material 3 styling:
* **Tabs:** Home, Search, Add (Raised FAB/Circle), Activity, Profile.
* **Active Pill Indicator:** Wrap the active tab item in a capsule shape with background `ReminiTokens.SecondarySurface`.
* **Add Action:** Use a center Floating Action Button (`48 × 48 dp` minimum) that triggers a modal `ModalBottomSheet` offering:
  1. *Choose from Photos* (`PickVisualMedia` contract)
  2. *Take Photo* (CameraX intent)

### B. Interactive Before/After Split Slider
In Compose, implement the split slider using `BoxWithConstraints` and `Modifier.pointerInput(Unit)`:
```kotlin
@Composable
fun BeforeAfterSlider(
    beforeBitmap: ImageBitmap,
    afterBitmap: ImageBitmap,
    modifier: Modifier = Modifier
) {
    var splitFraction by remember { mutableStateOf(0.5f) }

    BoxWithConstraints(modifier = modifier) {
        val widthPx = constraints.maxWidth.toFloat()
        val splitX = widthPx * splitFraction

        // Layer 1: Before Image
        Image(
            bitmap = beforeBitmap,
            contentDescription = "Original photo",
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Fit
        )

        // Layer 2: After Image (clipped to splitX)
        Image(
            bitmap = afterBitmap,
            contentDescription = "Enhanced photo",
            modifier = Modifier
                .fillMaxSize()
                .drawWithContent {
                    clipRect(right = splitX) {
                        this@drawWithContent.drawContent()
                    }
                },
            contentScale = ContentScale.Fit
        )

        // Draggable Handle
        Box(
            modifier = Modifier
                .offset { IntOffset(splitX.toInt() - 24.dp.roundToPx(), (constraints.maxHeight / 2) - 24.dp.roundToPx()) }
                .size(48.dp)
                .background(Color.White, CircleShape)
                .pointerInput(Unit) {
                    detectDragGestures { change, dragAmount ->
                        change.consume()
                        splitFraction = (splitFraction + dragAmount.x / widthPx).coerceIn(0.02f, 0.98f)
                    }
                }
                .semantics {
                    contentDescription = "Before and after comparison slider"
                    stateDescription = "${(splitFraction * 100).toInt()}% after"
                }
        )
    }
}
```

---

## 4. Android Image Processing Pipeline

### A. On-Device Neural Engine & DSP Alternatives
On iOS, ReminiAI utilizes Apple's CoreImage and Vision frameworks. On Android, implement the corresponding native stack:

1. **Orientation Normalization:**
   Read EXIF orientation via `androidx.exifinterface.media.ExifInterface` and normalize the bitmap using a `Matrix().postRotate(...)` transform before passing to inference.
2. **Natural Enhance:**
   - Bilateral noise reduction via RenderEffect or OpenCV Android `Imgproc.bilateralFilter()`.
   - Gentle unsharp mask via custom Vulkan compute shader or RenderEffect `createBlurEffect` subtraction.
3. **HD Upscale (2×):**
   - High-quality bicubic/Lanczos scaling via `Bitmap.createScaledBitmap(src, w * 2, h * 2, true)` or OpenCV `Imgproc.INTER_LANCZOS4`.
   - Luminance sharpening filter pass.
4. **Portrait Blur (Subject & Multi-Face Aware):**
   - **Subject Segmentation:** Use **Google ML Kit Selfie Segmentation** (`SegmenterOptions.STREAM_MODE` or `SINGLE_IMAGE_MODE`) to generate an 8-bit alpha mask protecting the person (hair, clothing, shoulders).
   - **Multi-Face Fallback:** Use **Google ML Kit Face Detection** (`FaceDetectorOptions`) to locate all bounding boxes and generate radial protection discs.
   - **Blur:** On Android 12+ (API 31+), apply `RenderEffect.createBlurEffect(16f, 16f, Shader.TileMode.CLAMP)`. On older versions, use a dual-pass script or GPUImage.
   - **Empty Check:** If zero subjects or faces are detected, return the original image untouched.

---

## 5. Security & Credential Storage

On Android, never store the Replicate API token in cleartext `SharedPreferences`. Use the **Android Keystore** with **EncryptedSharedPreferences**:

```kotlin
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys

val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
val securePrefs = EncryptedSharedPreferences.create(
    "remini_secure_prefs",
    masterKeyAlias,
    context,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

fun saveReplicateToken(token: String) {
    securePrefs.edit().putString("replicate_api_token", token).apply()
}

fun getReplicateToken(): String? {
    return securePrefs.getString("replicate_api_token", null)
}
```

---

## 6. Accessibility & TalkBack Guidance

1. **Touch Targets:**
   All buttons, tabs, slider handles, and icon actions must enforce `Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)`.
2. **TalkBack Semantics:**
   - Every interactive control must have an explicit `contentDescription`.
   - The comparison slider must expose `semantics { customActions = listOf(...) }` so TalkBack users can increment and decrement the split position with volume keys or accessibility swipes.
   - The strength slider must report state updates: *"Enhancement strength: 75 percent"*.
3. **Contrast & Focus:**
   - Text (`#172822`) on Background (`#F8F7F4`) provides a contrast ratio of **12.4:1**, far exceeding WCAG AAA (7:1).
   - Secondary Text (`#52625B`) on Background (`#F8F7F4`) provides a contrast ratio of **5.3:1**, exceeding WCAG AA (4.5:1).
   - Keyboard navigation on Android TV or ChromeOS/Foldables must display a `2.dp` border outline using `ReminiTokens.Primary`.
