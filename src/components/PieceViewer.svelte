<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  
  export let params = { id: '' };
  
  let piece: any = null;
  let loading = true;
  let error: string | null = null;
  let fullscreenMode = false;
  let showControls = true;
  let controlsTimeout: number;
  let isFollowing = false;
  let viewerElement: HTMLElement;
  let imageContainer: HTMLElement;
  let mainImage: HTMLImageElement;
  let videoElement: HTMLVideoElement;
  
  // Image scaling and pan state
  let scale = 1;
  let translateX = 0;
  let translateY = 0;
  let isDragging = false;
  let dragStartX = 0;
  let dragStartY = 0;
  let dragStartTranslateX = 0;
  let dragStartTranslateY = 0;
  let initialScale = 1;
  let userHasPanned = false; // Track if user has manually panned
  
  // Zoom limits
  const MIN_ZOOM = 0.5; // 50%
  const MAX_ZOOM = 3.0;  // 300%
  
  async function loadPiece() {
    try {
      loading = true;
      error = null;
      
      const { data, error: pieceError } = await supabase
        .from('piece_details')
        .select('*')
        .eq('id', params.id)
        .single();
        
      if (pieceError) throw pieceError;
      
      piece = data;
      
      // Check if user is following
      if ($user) {
        const { data: followData } = await supabase
          .from('piece_followers')
          .select('piece_id')
          .eq('piece_id', params.id)
          .eq('profile_id', $user.id)
          .maybeSingle();
          
        isFollowing = !!followData;
      }
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  function calculateInitialScale() {
    if (!mainImage || !imageContainer) return;
    
    const containerWidth = imageContainer.clientWidth;
    const imageWidth = mainImage.naturalWidth;
    
    if (imageWidth < containerWidth) {
      // Image is smaller than container, scale it up to fill width
      initialScale = containerWidth / imageWidth;
      scale = initialScale + .2;
    } else {
      // Image is larger than container, keep it at natural size
      initialScale = 1;
      scale = 1;
    }
    
    // Reset pan state when recalculating initial scale
    userHasPanned = false;
    
    // Center the image and apply constraints
    centerImageAndConstrain();
  }

  function centerImageAndConstrain() {
    if (!mainImage || !imageContainer) return;
    
    // CRITICAL: If zoom is less than 1.25, update to translate(0px, 0px)
    if (scale < 1.25) {
      translateX = 0;
      translateY = 0;
      return;
    }
    
    // CRITICAL: If pan has not been updated, maintain translate(0px, 0px) at any zoom level
    if (!userHasPanned) {
      translateX = 0;
      translateY = 0;
      return;
    }
    
    // Once pan has been updated by the user, recalculate translate position to remain on focal point
    // if scale is greater than 1.25
    const containerRect = imageContainer.getBoundingClientRect();
    const containerWidth = containerRect.width;
    const containerHeight = containerRect.height;
    
    const scaledImageWidth = mainImage.naturalWidth * scale;
    const scaledImageHeight = mainImage.naturalHeight * scale;
    
    // Apply panning constraints for larger images
    constrainPanning();
  }

  function constrainPanning() {
    if (!mainImage || !imageContainer) return;
    
    // CRITICAL: If zoom is less than 1.25, update to translate(0px, 0px)
    if (scale < 1.25) {
      translateX = 0;
      translateY = 0;
      return;
    }
    
    // CRITICAL: If pan has not been updated, maintain translate(0px, 0px) at any zoom level
    if (!userHasPanned) {
      translateX = 0;
      translateY = 0;
      return;
    }
    
    const containerRect = imageContainer.getBoundingClientRect();
    const containerWidth = containerRect.width;
    const containerHeight = containerRect.height;
    
    // Calculate the actual image dimensions after scaling
    const scaledImageWidth = mainImage.naturalWidth * scale;
    const scaledImageHeight = mainImage.naturalHeight * scale;
    
    // Horizontal constraints
    if (scaledImageWidth <= containerWidth) {
      // Image is smaller than container, center it
      translateX = (containerWidth - scaledImageWidth) / 2;
    } else {
      // Image is larger than container, allow panning with constraints
      // Calculate the minimum visible amount (20% of image)
      const minVisiblePercent = 0.2;
      const minVisibleWidth = scaledImageWidth * minVisiblePercent;
      
      // Calculate bounds for X translation
      // Maximum translateX: allows image to move right until only 20% is visible on the left
      const maxTranslateX = minVisibleWidth;
      // Minimum translateX: allows image to move left until only 20% is visible on the right  
      const minTranslateX = containerWidth - scaledImageWidth - minVisibleWidth;
      
      // Apply constraints
      translateX = Math.max(minTranslateX, Math.min(maxTranslateX, translateX));
    }
    
    // Vertical constraints
    if (scaledImageHeight <= containerHeight) {
      // Image is smaller than container, center it
      translateY = (containerHeight - scaledImageHeight) / 2;
    } else {
      // Image is larger than container, allow panning with constraints
      const minVisiblePercent = 0.2;
      const minVisibleHeight = scaledImageHeight * minVisiblePercent;
      
      // Calculate bounds for Y translation
      const maxTranslateY = minVisibleHeight;
      const minTranslateY = containerHeight - scaledImageHeight - minVisibleHeight;
      
      // Apply constraints
      translateY = Math.max(minTranslateY, Math.min(maxTranslateY, translateY));
    }
  }

  function updateImageTransform() {
    if (!mainImage) return;
    
    // CRITICAL: Always recalculate constraints before applying transform
    centerImageAndConstrain();
    
    mainImage.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
  }

  function handleImageLoad() {
    calculateInitialScale();
    updateImageTransform();
  }

  function handleMouseDown(event: MouseEvent) {
    if (event.button !== 0) return; // Only left mouse button
    
    isDragging = true;
    dragStartX = event.clientX;
    dragStartY = event.clientY;
    dragStartTranslateX = translateX;
    dragStartTranslateY = translateY;
    
    event.preventDefault();
  }

  function handleMouseMove(event: MouseEvent) {
    // Handle control visibility
    showControls = true;
    clearTimeout(controlsTimeout);
    
    if (fullscreenMode) {
      controlsTimeout = setTimeout(() => {
        showControls = false;
      }, 3000);
    }
    
    // Handle image dragging
    if (isDragging) {
      const deltaX = event.clientX - dragStartX;
      const deltaY = event.clientY - dragStartY;
      
      translateX = dragStartTranslateX + deltaX;
      translateY = dragStartTranslateY + deltaY;
      
      // Mark that user has panned
      userHasPanned = true;
      
      updateImageTransform();
    }
  }

  function handleMouseUp() {
    isDragging = false;
  }

  function resetImageTransform() {
    scale = initialScale;
    userHasPanned = false; // Reset pan state
    centerImageAndConstrain();
    updateImageTransform();
  }

  function zoomIn() {
    const rect = imageContainer.getBoundingClientRect();
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    
    const newScale = Math.min(MAX_ZOOM, scale * 1.2);
    
    if (newScale === scale) return; // Already at max zoom
    
    // CRITICAL: If zoom is triggered and scale is less than 1.25, then update to translate(0px, 0px)
    if (newScale < 1.25) {
      scale = newScale;
      translateX = 0;
      translateY = 0;
      updateImageTransform();
      return;
    }
    
    // CRITICAL: If pan has not been updated, then maintain translate(0px, 0px) at any zoom level
    if (!userHasPanned) {
      scale = newScale;
      translateX = 0;
      translateY = 0;
      updateImageTransform();
      return;
    }
    
    // Once pan has been updated by the user, then the logic should recalculate translate position 
    // to remain on focal point if scale is greater than 1.25
    const scaleChange = newScale / scale;
    
    // Zoom towards center
    translateX = centerX - (centerX - translateX) * scaleChange;
    translateY = centerY - (centerY - translateY) * scaleChange;
    
    scale = newScale;
    
    // IMPORTANT: Update constraints after zoom change
    updateImageTransform();
  }

  function zoomOut() {
    const rect = imageContainer.getBoundingClientRect();
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    
    const newScale = Math.max(MIN_ZOOM, scale / 1.2);
    
    if (newScale === scale) return; // Already at min zoom
    
    // CRITICAL: If zoom is triggered and scale is less than 1.25, then update to translate(0px, 0px)
    if (newScale < 1.25) {
      scale = newScale;
      translateX = 0;
      translateY = 0;
      updateImageTransform();
      return;
    }
    
    // CRITICAL: If pan has not been updated, then maintain translate(0px, 0px) at any zoom level
    if (!userHasPanned) {
      scale = newScale;
      translateX = 0;
      translateY = 0;
      updateImageTransform();
      return;
    }
    
    // Once pan has been updated by the user, then the logic should recalculate translate position 
    // to remain on focal point if scale is greater than 1.25
    const scaleChange = newScale / scale;
    
    // Zoom towards center
    translateX = centerX - (centerX - translateX) * scaleChange;
    translateY = centerY - (centerY - translateY) * scaleChange;
    
    scale = newScale;
    
    // IMPORTANT: Recenter and constrain after zoom change
    updateImageTransform();
  }

  async function toggleFollow() {
    if (!$user) return;
    
    try {
      if (isFollowing) {
        await supabase
          .from('piece_followers')
          .delete()
          .eq('piece_id', params.id)
          .eq('profile_id', $user.id);
      } else {
        await supabase
          .from('piece_followers')
          .insert({
            piece_id: params.id,
            profile_id: $user.id
          });
      }
      
      isFollowing = !isFollowing;
      if (piece) {
        piece.follower_count += isFollowing ? 1 : -1;
      }
    } catch (e: any) {
      console.error('Error toggling follow:', e);
    }
  }

  function toggleFullscreen() {
    if (!document.fullscreenElement) {
      viewerElement.requestFullscreen();
      fullscreenMode = true;
    } else {
      document.exitFullscreen();
      fullscreenMode = false;
    }
  }

  function handleKeydown(event: KeyboardEvent) {
    switch (event.key) {
      case 'Escape':
        if (fullscreenMode) {
          document.exitFullscreen();
        }
        break;
      case 'f':
      case 'F':
        toggleFullscreen();
        break;
      case ' ':
        event.preventDefault();
        // Toggle audio/video play/pause
        if (videoElement) {
          if (videoElement.paused) {
            videoElement.play();
          } else {
            videoElement.pause();
          }
        } else {
          // If no video, check for audio
          const audio = viewerElement.querySelector('audio') as HTMLAudioElement;
          if (audio) {
            if (audio.paused) {
              audio.play();
            } else {
              audio.pause();
            }
          }
        }
        break;
      case '+':
      case '=':
        event.preventDefault();
        if (piece.image_url && !piece.video_url) {
          zoomIn();
        }
        break;
      case '-':
        event.preventDefault();
        if (piece.image_url && !piece.video_url) {
          zoomOut();
        }
        break;
      case '0':
        event.preventDefault();
        if (piece.image_url && !piece.video_url) {
          resetImageTransform();
        }
        break;
    }
  }

  // Handle window resize to recalculate constraints
  function handleResize() {
    if (mainImage && imageContainer) {
      // Recalculate initial scale in case container size changed
      calculateInitialScale();
      // Update constraints for current zoom level
      updateImageTransform();
    }
  }

  onMount(() => {
    if (params.id) {
      loadPiece();
    }

    // Listen for fullscreen changes
    document.addEventListener('fullscreenchange', () => {
      fullscreenMode = !!document.fullscreenElement;
      // Recalculate constraints when entering/exiting fullscreen
      if (mainImage && imageContainer) {
        setTimeout(() => {
          calculateInitialScale();
          updateImageTransform();
        }, 100); // Small delay to ensure fullscreen transition is complete
      }
    });

    // Add keyboard listeners
    document.addEventListener('keydown', handleKeydown);
    
    // Add mouse event listeners for dragging
    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);

    // Add resize listener to recalculate constraints
    window.addEventListener('resize', handleResize);

    return () => {
      document.removeEventListener('keydown', handleKeydown);
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
      window.removeEventListener('resize', handleResize);
      clearTimeout(controlsTimeout);
    };
  });

  $: if (params.id) {
    loadPiece();
  }

</script>

<div 
  class="piece-viewer" 
  class:fullscreen={fullscreenMode}
  bind:this={viewerElement}
>
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading artwork...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Artwork Not Found</h2>
        <p>{error}</p>
        <a href="/explore" use:link class="primary">Explore Artworks</a>
      </div>
    </div>
  {:else if piece}
    <!-- Viewer Controls -->
    <div class="viewer-controls" class:hidden={fullscreenMode && !showControls}>
      <div class="controls-left">
        <a href="/piece/{piece.id}" use:link class="back-button" title="Back to details">
          <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
            <path d="M19 12H5"></path>
            <polyline points="12 19 5 12 12 5"></polyline>
          </svg>
          {#if !fullscreenMode}
            <span>Back to Details</span>
          {/if}
        </a>
      </div>

      <div class="controls-center">
        <h1 class="viewer-title">{piece.title}</h1>
      </div>

      <div class="controls-right">
        {#if piece.image_url && !piece.video_url}
          <!-- Image Controls -->
          <div class="image-controls">
            <button 
              class="control-button" 
              on:click={zoomOut} 
              title="Zoom out (-)"
              disabled={scale <= MIN_ZOOM}
            >
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <circle cx="11" cy="11" r="8"></circle>
                <path d="M21 21l-4.35-4.35"></path>
                <line x1="8" y1="11" x2="14" y2="11"></line>
              </svg>
            </button>
            
            <span class="zoom-level">{Math.round(scale * 100)}%</span>
            
            <button 
              class="control-button" 
              on:click={zoomIn} 
              title="Zoom in (+)"
              disabled={scale >= MAX_ZOOM}
            >
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <circle cx="11" cy="11" r="8"></circle>
                <path d="M21 21l-4.35-4.35"></path>
                <line x1="11" y1="8" x2="11" y2="14"></line>
                <line x1="8" y1="11" x2="14" y2="11"></line>
              </svg>
            </button>
            
            <button class="control-button" on:click={resetImageTransform} title="Reset zoom (0)">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M1 4v6h6"></path>
                <path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"></path>
              </svg>
            </button>
          </div>
        {/if}

        {#if $user}
          <button 
            class="follow-button" 
            class:following={isFollowing}
            on:click={toggleFollow}
            title={isFollowing ? 'Unfollow' : 'Follow'}
          >
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill={isFollowing ? "currentColor" : "none"}>
              <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
            </svg>
            {#if !fullscreenMode}
              <span>{isFollowing ? 'Following' : 'Follow'}</span>
            {/if}
          </button>
        {/if}

        <button class="fullscreen-button" on:click={toggleFullscreen} title="Toggle fullscreen (F)">
          {#if fullscreenMode}
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M8 3v3a2 2 0 0 1-2 2H3"></path>
              <path d="M21 8h-3a2 2 0 0 1-2-2V3"></path>
              <path d="M3 16h3a2 2 0 0 1 2 2v3"></path>
              <path d="M16 21v-3a2 2 0 0 1 2-2h3"></path>
            </svg>
          {:else}
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M8 3H5a2 2 0 0 0-2 2v3"></path>
              <path d="M21 8V5a2 2 0 0 0-2-2h-3"></path>
              <path d="M3 16v3a2 2 0 0 0 2 2h3"></path>
              <path d="M16 21h3a2 2 0 0 0 2-2v-3"></path>
            </svg>
          {/if}
          {#if !fullscreenMode}
            <span>Fullscreen</span>
          {/if}
        </button>
      </div>
    </div>

    <!-- Main Content Area -->
    <div class="viewer-content">
      <!-- Video Display (prioritized over image) -->
      {#if piece.video_url}
        <div class="video-container" in:fly={{ y: 20, duration: 300 }}>
          <video 
            bind:this={videoElement}
            src={piece.video_url} 
            controls 
            class="main-video"
            poster={piece.image_url}
          >
            Your browser does not support the video tag.
          </video>
        </div>
      <!-- Image Display (if no video) -->
      {:else if piece.image_url}
        <div 
          class="image-container" 
          bind:this={imageContainer}
          on:mousedown={handleMouseDown}
          in:fly={{ y: 20, duration: 300 }}
        >
          <img 
            bind:this={mainImage}
            src={piece.image_url} 
            alt={piece.title}
            class="main-image"
            class:dragging={isDragging}
            loading="eager"
            on:load={handleImageLoad}
            draggable="false"
          />
        </div>
      {/if}

      <!-- Audio Player (if not a video, or if audio is a separate track) -->
      {#if piece.audio_url && !piece.video_url}
        <div class="audio-container" in:fly={{ y: 20, duration: 300, delay: 100 }}>
          <div class="audio-player">
            <div class="audio-info">
              <h3>Audio Experience</h3>
              <p>Listen to the piece while viewing</p>
            </div>
            <audio controls src={piece.audio_url} class="audio-element">
              Your browser does not support the audio element.
            </audio>
          </div>
        </div>
      {/if}

      <!-- Text Content -->
      {#if piece.piece_poem}
        <div class="text-container" in:fly={{ y: 20, duration: 300, delay: 200 }}>
          <div class="text-content">
            <h3>Piece Poem</h3>
            <div class="poem-text">
              {piece.piece_poem}
            </div>
          </div>
        </div>
      {/if}

      <!-- Contributors Info -->
      {#if piece.contributors && piece.contributors.length > 0}
        <div class="contributors-container" in:fly={{ y: 20, duration: 300, delay: 300 }}>
          <h3>Contributors</h3>
          <div class="contributors-list">
            {#each piece.contributors as contributor}
              <div class="contributor-item">
                <span class="contributor-name">{contributor.name}</span>
                <span class="contributor-role">{contributor.role}</span>
              </div>
            {/each}
          </div>
        </div>
      {/if}
    </div>

    <!-- Keyboard Shortcuts Help -->
    {#if !fullscreenMode}
      <div class="shortcuts-help">
        <div class="shortcuts-content">
          <h4>Controls</h4>
          <div class="shortcuts-list">
            <div class="shortcut">
              <kbd>F</kbd>
              <span>Fullscreen</span>
            </div>
            <div class="shortcut">
              <kbd>Space</kbd>
              <span>Play/pause</span>
            </div>
            {#if piece.image_url && !piece.video_url}
              <div class="shortcut">
                <kbd>+/-</kbd>
                <span>Zoom (50%-300%)</span>
              </div>
              <div class="shortcut">
                <kbd>0</kbd>
                <span>Reset</span>
              </div>
              <div class="shortcut">
                <span class="mouse-icon">🖱️</span>
                <span>Drag to pan</span>
              </div>
            {/if}
          </div>
        </div>
      </div>
    {/if}
  {/if}
</div>

<style>
  .piece-viewer {
    min-height: 100vh;
    background-color: #000;
    color: white;
    display: flex;
    flex-direction: column;
    position: relative;
  }

  .piece-viewer.fullscreen {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    z-index: 9999;
    overflow-y: scroll;
  }

  .loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    gap: var(--space-4);
  }

  .loading-spinner {
    width: 40px;
    height: 40px;
    border: 3px solid rgba(255, 255, 255, 0.3);
    border-top: 3px solid white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .error-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    padding: var(--space-6);
  }

  .error-card {
    background-color: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    max-width: 400px;
    backdrop-filter: blur(10px);
  }

  .error-card h2 {
    color: #ff6b6b;
    margin-bottom: var(--space-4);
  }

  .viewer-controls {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    background: linear-gradient(to bottom, rgba(0, 0, 0, 0.8), transparent);
    padding: var(--space-4);
    display: flex;
    justify-content: space-between;
    align-items: center;
    z-index: 100;
    transition: opacity 0.3s ease;
  }

  .viewer-controls.hidden {
    opacity: 0;
    pointer-events: none;
  }

  .controls-left,
  .controls-right {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .controls-center {
    text-align: center;
    flex: 1;
    margin: 0 var(--space-6);
    width: fit-content;
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
  }

  .viewer-title {
    font-size: 1.2rem;
    font-weight: 700;
    margin: 0 0 var(--space-1) 0;
    color: white;
  }

  .viewer-organizer {
    font-size: 0.875rem;
    color: rgba(255, 255, 255, 0.8);
    margin: 0;
  }

  .image-controls {
    display: flex;
    align-items: center;
    gap: 4px;
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: var(--radius-md);
    padding: var(--space-2);
    backdrop-filter: blur(10px);
  }

  .control-button {
    background: none;
    border: none;
    color: white;
    padding: var(--space-1);
    border-radius: 4px;
    cursor: pointer;
    transition: background-color 0.2s, opacity 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .control-button:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.2);
  }

  .control-button:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }

  .zoom-level {
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.8);
    min-width: 40px;
    text-align: center;
  }

  .back-button,
  .follow-button,
  .fullscreen-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    color: white;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    transition: all 0.2s;
    backdrop-filter: blur(10px);
    cursor: pointer;
    font-size: 12px;
  }

  .back-button:hover,
  .follow-button:hover,
  .fullscreen-button:hover {
    background: rgba(255, 255, 255, 0.2);
    border-color: rgba(255, 255, 255, 0.4);
  }

  .follow-button span,
  .fullscreen-button span {
  display: none;
  }

  .follow-button.following {
    background: rgba(34, 197, 94, 0.2);
    border-color: rgba(34, 197, 94, 0.4);
    color: #22c55e;
  }

  .viewer-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 80px 1rem 1rem;
    gap: var(--space-6);
    min-height: 100vh;
    overflow-y: auto;
  }

  .image-container {
    width: 100%;
    height: calc(100vh - 80px - 1rem);
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-lg);
    overflow: hidden;
    cursor: grab;
    position: relative;
  }

  .image-container:active {
    cursor: grabbing;
  }

  .main-image {
    max-width: none;
    max-height: none;
    width: auto;
    height: auto;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
    transform-origin: center center;
    transition: transform 0.1s ease-out;
    user-select: none;
    -webkit-user-drag: none;
  }

  .main-image.dragging {
    transition: none;
    cursor: grabbing;
  }

  .video-container {
    width: 100%;
    max-width: 1200px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-lg);
    overflow: hidden;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
  }

  .main-video {
    width: 100%;
    height: auto;
    max-height: 80vh;
    border-radius: var(--radius-lg);
  }

  .audio-container {
    width: 100%;
    max-width: 600px;
  }

  .audio-player {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: var(--radius-lg);
    padding: var(--space-4);
    backdrop-filter: blur(10px);
  }

  .audio-info {
    margin-bottom: var(--space-3);
  }

  .audio-info h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: white;
    visibility: hidden;
    position: absolute;
    left: -99999px;
  }

  .audio-info p {
    font-size: 0.875rem;
    color: rgba(255, 255, 255, 0.8);
    margin: 0;
  }

  .audio-info h3,
  .audio-info p {
    visibility: hidden;
    position: absolute;
    left: -99999px;
  }

  .audio-element {
    width: 100%;
    background: transparent;
  }

  .text-container {
    width: 100%;
    max-width: 800px;
  }

  .text-content {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    backdrop-filter: blur(10px);
  }

  .text-content h3 {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0 0 var(--space-4) 0;
    color: white;
  }

  .mission-text,
  .poem-text {
    font-size: 1.125rem;
    line-height: 1.8;
    color: rgba(255, 255, 255, 0.9);
  }

  .mission-text :global(p),
  .poem-text :global(p) {
    margin-bottom: 1rem;
  }

  .mission-text :global(ul), .mission-text :global(ol) {
    margin-bottom: 1rem;
    padding-left: 1.5rem;
  }

  .mission-text :global(li) {
    margin-bottom: 0.5rem;
  }

  .mission-text :global(a) {
    color: #93c5fd;
    text-decoration: none;
  }

  .mission-text :global(a:hover) {
    text-decoration: underline;
  }

  .mission-text :global(strong) {
    font-weight: 500;
    color: white;
  }

  .mission-text :global(em) {
    font-style: italic;
  }

  .contributors-container {
    width: 100%;
    max-width: 600px;
  }

  .contributors-container h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: white;
    text-align: center;
  }

  .contributors-list {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-3);
    justify-content: center;
  }

  .contributor-item {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: var(--radius-md);
    padding: var(--space-3);
    backdrop-filter: blur(10px);
    text-align: center;
  }

  .contributor-name {
    display: block;
    font-weight: 500;
    color: white;
    margin-bottom: var(--space-1);
  }

  .contributor-role {
    display: block;
    font-size: 0.875rem;
    color: rgba(255, 255, 255, 0.8);
  }

  .shortcuts-help {
    position: fixed;
    top: 5rem;
    left: var(--space-4);
    background: rgba(0, 0, 0, 0.8);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: var(--radius-lg);
    padding: var(--space-4);
    backdrop-filter: blur(10px);
    z-index: 50;
  }

  .shortcuts-content h4 {
    font-size: 0.875rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: white;
  }

  .shortcuts-list {
    display: flex;
    gap: var(--space-2);
  }

  .shortcut {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    font-size: 0.75rem;
  }

  .shortcut kbd {
    background: rgba(255, 255, 255, 0.2);
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 4px;
    padding: 2px 6px;
    font-family: monospace;
    font-size: 0.75rem;
    color: white;
    min-width: 24px;
    text-align: center;
  }

  .shortcut .mouse-icon {
    min-width: 24px;
    text-align: center;
    font-size: 0.875rem;
  }

  .shortcut span {
    color: rgba(255, 255, 255, 0.8);
  }

  /* Fullscreen adjustments */
  .piece-viewer.fullscreen .viewer-content {
    padding: var(--space-12) var(--space-6) var(--space-6) var(--space-6);
  }

  .piece-viewer.fullscreen .image-container {
    max-height: 80vh;
  }

  .piece-viewer.fullscreen .video-container {
    max-height: 80vh;
  }

  .piece-viewer.fullscreen .viewer-title {
    font-size: 1.25rem;
  }

  .piece-viewer.fullscreen .controls-center {
    margin: 0 var(--space-4);
  }

  @media (min-width: 769px) {
    .controls-left {
      flex-basis: 258px;
    }
  }

  /* Mobile responsiveness */
  @media (max-width: 768px) {
    .viewer-controls {
      flex-direction: column;
      gap: var(--space-3);
      padding: var(--space-3);
    }

    .controls-left,
    .controls-right {
      order: 2;
    }

    .controls-center {
      order: 1;
      margin: 0;
    }

    .viewer-title {
      font-size: 1.25rem;
    }

    .viewer-content {
      padding: var(--space-6) var(--space-4);
      padding-top: 140px; /* Account for taller mobile controls */
    }

    .shortcuts-help {
      display: none; /* Hide on mobile */
    }

    .back-button span,
    .follow-button span,
    .fullscreen-button span {
      display: none;
    }

    .image-controls {
      flex-direction: column;
      gap: var(--space-1);
    }

    .zoom-level {
      order: -1;
      margin-bottom: var(--space-1);
    }

    .video-container {
      width: 100%;
    }
  }

  /* Touch device optimizations */
  @media (hover: none) and (pointer: coarse) {
    .image-container {
      cursor: default;
    }
    
    .main-image.dragging {
      cursor: default;
    }
  }
</style>