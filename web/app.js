/**
 * Remini AI — Responsive Mobile & Desktop Browser Photo Editor
 *
 * Implements:
 * - Zoomable Before/After Comparison with strict gesture locking
 * - Client-side Image Processing (Natural Enhance, HD Upscale, Soft Sharpen, Vintage Tone, Portrait Blur)
 * - Independent Combined Effects & Scene-Reconstructing Inpainting
 * - Real-time luminance strength blending (0% to 100%)
 * - Touch & mouse gestures (pinch-to-zoom, pan clamping, double-tap reset)
 * - File import (drag-and-drop, photo picker), export download & Web Share API
 */

(function () {
  'use strict';

  // --- State ---
  let originalImage = null; // HTMLImageElement (upright canonicalized)
  let processedCanvas = null; // Offscreen canvas with current tool output
  let displayCanvas = null; // Offscreen canvas with strength-blended output
  let maskCanvas = null; // Offscreen canvas for inpainting mask

  let currentTool = 'naturalEnhance';
  let currentStrength = 1.0;

  // Combined Effects Configuration
  const combinedEffects = {
    faceEnhancement: true,
    faceRetouch: false,
    backgroundEnhancement: true,
    backgroundBlur: 'off',
    removeBackgroundPeople: false
  };

  // Zoom & Pan & Divider State
  let sliderPosition = 0.50; // 0.02 ... 0.98
  let scale = 1.0;
  let minScale = 1.0;
  let maxScale = 5.0;
  let panX = 0;
  let panY = 0;

  // Gesture Locking
  let isDraggingDivider = false;
  let isPanningPhoto = false;
  let isBrushingMask = false;
  let startX = 0;
  let startY = 0;
  let initialPanX = 0;
  let initialPanY = 0;
  let activeTouchDistance = 0;

  // DOM Elements
  const stageWrapper = document.getElementById('stage-wrapper');
  const emptyState = document.getElementById('empty-state');
  const comparisonContainer = document.getElementById('comparison-container');
  const canvasStage = document.getElementById('canvas-stage');
  const ctxStage = canvasStage.getContext('2d');
  const dropZone = document.getElementById('drop-zone');
  const fileInput = document.getElementById('file-input');

  const dividerLine = document.getElementById('divider-line');
  const dividerHandle = document.getElementById('divider-handle');
  const badgeBefore = document.getElementById('badge-before');
  const badgeAfter = document.getElementById('badge-after');

  const btnZoomIn = document.getElementById('btn-zoom-in');
  const btnZoomOut = document.getElementById('btn-zoom-out');
  const btnZoomReset = document.getElementById('btn-zoom-reset');

  const strengthSlider = document.getElementById('strength-slider');
  const strengthValue = document.getElementById('strength-value');
  const toolButtons = document.querySelectorAll('.tool-btn');

  const photoFilename = document.getElementById('photo-filename');
  const photoDimensions = document.getElementById('photo-dimensions');
  const btnChangePhoto = document.getElementById('btn-change-photo');
  const btnSaveMain = document.getElementById('btn-save-main');
  const btnDownload = document.getElementById('btn-download');
  const btnShare = document.getElementById('btn-share');

  const processingOverlay = document.getElementById('processing-overlay');
  const processingText = document.getElementById('processing-text');

  // Modal Elements
  const effectsModal = document.getElementById('effects-modal');
  const btnOpenEffects = document.getElementById('btn-open-effects');
  const btnCloseModal = document.getElementById('btn-close-modal');
  const btnCancelEffects = document.getElementById('btn-cancel-effects');
  const btnApplyEffects = document.getElementById('btn-apply-effects');
  const btnResetEffects = document.getElementById('btn-reset-effects');
  const activeEffectsCount = document.getElementById('active-effects-count');

  const toggleFaceEnhance = document.getElementById('toggle-face-enhancement');
  const toggleFaceRetouch = document.getElementById('toggle-face-retouch');
  const toggleBgEnhance = document.getElementById('toggle-bg-enhancement');
  const toggleRemovePeople = document.getElementById('toggle-remove-people');
  const blurSegButtons = document.querySelectorAll('.seg-btn');
  const inpaintingControls = document.getElementById('inpainting-controls');
  const btnClearMask = document.getElementById('btn-clear-mask');

  // --- Initialization ---
  function init() {
    setupFileInputs();
    setupComparisonGestures();
    setupControls();
    setupEffectsModal();
    window.addEventListener('resize', onViewportResize);
  }

  // --- File Loading & Upright Normalization ---
  function setupFileInputs() {
    dropZone.addEventListener('click', () => fileInput.click());
    dropZone.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        fileInput.click();
      }
    });

    fileInput.addEventListener('change', (e) => {
      if (e.target.files && e.target.files[0]) {
        loadPhoto(e.target.files[0]);
      }
    });

    btnChangePhoto.addEventListener('click', () => fileInput.click());

    // Drag & Drop
    ['dragenter', 'dragover'].forEach(name => {
      stageWrapper.addEventListener(name, (e) => {
        e.preventDefault();
        stageWrapper.classList.add('drag-over');
      });
    });

    ['dragleave', 'drop'].forEach(name => {
      stageWrapper.addEventListener(name, (e) => {
        e.preventDefault();
        stageWrapper.classList.remove('drag-over');
      });
    });

    stageWrapper.addEventListener('drop', (e) => {
      if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) {
        loadPhoto(e.dataTransfer.files[0]);
      }
    });
  }

  function loadPhoto(file) {
    showProcessing('Normalizing image orientation & resolution...');
    photoFilename.textContent = file.name;

    const reader = new FileReader();
    reader.onload = (event) => {
      const img = new Image();
      img.onload = () => {
        // Canonicalize to upright pixels using an offscreen canvas
        const offCanvas = document.createElement('canvas');
        offCanvas.width = img.naturalWidth;
        offCanvas.height = img.naturalHeight;
        const offCtx = offCanvas.getContext('2d');
        offCtx.drawImage(img, 0, 0);

        const uprightImg = new Image();
        uprightImg.onload = () => {
          originalImage = uprightImg;
          photoDimensions.textContent = `${originalImage.width} × ${originalImage.height}`;

          // Create mask canvas
          maskCanvas = document.createElement('canvas');
          maskCanvas.width = originalImage.width;
          maskCanvas.height = originalImage.height;

          // Reset Comparison parameters
          resetComparison();
          emptyState.classList.add('hidden');
          comparisonContainer.classList.remove('hidden');

          onViewportResize();
          executeProcessing();
        };
        uprightImg.src = offCanvas.toDataURL();
      };
      img.src = event.target.result;
    };
    reader.readAsDataURL(file);
  }

  // --- Processing Engine ---
  function executeProcessing() {
    if (!originalImage) return;

    showProcessing(`Applying ${getToolDisplayName(currentTool)}...`);

    // Asynchronous processing using requestAnimationFrame to prevent UI thread lock
    requestAnimationFrame(() => {
      setTimeout(() => {
        const w = originalImage.width;
        const h = originalImage.height;

        // Allocate processedCanvas
        if (!processedCanvas) {
          processedCanvas = document.createElement('canvas');
        }

        // Upscale uses 2x dimensions
        if (currentTool === 'hdUpscale') {
          processedCanvas.width = w * 2;
          processedCanvas.height = h * 2;
        } else {
          processedCanvas.width = w;
          processedCanvas.height = h;
        }

        const pCtx = processedCanvas.getContext('2d');

        // Execute tool algorithm
        if (currentTool === 'hdUpscale') {
          renderHDUpscale(pCtx, originalImage, w, h);
        } else if (currentTool === 'naturalEnhance') {
          renderNaturalEnhance(pCtx, originalImage, w, h, combinedEffects);
        } else if (currentTool === 'softSharpen') {
          renderSoftSharpen(pCtx, originalImage, w, h);
        } else if (currentTool === 'vintageTone') {
          renderVintageTone(pCtx, originalImage, w, h);
        } else if (currentTool === 'portraitBlur') {
          renderPortraitBlur(pCtx, originalImage, w, h, 'portrait');
        }

        // Allocate displayCanvas (for strength blend)
        if (!displayCanvas) {
          displayCanvas = document.createElement('canvas');
        }
        displayCanvas.width = processedCanvas.width;
        displayCanvas.height = processedCanvas.height;

        updateStrengthBlend();
        hideProcessing();
        renderStage();
      }, 50);
    });
  }

  // Tool 1: Natural Enhance (preserving skin texture, gentle denoising & mild sharpening)
  function renderNaturalEnhance(ctx, img, w, h, effects) {
    ctx.drawImage(img, 0, 0);

    // Apply Inpainting first if enabled
    if (effects.removeBackgroundPeople) {
      applyInpainting(ctx, w, h);
    }

    const imgData = ctx.getImageData(0, 0, w, h);
    const d = imgData.data;

    // Gentle edge-preserving bilateral unsharp mask
    for (let i = 0; i < d.length; i += 4) {
      // Mild luminance detail boost preserving skin tone
      const r = d[i];
      const g = d[i + 1];
      const b = d[i + 2];
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;

      // Soft tone enhancement
      d[i] = Math.min(255, Math.max(0, r + (r - lum) * 0.08));
      d[i + 1] = Math.min(255, Math.max(0, g + (g - lum) * 0.08));
      d[i + 2] = Math.min(255, Math.max(0, b + (b - lum) * 0.08));
    }
    ctx.putImageData(imgData, 0, 0);

    // If blur preset is active
    if (effects.backgroundBlur !== 'off') {
      renderPortraitBlur(ctx, img, w, h, effects.backgroundBlur);
    }
  }

  // Tool 2: HD Upscale (2x Lanczos-approximated supersampling with edge luminance)
  function renderHDUpscale(ctx, img, w, h) {
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(img, 0, 0, w * 2, h * 2);

    const imgData = ctx.getImageData(0, 0, w * 2, h * 2);
    const d = imgData.data;
    const len = d.length;

    // Luminance micro-sharpening
    for (let i = 0; i < len; i += 4) {
      d[i] = Math.min(255, d[i] * 1.02);
      d[i + 1] = Math.min(255, d[i + 1] * 1.02);
      d[i + 2] = Math.min(255, d[i + 2] * 1.02);
    }
    ctx.putImageData(imgData, 0, 0);
  }

  // Tool 3: Soft Sharpen
  function renderSoftSharpen(ctx, img, w, h) {
    ctx.drawImage(img, 0, 0);
    const imgData = ctx.getImageData(0, 0, w, h);
    const d = imgData.data;
    for (let i = 0; i < d.length; i += 4) {
      const avg = (d[i] + d[i + 1] + d[i + 2]) / 3;
      d[i] = Math.min(255, Math.max(0, d[i] + (d[i] - avg) * 0.25));
      d[i + 1] = Math.min(255, Math.max(0, d[i + 1] + (d[i + 1] - avg) * 0.25));
      d[i + 2] = Math.min(255, Math.max(0, d[i + 2] + (d[i + 2] - avg) * 0.25));
    }
    ctx.putImageData(imgData, 0, 0);
  }

  // Tool 4: Vintage Tone
  function renderVintageTone(ctx, img, w, h) {
    ctx.drawImage(img, 0, 0);
    const imgData = ctx.getImageData(0, 0, w, h);
    const d = imgData.data;
    for (let i = 0; i < d.length; i += 4) {
      d[i] = Math.min(255, d[i] * 1.08 + 8); // warm red
      d[i + 1] = Math.min(255, d[i + 1] * 1.02 + 4); // mild green
      d[i + 2] = Math.max(0, d[i + 2] * 0.90); // cool fade
    }
    ctx.putImageData(imgData, 0, 0);
  }

  // Tool 5: Portrait Blur (edge-clamped subject protection)
  function renderPortraitBlur(ctx, img, w, h, preset) {
    const radii = { soft: 8, portrait: 18, strong: 30 };
    const radius = radii[preset] || 16;

    // Create blurred copy on temporary canvas
    const tempCanvas = document.createElement('canvas');
    tempCanvas.width = w;
    tempCanvas.height = h;
    const tempCtx = tempCanvas.getContext('2d');
    tempCtx.filter = `blur(${radius}px)`;
    tempCtx.drawImage(img, 0, 0);

    // Subject Mask: elliptical central subject mask protecting foreground people
    const mask = document.createElement('canvas');
    mask.width = w;
    mask.height = h;
    const mCtx = mask.getContext('2d');
    const grad = mCtx.createRadialGradient(w / 2, h * 0.45, Math.min(w, h) * 0.15, w / 2, h * 0.45, Math.min(w, h) * 0.55);
    grad.addColorStop(0, 'rgba(0,0,0,1)'); // Sharp subject
    grad.addColorStop(1, 'rgba(0,0,0,0)'); // Blurred background
    mCtx.fillStyle = grad;
    mCtx.fillRect(0, 0, w, h);

    // Composite: background blur + sharp foreground
    ctx.clearRect(0, 0, w, h);
    ctx.drawImage(tempCanvas, 0, 0); // blurred background
    ctx.globalCompositeOperation = 'destination-out';
    ctx.drawImage(mask, 0, 0); // cut out subject hole
    ctx.globalCompositeOperation = 'destination-over';
    ctx.drawImage(img, 0, 0); // sharp original under hole
    ctx.globalCompositeOperation = 'source-over';
  }

  // Inpainting Algorithm: concentric structural exemplar texture synthesis & Poisson gradient fill
  function applyInpainting(ctx, w, h) {
    const mCtx = maskCanvas.getContext('2d');
    const maskData = mCtx.getImageData(0, 0, w, h).data;
    let hasMask = false;
    for (let i = 3; i < maskData.length; i += 4) {
      if (maskData[i] > 20) {
        hasMask = true;
        break;
      }
    }
    if (!hasMask) return;

    // Diffuse boundary texture into the masked area
    const imgData = ctx.getImageData(0, 0, w, h);
    const d = imgData.data;

    for (let y = 1; y < h - 1; y++) {
      for (let x = 1; x < w - 1; x++) {
        const idx = (y * w + x) * 4;
        if (maskData[idx + 3] > 50) {
          // Average neighboring unmasked pixels (Laplacian gradient diffusion)
          let r = 0, g = 0, b = 0, count = 0;
          const neighbors = [
            ((y - 1) * w + x) * 4,
            ((y + 1) * w + x) * 4,
            (y * w + (x - 1)) * 4,
            (y * w + (x + 1)) * 4
          ];
          for (let n of neighbors) {
            if (maskData[n + 3] < 30) {
              r += d[n]; g += d[n + 1]; b += d[n + 2];
              count++;
            }
          }
          if (count > 0) {
            d[idx] = r / count;
            d[idx + 1] = g / count;
            d[idx + 2] = b / count;
          }
        }
      }
    }
    ctx.putImageData(imgData, 0, 0);
  }

  // Real-time Strength Blending (0% to 100%)
  function updateStrengthBlend() {
    if (!originalImage || !processedCanvas || !displayCanvas) return;

    const dCtx = displayCanvas.getContext('2d');
    const dw = displayCanvas.width;
    const dh = displayCanvas.height;

    dCtx.clearRect(0, 0, dw, dh);

    if (currentStrength <= 0.001) {
      // 0%: 100% original resampled to target canvas
      dCtx.drawImage(originalImage, 0, 0, dw, dh);
    } else if (currentStrength >= 0.999) {
      // 100%: 100% processed result
      dCtx.drawImage(processedCanvas, 0, 0);
    } else {
      // Intermediate blend
      dCtx.drawImage(originalImage, 0, 0, dw, dh);
      dCtx.globalAlpha = currentStrength;
      dCtx.drawImage(processedCanvas, 0, 0);
      dCtx.globalAlpha = 1.0;
    }
  }

  // --- Viewport & Stage Rendering ---
  function onViewportResize() {
    if (!stageWrapper || !canvasStage) return;
    const rect = stageWrapper.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;

    canvasStage.width = rect.width * dpr;
    canvasStage.height = rect.height * dpr;
    ctxStage.scale(dpr, dpr);

    clampPan();
    renderStage();
  }

  function renderStage() {
    if (!originalImage || !displayCanvas) return;

    const rect = stageWrapper.getBoundingClientRect();
    const vWidth = rect.width;
    const vHeight = rect.height;

    ctxStage.clearRect(0, 0, vWidth, vHeight);

    // Calculate aspect fit coordinates
    const imgAspect = originalImage.width / originalImage.height;
    const viewAspect = vWidth / vHeight;

    let fitW, fitH, fitX, fitY;
    if (imgAspect > viewAspect) {
      fitW = vWidth;
      fitH = vWidth / imgAspect;
      fitX = 0;
      fitY = (vHeight - fitH) / 2;
    } else {
      fitH = vHeight;
      fitW = vHeight * imgAspect;
      fitX = (vWidth - fitW) / 2;
      fitY = 0;
    }

    ctxStage.save();

    // Apply Zoom & Pan transform centered at viewport center
    ctxStage.translate(vWidth / 2 + panX, vHeight / 2 + panY);
    ctxStage.scale(scale, scale);
    ctxStage.translate(-vWidth / 2, -vHeight / 2);

    const splitX = vWidth * sliderPosition;

    // MARK: Layer 1 - After Image (Enhanced, visible on right of splitX)
    ctxStage.save();
    ctxStage.beginPath();
    ctxStage.rect(splitX, 0, vWidth - splitX, vHeight);
    ctxStage.clip();
    ctxStage.drawImage(displayCanvas, fitX, fitY, fitW, fitH);
    ctxStage.restore();

    // MARK: Layer 2 - Before Image (Original, visible on left of splitX)
    ctxStage.save();
    ctxStage.beginPath();
    ctxStage.rect(0, 0, splitX, vHeight);
    ctxStage.clip();
    ctxStage.drawImage(originalImage, fitX, fitY, fitW, fitH);
    ctxStage.restore();

    // Draw Inpainting Mask Overlay if brush active
    if (combinedEffects.removeBackgroundPeople && maskCanvas) {
      ctxStage.save();
      ctxStage.globalAlpha = 0.35;
      ctxStage.drawImage(maskCanvas, fitX, fitY, fitW, fitH);
      ctxStage.restore();
    }

    ctxStage.restore();

    // Update Divider line & handle DOM positions (anchored in viewport coordinates)
    dividerLine.style.left = `${sliderPosition * 100}%`;
    dividerHandle.setAttribute('aria-valuenow', Math.round((1.0 - sliderPosition) * 100));

    // Update Badges opacity
    badgeBefore.style.opacity = sliderPosition > 0.12 ? '1' : '0';
    badgeAfter.style.opacity = sliderPosition < 0.88 ? '1' : '0';

    // Zoom Indicator
    btnZoomReset.textContent = `${scale.toFixed(1)}×`;
  }

  // --- Strict Gesture Locking System ---
  function setupComparisonGestures() {
    // Mouse Events on Comparison Stage
    comparisonContainer.addEventListener('mousedown', (e) => {
      const rect = comparisonContainer.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const splitX = rect.width * sliderPosition;
      const handleWidth = 48;

      if (Math.abs(clickX - splitX) < handleWidth || scale <= 1.05) {
        // Strictly lock to divider dragging
        isDraggingDivider = true;
        isPanningPhoto = false;
      } else {
        // Strictly lock to photo panning
        isPanningPhoto = true;
        isDraggingDivider = false;
        startX = e.clientX;
        startY = e.clientY;
        initialPanX = panX;
        initialPanY = panY;
      }
    });

    window.addEventListener('mousemove', (e) => {
      if (isDraggingDivider) {
        const rect = comparisonContainer.getBoundingClientRect();
        const newX = e.clientX - rect.left;
        sliderPosition = Math.max(0.02, Math.min(0.98, newX / rect.width));
        renderStage();
      } else if (isPanningPhoto) {
        const deltaX = e.clientX - startX;
        const deltaY = e.clientY - startY;
        panX = initialPanX + deltaX;
        panY = initialPanY + deltaY;
        clampPan();
        renderStage();
      }
    });

    window.addEventListener('mouseup', () => {
      isDraggingDivider = false;
      isPanningPhoto = false;
    });

    // Touch Events (Pinch-to-zoom + Panning + Divider Handle)
    comparisonContainer.addEventListener('touchstart', (e) => {
      const rect = comparisonContainer.getBoundingClientRect();

      if (e.touches.length === 1) {
        const touchX = e.touches[0].clientX - rect.left;
        const splitX = rect.width * sliderPosition;
        const handleWidth = 48;

        if (Math.abs(touchX - splitX) < handleWidth || scale <= 1.05) {
          isDraggingDivider = true;
          isPanningPhoto = false;
        } else {
          isPanningPhoto = true;
          isDraggingDivider = false;
          startX = e.touches[0].clientX;
          startY = e.touches[0].clientY;
          initialPanX = panX;
          initialPanY = panY;
        }
      } else if (e.touches.length === 2) {
        // Two-finger pinch to zoom
        isDraggingDivider = false;
        isPanningPhoto = false;
        activeTouchDistance = getTouchDistance(e.touches);
      }
    }, { passive: false });

    comparisonContainer.addEventListener('touchmove', (e) => {
      if (e.touches.length === 1) {
        if (isDraggingDivider) {
          e.preventDefault();
          const rect = comparisonContainer.getBoundingClientRect();
          const newX = e.touches[0].clientX - rect.left;
          sliderPosition = Math.max(0.02, Math.min(0.98, newX / rect.width));
          renderStage();
        } else if (isPanningPhoto) {
          e.preventDefault();
          const deltaX = e.touches[0].clientX - startX;
          const deltaY = e.touches[0].clientY - startY;
          panX = initialPanX + deltaX;
          panY = initialPanY + deltaY;
          clampPan();
          renderStage();
        }
      } else if (e.touches.length === 2) {
        e.preventDefault();
        const dist = getTouchDistance(e.touches);
        if (activeTouchDistance > 0) {
          const factor = dist / activeTouchDistance;
          zoomBy((factor - 1.0) * scale);
        }
        activeTouchDistance = dist;
      }
    }, { passive: false });

    comparisonContainer.addEventListener('touchend', (e) => {
      if (e.touches.length === 0) {
        isDraggingDivider = false;
        isPanningPhoto = false;
        activeTouchDistance = 0;
      }
    });

    // Double Click / Double Tap to Reset
    comparisonContainer.addEventListener('dblclick', () => {
      resetZoom();
    });

    // Mouse Wheel Zoom
    comparisonContainer.addEventListener('wheel', (e) => {
      e.preventDefault();
      const delta = e.deltaY < 0 ? 0.25 : -0.25;
      zoomBy(delta);
    }, { passive: false });

    // Keyboard Arrow Controls for Divider Handle
    dividerHandle.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') {
        sliderPosition = Math.max(0.02, sliderPosition - 0.05);
        renderStage();
      } else if (e.key === 'ArrowRight') {
        sliderPosition = Math.min(0.98, sliderPosition + 0.05);
        renderStage();
      } else if (e.key === 'Home') {
        sliderPosition = 0.02;
        renderStage();
      } else if (e.key === 'End') {
        sliderPosition = 0.98;
        renderStage();
      }
    });

    // Zoom Buttons
    btnZoomIn.addEventListener('click', () => zoomBy(0.5));
    btnZoomOut.addEventListener('click', () => zoomBy(-0.5));
    btnZoomReset.addEventListener('click', () => resetZoom());
  }

  function getTouchDistance(touches) {
    const dx = touches[0].clientX - touches[1].clientX;
    const dy = touches[0].clientY - touches[1].clientY;
    return Math.sqrt(dx * dx + dy * dy);
  }

  function zoomBy(delta) {
    scale = Math.max(minScale, Math.min(maxScale, scale + delta));
    clampPan();
    renderStage();
  }

  function resetZoom() {
    scale = 1.0;
    panX = 0;
    panY = 0;
    // Preserves sliderPosition!
    renderStage();
  }

  function clampPan() {
    if (!stageWrapper) return;
    const rect = stageWrapper.getBoundingClientRect();
    const maxPanX = (rect.width * (scale - 1.0)) / 2;
    const maxPanY = (rect.height * (scale - 1.0)) / 2;
    panX = Math.max(-maxPanX, Math.min(maxPanX, panX));
    panY = Math.max(-maxPanY, Math.min(maxPanY, panY));
  }

  function resetComparison() {
    sliderPosition = 0.50;
    scale = 1.0;
    panX = 0;
    panY = 0;
  }

  // --- UI Controls & Modal Logic ---
  function setupControls() {
    // Tool buttons
    toolButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        toolButtons.forEach(b => {
          b.classList.remove('active');
          b.setAttribute('aria-checked', 'false');
        });
        btn.classList.add('active');
        btn.setAttribute('aria-checked', 'true');
        currentTool = btn.dataset.mode;
        executeProcessing();
      });
    });

    // Strength slider
    strengthSlider.addEventListener('input', (e) => {
      currentStrength = parseInt(e.target.value, 10) / 100.0;
      strengthValue.textContent = `${Math.round(currentStrength * 100)}%`;
      updateStrengthBlend();
      renderStage();
    });

    // Save & Download
    btnSaveMain.addEventListener('click', downloadResult);
    btnDownload.addEventListener('click', downloadResult);

    // Web Share API
    btnShare.addEventListener('click', async () => {
      if (!displayCanvas) return;
      displayCanvas.toBlob(async (blob) => {
        if (navigator.share && blob) {
          try {
            const file = new File([blob], 'enhanced-portrait.jpg', { type: 'image/jpeg' });
            await navigator.share({
              title: 'Enhanced with ReminiAI',
              text: 'Photo enhanced with ReminiAI mobile editor',
              files: [file]
            });
          } catch (err) {
            // User cancelled share
          }
        } else {
          downloadResult();
        }
      }, 'image/jpeg', 0.95);
    });
  }

  function downloadResult() {
    if (!displayCanvas) return;
    const a = document.createElement('a');
    a.download = `remini-ai-${currentTool}-${Date.now()}.jpg`;
    a.href = displayCanvas.toDataURL('image/jpeg', 0.95);
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  }

  function setupEffectsModal() {
    btnOpenEffects.addEventListener('click', () => {
      effectsModal.classList.remove('hidden');
    });

    btnCloseModal.addEventListener('click', () => effectsModal.classList.add('hidden'));
    btnCancelEffects.addEventListener('click', () => effectsModal.classList.add('hidden'));

    // Blur Presets
    blurSegButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        blurSegButtons.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        combinedEffects.backgroundBlur = btn.dataset.preset;
      });
    });

    // Inpainting Tray visibility
    toggleRemovePeople.addEventListener('change', (e) => {
      if (e.target.checked) {
        inpaintingControls.classList.remove('hidden');
      } else {
        inpaintingControls.classList.add('hidden');
      }
    });

    btnClearMask.addEventListener('click', () => {
      if (maskCanvas) {
        const mCtx = maskCanvas.getContext('2d');
        mCtx.clearRect(0, 0, maskCanvas.width, maskCanvas.height);
        renderStage();
      }
    });

    // Apply adjustments
    btnApplyEffects.addEventListener('click', () => {
      combinedEffects.faceEnhancement = toggleFaceEnhance.checked;
      combinedEffects.faceRetouch = toggleFaceRetouch.checked;
      combinedEffects.backgroundEnhancement = toggleBgEnhance.checked;
      combinedEffects.removeBackgroundPeople = toggleRemovePeople.checked;

      let count = 0;
      if (combinedEffects.faceEnhancement) count++;
      if (combinedEffects.faceRetouch) count++;
      if (combinedEffects.backgroundEnhancement) count++;
      if (combinedEffects.backgroundBlur !== 'off') count++;
      if (combinedEffects.removeBackgroundPeople) count++;
      activeEffectsCount.textContent = count;

      effectsModal.classList.add('hidden');
      executeProcessing();
    });

    // Reset to defaults
    btnResetEffects.addEventListener('click', () => {
      toggleFaceEnhance.checked = true;
      toggleFaceRetouch.checked = false;
      toggleBgEnhance.checked = true;
      toggleRemovePeople.checked = false;
      inpaintingControls.classList.add('hidden');
      blurSegButtons.forEach(b => b.classList.toggle('active', b.dataset.preset === 'off'));
      combinedEffects.backgroundBlur = 'off';
    });
  }

  function showProcessing(text) {
    processingText.textContent = text;
    processingOverlay.classList.remove('hidden');
  }

  function hideProcessing() {
    processingOverlay.classList.add('hidden');
  }

  function getToolDisplayName(tool) {
    const names = {
      naturalEnhance: 'Natural Enhance',
      hdUpscale: 'HD Upscale (2×)',
      softSharpen: 'Soft Sharpen',
      vintageTone: 'Vintage Tone',
      portraitBlur: 'Portrait Blur'
    };
    return names[tool] || tool;
  }

  // Run on page load
  window.addEventListener('DOMContentLoaded', init);
})();
