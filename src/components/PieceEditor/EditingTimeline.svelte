<script lang="ts">
  import { onMount } from 'svelte';
  import type { VideoClip } from './types';
  import { createEventDispatcher } from 'svelte';

  export let clips: VideoClip[] = [];
  export let currentTime = 0;
  export let totalDuration = 60;
  export let isPlaying = false;
  export let selectedClip: VideoClip | null = null;
  export let timelineHeight = 150;

  let timelineContainer: HTMLElement;

  // Timeline resize functionality
  let isResizing = false;
  let resizeStartY = 0;
  let resizeStartHeight = 0;
  const MIN_TIMELINE_HEIGHT = 100;
  const MAX_TIMELINE_HEIGHT = 400;

  // Timeline scrubbing functionality
  let isScrubbing = false;

  // Layer dragging functionality
  let isDraggingLayer = false;
  let draggedClip: VideoClip | null = null;
  let dragStartX = 0;
  let dragStartTimelineStart = 0;
  let dragOffset = 0;

  // Layer resizing functionality
  let isResizingLayer = false;
  let resizeDirection: 'left' | 'right' | null = null;
  let resizeStartWidth = 0;
  let resizeStartLeft = 0;
  let resizeStartContentStartTime = 0;
  let resizeStartContentEndTime = 0;

  const LAYER_HEIGHT = 40;
  const PIXELS_PER_SECOND = 20;
  const RESIZE_HANDLE_WIDTH = 8;

  const dispatch = createEventDispatcher();

  onMount(() => {
    // Add global mouse event listeners
    document.addEventListener('mousemove', handleGlobalMouseMove);
    document.addEventListener('mouseup', handleGlobalMouseUp);
    document.addEventListener('keydown', handleGlobalKeyDown);
    
    return () => {
      document.removeEventListener('mousemove', handleGlobalMouseMove);
      document.removeEventListener('mouseup', handleGlobalMouseUp);
      document.removeEventListener('keydown', handleGlobalKeyDown);
    };
  });

  function formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    const frames = Math.floor((seconds % 1) * 30);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}:${frames.toString().padStart(2, '0')}`;
  }

  function playPause() {
    dispatch('playPause');
  }

  function backToStart() {
    dispatch('seek', 0);
  }

  function pause() {
    if (isPlaying) {
      dispatch('playPause');
    }
  }

  function stop() {
    if (isPlaying) {
      dispatch('playPause');
    }
    dispatch('seek', 0);
  }

  function handleGlobalKeyDown(event: KeyboardEvent) {
    // Check if the event originated from an input element
    const target = event.target as HTMLElement;
    if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA')) {
      // If we're in an input field, don't handle global shortcuts
      return;
    }

    // Handle spacebar for play/pause
    if (event.code === 'Space') {
      event.preventDefault();
      playPause();
    }
  }

  function seek(event: MouseEvent) {
    if (isDraggingLayer || isResizingLayer) return;
    
    const rect = timelineContainer.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const timelineWidth = rect.width;
    const newTime = Math.max(0, Math.min(totalDuration, (x / timelineWidth) * totalDuration));
    dispatch('seek', newTime);
  }

  function selectClip(clip: VideoClip) {
    dispatch('selectClip', clip);
  }

  // Timeline resize functions
  function startResize(event: MouseEvent) {
    isResizing = true;
    resizeStartY = event.clientY;
    resizeStartHeight = timelineHeight;
    event.preventDefault();
  }

  // Timeline scrubbing functions
  function startScrubbing(event: MouseEvent) {
    if (isDraggingLayer || isResizingLayer) return;
    
    isScrubbing = true;
    seek(event); // Set initial time
    event.preventDefault();
  }

  // Layer dragging functions
  function startLayerDrag(event: MouseEvent, clip: VideoClip) {
    if (event.button !== 0) return;
    
    const rect = event.currentTarget.getBoundingClientRect();
    const mouseX = event.clientX - rect.left;
    
    if (mouseX <= RESIZE_HANDLE_WIDTH) {
      startLayerResize(event, clip, 'left');
      return;
    } else if (mouseX >= rect.width - RESIZE_HANDLE_WIDTH) {
      startLayerResize(event, clip, 'right');
      return;
    }
    
    isDraggingLayer = true;
    draggedClip = clip;
    dragStartX = event.clientX;
    dragStartTimelineStart = clip.timelineStart;
    
    const timelineRect = timelineContainer.getBoundingClientRect();
    const clipStartPixel = clip.timelineStart * PIXELS_PER_SECOND;
    dragOffset = event.clientX - timelineRect.left - clipStartPixel;
    
    selectClip(clip);
    event.preventDefault();
    event.stopPropagation();
  }

  // Layer resizing functions
  function startLayerResize(event: MouseEvent, clip: VideoClip, direction: 'left' | 'right') {
    isResizingLayer = true;
    resizeDirection = direction;
    draggedClip = clip;
    selectClip(clip);
    
    resizeStartWidth = clip.timelineEnd - clip.timelineStart;
    resizeStartLeft = clip.timelineStart;
    resizeStartContentStartTime = clip.contentStartTime || 0;
    resizeStartContentEndTime = clip.contentEndTime || clip.duration;
    
    event.preventDefault();
    event.stopPropagation();
  }

  function handleGlobalMouseMove(event: MouseEvent) {
    if (isResizing) {
      const deltaY = resizeStartY - event.clientY;
      const newHeight = Math.max(
        MIN_TIMELINE_HEIGHT,
        Math.min(MAX_TIMELINE_HEIGHT, resizeStartHeight + deltaY)
      );
      
      timelineHeight = newHeight;
      dispatch('timelineResize', newHeight);
    }
    
    // Handle timeline scrubbing
    if (isScrubbing) {
      seek(event);
    }
    
    if (isDraggingLayer && draggedClip) {
      const rect = timelineContainer.getBoundingClientRect();
      const mouseX = event.clientX - rect.left - dragOffset;
      const newTimelineStart = Math.max(0, mouseX / PIXELS_PER_SECOND);
      const clipDuration = draggedClip.timelineEnd - draggedClip.timelineStart;
      const newTimelineEnd = newTimelineStart + clipDuration;
      
      if (newTimelineEnd <= totalDuration) {
        dispatch('updateClipTiming', {
          clipId: draggedClip.id,
          timelineStart: newTimelineStart,
          timelineEnd: newTimelineEnd
        });
      }
    }
    
    if (isResizingLayer && draggedClip && resizeDirection) {
      const rect = timelineContainer.getBoundingClientRect();
      const mouseX = event.clientX - rect.left;
      const mouseTime = mouseX / PIXELS_PER_SECOND;
      
      if (resizeDirection === 'left') {
        const newTimelineStart = Math.max(0, Math.min(mouseTime, draggedClip.timelineEnd - 1));
        const deltaTimeline = newTimelineStart - draggedClip.timelineStart;
        const newContentStartTime = Math.max(0, Math.min(
          resizeStartContentStartTime + deltaTimeline,
          draggedClip.contentEndTime - 0.1
        ));
        
        dispatch('updateClipTiming', {
          clipId: draggedClip.id,
          timelineStart: newTimelineStart,
          contentStartTime: newContentStartTime
        });
      } else if (resizeDirection === 'right') {
        const newTimelineEnd = Math.min(totalDuration, Math.max(mouseTime, draggedClip.timelineStart + 1));
        const deltaTimeline = newTimelineEnd - draggedClip.timelineEnd;
        const newContentEndTime = Math.min(draggedClip.duration, Math.max(
          resizeStartContentEndTime + deltaTimeline,
          draggedClip.contentStartTime + 0.1
        ));
        
        dispatch('updateClipTiming', {
          clipId: draggedClip.id,
          timelineEnd: newTimelineEnd,
          contentEndTime: newContentEndTime
        });
      }
    }
  }

  function handleGlobalMouseUp() {
    isResizing = false;
    isScrubbing = false; // Stop scrubbing
    isDraggingLayer = false;
    isResizingLayer = false;
    resizeDirection = null;
    draggedClip = null;
  }

  $: playheadPosition = (currentTime / totalDuration) * 100;
  
  // Sort clips by layer order for timeline display (highest layer at top)
  $: sortedClips = [...clips].sort((a, b) => b.layer - a.layer);
</script>

<!-- Timeline Resize Handle -->
<div 
  class="timeline-resize-handle"
  class:resizing={isResizing}
  on:mousedown={startResize}
>
  <div class="resize-indicator">
    <div class="resize-dots">
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </div>
</div>

<!-- Timeline -->
<div class="timeline-section" style="height: {timelineHeight}px">
  <div class="timeline-controls">
    <div class="playback-controls">
      <button class="control-btn back-to-start" on:click={backToStart} title="Back to Start">
        ⏮️
      </button>
      <button class="control-btn play-pause" on:click={playPause} title="Play/Pause">
        {isPlaying ? '⏸️' : '▶️'}
      </button>
      <button class="control-btn pause" on:click={pause} title="Pause">
        ⏸️
      </button>
      <button class="control-btn stop" on:click={stop} title="Stop">
        ⏹️
      </button>
    </div>
    <div class="time-display">
      {formatTime(currentTime)} / {formatTime(totalDuration)}
    </div>
  </div>

  <div class="timeline-content">
    <!-- Time Ruler (Sticky) -->
    <div 
      class="time-ruler"
      on:mousedown={startScrubbing}
    >
      {#each Array(Math.ceil(totalDuration / 5)) as _, i}
        <div class="time-tick" style="left: {(i * 5 * PIXELS_PER_SECOND)}px">
          <div class="tick-mark"></div>
          {#if i % 2 === 0}
            <span class="tick-label">{i * 5}s</span>
          {/if}
        </div>
      {/each}
      
      <!-- Playhead in ruler -->
      <div 
        class="playhead-ruler" 
        style="left: {currentTime * PIXELS_PER_SECOND}px"
      >
        <div class="playhead-line-ruler"></div>
        <div class="playhead-handle-ruler"></div>
      </div>
    </div>

    <!-- Timeline Container (Scrollable) -->
    <div 
      class="timeline-container"
      bind:this={timelineContainer}
      on:click={seek}
    >
      <!-- Timeline Tracks -->
      <div class="timeline-tracks">
        {#each sortedClips as clip, index}
          <div class="timeline-track">
            <div class="track-content">
              <div
                class="timeline-clip"
                class:selected={selectedClip?.id === clip.id}
                class:dragging={isDraggingLayer && draggedClip?.id === clip.id}
                class:resizing={isResizingLayer && draggedClip?.id === clip.id}
                style="left: {clip.timelineStart * PIXELS_PER_SECOND}px; 
                       width: {(clip.timelineEnd - clip.timelineStart) * PIXELS_PER_SECOND}px;"
                on:mousedown={(e) => startLayerDrag(e, clip)}
                on:click|stopPropagation={() => selectClip(clip)}
              >
                <div class="resize-handle resize-handle-left"></div>
                <div class="clip-content">
                  <span class="clip-icon">{clip.icon}</span>
                  <span class="clip-name">{clip.name}</span>
                  <span class="layer-number">L{clip.layer}</span>
                </div>
                <div class="resize-handle resize-handle-right"></div>
              </div>
            </div>
          </div>
        {/each}
      </div>

      <!-- Playhead in tracks -->
      <div 
        class="playhead-tracks" 
        style="left: {currentTime * PIXELS_PER_SECOND}px"
      >
        <div class="playhead-line-tracks"></div>
      </div>
    </div>
  </div>
</div>

<style>
  /* Timeline Resize Handle */
  .timeline-resize-handle {
    height: 5px;
    background: var(--color-neutral-400);
    border-top: 1px solid var(--color-neutral-400);
    border-bottom: 1px solid var(--color-neutral-400);
    cursor: ns-resize;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s ease;
    position: relative;
  }

  .timeline-resize-handle:hover {
    background: var(--color-neutral-500);
  }

  .timeline-resize-handle.resizing {
    background: var(--color-neutral-800);
  }

  .resize-indicator {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
  }

  .resize-dots {
    display: flex;
    gap: 2px;
    align-items: center;
  }

  .dot {
    width: 2px;
    height: 2px;
    border-radius: 50%;
    background: var(--color-neutral-100);
    transition: background 0.2s ease;
  }

  .timeline-resize-handle:hover .dot {
    background: var(--color-neutral-100);
  }

  .timeline-resize-handle.resizing .dot {
    background: var(--color-neutral-200);
  }

  /* Timeline */
  .timeline-section {
    background: var(--color-neutral-100);
    border-top: 1px solid #d0d0d0;
    display: flex;
    flex-direction: column;
    transition: height 0.1s ease;
    min-height: 100px;
    z-index: 10;
  }

  .timeline-controls {
    height: 40px;
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 0 1rem;
    border-bottom: 1px solid #d0d0d0;
    flex-shrink: 0;
  }

  .playback-controls {
    display: flex;
    align-items: center;
    gap: 0.25rem;
  }

  .control-btn {
    background: none;
    border: none;
    font-size: 1.1rem;
    cursor: pointer;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    min-width: 32px;
    height: 32px;
  }

  .control-btn:hover {
    background: #f0f0f0;
  }

  .control-btn:active {
    background: #e0e0e0;
    transform: scale(0.95);
  }

  .control-btn.play-pause {
    font-size: 1.2rem;
  }

  .control-btn.back-to-start {
    font-size: 1rem;
  }

  .control-btn.pause {
    font-size: 1rem;
  }

  .control-btn.stop {
    font-size: 1rem;
    color: #666;
  }

  .control-btn.stop:hover {
    color: #333;
    background: #f0f0f0;
  }

  .timeline-actions {
    display: flex;
    align-items: center;
  }

  .timeline-btn {
    background: none;
    border: none;
    font-size: 1rem;
    cursor: pointer;
    padding: 0.25rem;
    border-radius: 4px;
    transition: background 0.2s ease;
  }

  .timeline-btn:hover {
    background: #f0f0f0;
  }

  .time-display {
    font-family: monospace;
    font-size: 0.8rem;
    color: #666;
    margin-left: auto;
    background: #f8f8f8;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    border: 1px solid #e0e0e0;
  }

  /* Timeline Content Container */
  .timeline-content {
    flex: 1;
    position: relative;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  /* Sticky Time Ruler */
  .time-ruler {
    height: 24px;
    position: sticky;
    top: 0;
    z-index: 20;
    border-bottom: 1px solid #e0e0e0;
    background: #f8f8f8;
    flex-shrink: 0;
    cursor: pointer;
    overflow: hidden;
  }

  .time-tick {
    position: absolute;
    height: 100%;
  }

  .tick-mark {
    width: 1px;
    height: 10px;
    background: #ccc;
    margin-top: 8px;
  }

  .tick-label {
    position: absolute;
    top: 2px;
    left: 4px;
    font-size: 0.7rem;
    color: #666;
  }

  /* Playhead in ruler */
  .playhead-ruler {
    position: absolute;
    top: 0;
    bottom: 0;
    pointer-events: none;
    z-index: 25;
  }

  .playhead-line-ruler {
    width: 2px;
    height: 100%;
    background: #007AFF;
  }

  .playhead-handle-ruler {
    position: absolute;
    top: -2px;
    left: -4px;
    width: 10px;
    height: 10px;
    background: #007AFF;
    border-radius: 50%;
  }

  /* Scrollable Timeline Container */
  .timeline-container {
    flex: 1;
    position: relative;
    overflow-x: auto;
    overflow-y: auto;
    background: var(--color-primary-00);
  }

  .timeline-tracks {
    padding-bottom: 50px;
  }

  .timeline-track {
    height: 32px;
    border-bottom: 1px solid #e0e0e0;
    position: relative;
    transition: all 0.2s;
  }

  .track-content {
    width: 100%;
    height: 100%;
    position: relative;
  }

  .timeline-clip {
    position: absolute;
    top: 4px;
    height: 24px;
    background: var(--color-neutral-800);
    border-radius: 2px;
    cursor: grab;
    transition: all 0.05s;
    display: flex;
    align-items: center;
    padding: 0 8px;
    min-width: 60px;
    overflow: hidden;
    position: relative;
  }

  .timeline-clip:hover {
    background: var(--color-neutral-700);
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }

  .timeline-clip.selected {
    background: var(--color-neutral-900);
    box-shadow: 0 0 0 2px var(--color-neutral-500);
  }

  .timeline-clip.dragging {
    cursor: grabbing;
    z-index: 10;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
  }

  .timeline-clip.resizing {
    z-index: 10;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
  }

  .resize-handle {
    position: absolute;
    top: 0;
    bottom: 0;
    width: 8px;
    cursor: ew-resize;
    background: transparent;
    transition: background 0.2s;
  }

  .resize-handle-left {
    left: 0;
    border-left: 2px solid transparent;
  }

  .resize-handle-right {
    right: 0;
    border-right: 2px solid transparent;
  }

  .timeline-clip:hover .resize-handle-left {
    border-left-color: rgba(255, 255, 255, 0.5);
  }

  .timeline-clip:hover .resize-handle-right {
    border-right-color: rgba(255, 255, 255, 0.5);
  }

  .timeline-clip.selected .resize-handle-left,
  .timeline-clip.selected .resize-handle-right {
    border-color: rgba(255, 255, 255, 0.8);
  }

  .clip-content {
    display: flex;
    align-items: center;
    gap: 4px;
    width: 100%;
    overflow: hidden;
    pointer-events: none;
  }

  .clip-icon {
    font-size: 0.7rem;
    flex-shrink: 0;
  }

  .clip-name {
    font-size: 0.7rem;
    color: white;
    font-weight: 500;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
    flex: 1;
  }

  .layer-number {
    font-size: 0.6rem;
    color: rgba(255, 255, 255, 0.8);
    font-weight: 600;
    background: rgba(255, 255, 255, 0.2);
    padding: 1px 4px;
    border-radius: 2px;
    flex-shrink: 0;
  }

  /* Playhead in tracks */
  .playhead-tracks {
    position: absolute;
    top: 0;
    bottom: 0;
    pointer-events: none;
    z-index: 15;
  }

  .playhead-line-tracks {
    width: 2px;
    height: 100%;
    background: #007AFF;
  }
</style>