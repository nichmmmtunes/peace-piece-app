<script lang="ts">
  import type { VideoClip } from './types';
  import { createEventDispatcher } from 'svelte';

  export let timelineHeight = 150;
  export let activeClips: VideoClip[] = [];
  export let currentTime = 0;
  export let isPlaying = false;

  let canvasWidth = 0;
  let canvasElement: HTMLElement;

  const dispatch = createEventDispatcher();

  // Video element references for playback control
  let backgroundVideoElement: HTMLVideoElement;
  let overlayVideoElements: Map<string, HTMLVideoElement> = new Map();

  function formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // Get background video/image for the canvas
  $: backgroundClip = activeClips.find(clip => 
    (clip.type === 'video' || clip.type === 'image') && clip.layer === 0
  );

  // Get overlay elements (images, stickers, text, videos)
  $: overlayClips = activeClips.filter(clip => 
    clip.layer > 0 && clip.type !== 'audio'
  ).sort((a, b) => a.layer - b.layer);

  // Get audio clips for visualization
  $: audioClips = activeClips.filter(clip => clip.type === 'audio');

  // Video playback control - sync with timeline
  $: {
    if (backgroundVideoElement && backgroundClip && backgroundClip.type === 'video') {
      const videoTime = currentTime - backgroundClip.timelineStart + (backgroundClip.contentStartTime || 0);
      
      // Ensure video time stays within content bounds
      const clampedVideoTime = Math.max(
        backgroundClip.contentStartTime || 0,
        Math.min(backgroundClip.contentEndTime || backgroundClip.duration, videoTime)
      );
      
      if (Math.abs(backgroundVideoElement.currentTime - clampedVideoTime) > 0.2) {
        backgroundVideoElement.currentTime = clampedVideoTime;
      }
      
      if (isPlaying && backgroundVideoElement.paused) {
        backgroundVideoElement.play().catch(console.warn);
      } else if (!isPlaying && !backgroundVideoElement.paused) {
        backgroundVideoElement.pause();
      }
    }
    
    // Control overlay video elements
    overlayClips.forEach(clip => {
      if (clip.type === 'video') {
        const videoElement = overlayVideoElements.get(clip.id);
        if (videoElement) {
          const videoTime = currentTime - clip.timelineStart + (clip.contentStartTime || 0);
          
          // Ensure video time stays within content bounds
          const clampedVideoTime = Math.max(
            clip.contentStartTime || 0,
            Math.min(clip.contentEndTime || clip.duration, videoTime)
          );
          
          if (Math.abs(videoElement.currentTime - clampedVideoTime) > 0.2) {
            videoElement.currentTime = clampedVideoTime;
          }
          
          if (isPlaying && videoElement.paused) {
            videoElement.play().catch(console.warn);
          } else if (!isPlaying && !videoElement.paused) {
            videoElement.pause();
          }
        }
      }
    });
  }

  // Handle clicks on the canvas area
  function handleCanvasAreaClick(event: MouseEvent) {
    // Check if the click was on the canvas element itself
    if (canvasElement && event.target) {
      const clickedElement = event.target as HTMLElement;
      
      // If the click was on the canvas or any of its children, don't reset
      if (canvasElement.contains(clickedElement)) {
        return;
      }
      
      // If the click was outside the canvas (on the canvas area background), reset properties
      dispatch('resetProperties');
    }
  }

  // Helper function to get position styles (left and top only)
  function getPositionStyle(clip: VideoClip): string {
    // For image layers (not stickers), use fixed center position
    if (clip.type === 'image' && clip.sampleData?.type !== 'sticker') {
      return `
        left: 50%;
        top: 50%;
      `;
    }
    
    // For video layers, use fixed center position
    if (clip.type === 'video') {
      return `
        left: 50%;
        top: 50%;
      `;
    }
    
    // For other elements, use custom position
    const position = clip.position || { x: 50, y: 50 };
    
    return `
      left: ${position.x}%;
      top: ${position.y}%;
    `;
  }

  // Helper function to get base transform components (always applied)
  function getBaseTransformComponents(clip: VideoClip): string {
    const rotation = clip.rotation || 0;
    return `translate(-50%, -50%) rotate(${rotation}deg)`;
  }

  // Helper function to calculate scrubbed animation values
  function getScrubbedAnimationValues(clip: VideoClip, currentTime: number): { additionalTransform: string; finalOpacity: number } {
    const animation = clip.animation || 'none';
    const animationDuration = clip.animationDuration || 1;
    const animationDelay = clip.animationDelay || 0;
    const baseOpacity = clip.opacity !== undefined ? clip.opacity : 1;
    
    // If no animation, return defaults
    if (animation === 'none') {
      return {
        additionalTransform: '',
        finalOpacity: baseOpacity
      };
    }
    
    // Calculate animation timing
    const clipStartTime = clip.timelineStart;
    const animationStartTime = clipStartTime + animationDelay;
    const animationEndTime = animationStartTime + animationDuration;
    
    // Determine animation progress (0 = start, 1 = complete)
    let progress = 0;
    
    if (currentTime < animationStartTime) {
      // Before animation starts
      progress = 0;
    } else if (currentTime >= animationEndTime) {
      // After animation completes
      progress = 1;
    } else {
      // During animation
      progress = (currentTime - animationStartTime) / animationDuration;
      // Clamp progress between 0 and 1
      progress = Math.max(0, Math.min(1, progress));
    }
    
    // Apply easing for smoother animations (ease-out)
    const easedProgress = 1 - Math.pow(1 - progress, 2);
    
    // Calculate animation-specific transforms and opacity
    switch (animation) {
      case 'fadeIn':
        return {
          additionalTransform: '',
          finalOpacity: baseOpacity * easedProgress
        };
        
      case 'slideInLeft':
        const leftOffset = (1 - easedProgress) * -100; // Start from -100% (off-screen left)
        return {
          additionalTransform: `translateX(${leftOffset}%)`,
          finalOpacity: baseOpacity
        };
        
      case 'slideInRight':
        const rightOffset = (1 - easedProgress) * 100; // Start from 100% (off-screen right)
        return {
          additionalTransform: `translateX(${rightOffset}%)`,
          finalOpacity: baseOpacity
        };
        
      case 'slideInUp':
        const upOffset = (1 - easedProgress) * 100; // Start from 100% (off-screen bottom)
        return {
          additionalTransform: `translateY(${upOffset}%)`,
          finalOpacity: baseOpacity
        };
        
      case 'slideInDown':
        const downOffset = (1 - easedProgress) * -100; // Start from -100% (off-screen top)
        return {
          additionalTransform: `translateY(${downOffset}%)`,
          finalOpacity: baseOpacity
        };
        
      case 'zoomIn':
        const scale = easedProgress; // Start from 0 scale, end at 1
        return {
          additionalTransform: `scale(${scale})`,
          finalOpacity: baseOpacity
        };
        
      default:
        return {
          additionalTransform: '',
          finalOpacity: baseOpacity
        };
    }
  }

  // Helper function to get size styles for overlay elements
  function getSizeStyle(clip: VideoClip): string {
    // For image layers (not stickers), fill the canvas
    if (clip.type === 'image' && clip.sampleData?.type !== 'sticker') {
      return `
        width: 100%;
        height: 100%;
      `;
    }
    
    // For video layers, fill the canvas
    if (clip.type === 'video') {
      return `
        width: 100%;
        height: 100%;
      `;
    }
    
    // For other elements, use scale as percentage of canvas
    const scale = clip.scale || { x: 20, y: 20 }; // Default to 20% of canvas
    
    return `
      width: ${scale.x}%;
      height: ${scale.y}%;
    `;
  }

  // Helper function to get filter styles
  function getFilterStyle(clip: VideoClip): string {
    const filters = [];
    
    if (clip.brightness !== undefined && clip.brightness !== 1) {
      filters.push(`brightness(${clip.brightness})`);
    }
    if (clip.contrast !== undefined && clip.contrast !== 1) {
      filters.push(`contrast(${clip.contrast})`);
    }
    if (clip.saturation !== undefined && clip.saturation !== 1) {
      filters.push(`saturate(${clip.saturation})`);
    }
    if (clip.blur !== undefined && clip.blur > 0) {
      filters.push(`blur(${clip.blur}px)`);
    }
    
    return filters.length > 0 ? `filter: ${filters.join(' ')};` : '';
  }

  // Helper function to get blend mode styles
  function getBlendModeStyle(clip: VideoClip): string {
    if (clip.mixBlendMode && clip.mixBlendMode !== 'normal') {
      return `mix-blend-mode: ${clip.mixBlendMode};`;
    }
    return '';
  }

  // Helper function to get text styles
  function getTextStyle(clip: VideoClip): string {
    const fontSize = clip.fontSize || 2.5; // Default to 2.5% of canvas width
    const fontSizePixels = canvasWidth > 0 ? (fontSize / 100) * canvasWidth : fontSize * 16; // Fallback to 16px base
    
    return `
      font-size: ${fontSizePixels}px;
      font-family: ${clip.fontFamily || 'Arial, sans-serif'};
      font-weight: ${clip.fontWeight || 'normal'};
      font-style: ${clip.fontStyle || 'normal'};
      color: ${clip.textColor || '#FFFFFF'};
      text-align: ${clip.textAlign || 'center'};
      text-shadow: ${clip.textShadow || 'none'};
      line-height: ${clip.lineHeight || 1.2};
      letter-spacing: ${clip.letterSpacing || 0}px;
    `;
  }

  // Helper function to bind video elements to the map
  function bindVideoElement(node: HTMLVideoElement, clipId: string) {
    overlayVideoElements.set(clipId, node);
    return {
      destroy() {
        overlayVideoElements.delete(clipId);
      }
    };
  }
</script>

<div class="canvas-area" on:click={handleCanvasAreaClick}>
  <div class="canvas-container">
    <div class="canvas" bind:this={canvasElement} bind:clientWidth={canvasWidth}>
      <!-- Background Layer -->
      {#if backgroundClip}
        <div 
          class="background-layer"
          style="{getFilterStyle(backgroundClip)} {getBlendModeStyle(backgroundClip)}"
        >
          {#if backgroundClip.type === 'video' && (backgroundClip.url || backgroundClip.sampleData?.thumbnail)}
            <video 
              bind:this={backgroundVideoElement}
              src={backgroundClip.url || backgroundClip.sampleData?.thumbnail} 
              class="background-media"
              muted
              playsinline
              style="opacity: {backgroundClip.opacity !== undefined ? backgroundClip.opacity : 1};"
            >
              Your browser does not support the video tag.
            </video>
          {:else if backgroundClip.type === 'image' && (backgroundClip.url || backgroundClip.sampleData?.thumbnail)}
            <img 
              src={backgroundClip.url || backgroundClip.sampleData?.thumbnail} 
              alt={backgroundClip.name}
              class="background-media"
              style="opacity: {backgroundClip.opacity !== undefined ? backgroundClip.opacity : 1};"
            />
          {/if}
        </div>
      {:else}
        <div class="canvas-placeholder">
          <div class="placeholder-content">
            <div class="placeholder-icon">🎬</div>
            <div class="placeholder-text">16:9 Canvas Area</div>
            <div class="canvas-info">
              Time: {formatTime(currentTime)}
              {#if isPlaying}
                <span class="playing-indicator">▶️</span>
              {/if}
            </div>
          </div>
        </div>
      {/if}

      <!-- Overlay Layers -->
      {#each overlayClips as clip (clip.id)}
        {@const animationValues = getScrubbedAnimationValues(clip, currentTime)}
        <div 
          class="overlay-layer"
          style="{getPositionStyle(clip)} {getSizeStyle(clip)} {getBlendModeStyle(clip)} z-index: {clip.layer}; transform: {getBaseTransformComponents(clip)} {animationValues.additionalTransform}; opacity: {animationValues.finalOpacity};"
        >
          {#if clip.type === 'text'}
            <div 
              class="text-overlay"
              style="{getTextStyle(clip)}"
            >
              {clip.content || 'Sample Text'}
            </div>
          {:else if clip.type === 'video' && (clip.url || clip.sampleData?.thumbnail)}
            <div 
              class="video-overlay"
              style="{getFilterStyle(clip)}"
            >
              <video 
                use:bindVideoElement={clip.id}
                src={clip.url || clip.sampleData?.thumbnail} 
                class="overlay-video"
                muted
                playsinline
                style="opacity: {clip.opacity !== undefined ? clip.opacity : 1};"
              >
                Your browser does not support the video tag.
              </video>
            </div>
          {:else if clip.type === 'image' && (clip.url || clip.sampleData?.thumbnail)}
            <div 
              class="image-overlay"
              class:sticker={clip.sampleData?.type === 'sticker'}
              style="{getFilterStyle(clip)}"
            >
              <img 
                src={clip.url || clip.sampleData?.thumbnail} 
                alt={clip.name}
                class="overlay-image"
              />
            </div>
          {/if}
        </div>
      {/each}

      <!-- Audio Visualization -->
      {#if audioClips.length > 0}
        <div class="audio-visualization">
          {#each audioClips as audioClip (audioClip.id)}
            <div class="audio-indicator">
              <div class="audio-icon">🎵</div>
              <div class="audio-info">
                <div class="audio-title">{audioClip.sampleData?.title || audioClip.name}</div>
                <div class="audio-waveform">
                  {#if audioClip.sampleData?.waveform}
                    {#each audioClip.sampleData.waveform as level, i}
                      <div 
                        class="waveform-bar"
                        class:active={isPlaying}
                        style="
                          height: {level * 20}px;
                          animation-delay: {i * 0.1}s;
                        "
                      ></div>
                    {/each}
                  {/if}
                </div>
                <div class="volume-indicator">
                  Volume: {Math.round((audioClip.volume || 0.6) * 100)}%
                </div>
              </div>
            </div>
          {/each}
        </div>
      {/if}

      <!-- Timeline Position Indicator -->
      <div class="timeline-position">
        {formatTime(currentTime)}
        {#if activeClips.length > 0}
          <span class="active-layers">• {activeClips.length} active layers</span>
        {/if}
      </div>
    </div>

  </div>
</div>

<style>
  /* Canvas Area */
  .canvas-area {
    flex: 1;
    display: flex;
    flex-direction: column;
    background: #f5f5f5;
    min-width: 0;
    overflow: hidden;
    cursor: default;
  }

  .canvas-container {
    flex: 1;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem;
    min-height: 0;
    overflow: hidden;
  }

  .canvas {
    /* Maintain 16:9 aspect ratio while fitting in available space */
    height: 82%;
    aspect-ratio: 16 / 9;
    background: #000;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    position: relative;
    top: 0;
    overflow: hidden;
  }

  .background-layer {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 0;
  }

  .background-media {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 4px;
    position: absolute;
    top: 0;
    left: 0;
  }

  .canvas-placeholder {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    z-index: -1;
  }

  .placeholder-content {
    text-align: center;
  }

  .placeholder-icon {
    font-size: 3rem;
    margin-bottom: 1rem;
  }

  .placeholder-text {
    font-size: 1.2rem;
    margin-bottom: 0.5rem;
  }

  .canvas-info {
    font-size: 0.9rem;
    opacity: 0.8;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
  }

  .playing-indicator {
    animation: pulse 1s infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }

  .overlay-layer {
    position: absolute;
    pointer-events: none;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .text-overlay {
    white-space: pre-wrap;
    word-wrap: break-word;
    text-align: center;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .video-overlay {
    border-radius: 4px;
    overflow: hidden;
    width: 100%;
    height: 100%;
  }

  .overlay-video {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 4px;
  }

  .image-overlay {
    border-radius: 4px;
    overflow: hidden;
    width: 100%;
    height: 100%;
  }

  .image-overlay.sticker {
    filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));
  }

  .overlay-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 4px;
  }

  .audio-visualization {
    position: absolute;
    bottom: 10px;
    left: 10px;
    background: rgba(0, 0, 0, 0.7);
    border-radius: 8px;
    padding: 0.75rem;
    color: white;
    font-size: 0.8rem;
    z-index: 100;
    visibility: hidden;
    opacity: 0;
  }

  .audio-indicator {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.5rem;
  }

  .audio-indicator:last-child {
    margin-bottom: 0;
  }

  .audio-icon {
    font-size: 1.2rem;
  }

  .audio-info {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .audio-title {
    font-weight: 500;
  }

  .audio-waveform {
    display: flex;
    align-items: end;
    gap: 2px;
    height: 20px;
  }

  .waveform-bar {
    width: 3px;
    background: #007AFF;
    border-radius: 1px;
    transition: all 0.2s ease;
  }

  .waveform-bar.active {
    animation: waveform-pulse 1s infinite;
  }

  @keyframes waveform-pulse {
    0%, 100% { opacity: 0.6; }
    50% { opacity: 1; }
  }

  .volume-indicator {
    font-size: 0.7rem;
    opacity: 0.8;
  }

  .timeline-position {
    position: absolute;
    top: 10px;
    right: 10px;
    background: rgba(0, 0, 0, 0.7);
    color: white;
    padding: 0.5rem 0.75rem;
    border-radius: 6px;
    font-family: monospace;
    font-size: 0.9rem;
    z-index: 100;
    visibility: hidden;
    opacity: 0;
  }

  .active-layers {
    font-size: 0.7rem;
    opacity: 0.8;
    margin-left: 0.5rem;
  }

  .tool-btn {
    background: none;
    border: none;
    padding: 0.5rem;
    cursor: pointer;
    border-radius: 4px;
    font-size: 1rem;
    transition: background 0.2s;
  }

  .tool-btn:hover {
    background: #f0f0f0;
  }
</style>