<script lang="ts">
import { onMount, createEventDispatcher } from 'svelte';
import LayersPanel from './LayersPanel.svelte';
import CanvasArea from './CanvasArea.svelte';
import PropertiesPanel from './PropertiesPanel.svelte';
import EditingTimeline from './EditingTimeline.svelte';
import type { VideoClip } from './types';

export let initialData: any = null;
export let pieceId: string = '';
export let currentProjectStatus: string = '';

let clips: VideoClip[] = [];
let currentTime = 0;
let totalDuration = 60;
let isPlaying = false;
let selectedClip: VideoClip | null = null;
let activeTab: 'layers' | 'assets' = 'layers';
let zoomLevel = 100;
let timelineHeight = 220;

// Panel width state
let layersPanelWidth = 200;
let propertiesPanelWidth = 250;
const MIN_PANEL_WIDTH = 150;
const MAX_PANEL_WIDTH = 400;

// Panel resizing state
let isResizingLayersPanel = false;
let isResizingPropertiesPanel = false;
let resizeStartX = 0;
let resizeStartWidth = 0;

// Layer creation popup state
let showLayerPopup = false;
let popupStep: 'name' | 'content' = 'name';
let newLayerName = '';
let newLayerType: 'video' | 'image' | 'sticker' | 'music' | 'text' = 'video';
let newLayerContent = '';
let newLayerFile: File | null = null;

// Auto-save timer
let autoSaveTimer: number;
const AUTO_SAVE_INTERVAL = 10000; // 10 seconds

// Event dispatcher for saving data
const dispatch = createEventDispatcher();

onMount(() => {
  // Initialize with provided data or sample data
  if (initialData && initialData.clips && Array.isArray(initialData.clips)) {
    clips = initialData.clips;
    
    if (initialData.totalDuration) {
      totalDuration = initialData.totalDuration;
    }
  } else {
    clips = [];
  }
  
  // Add global mouse event listeners for panel resizing
  document.addEventListener('mousemove', handleGlobalMouseMove);
  document.addEventListener('mouseup', handleGlobalMouseUp);
  
  // Set up auto-save timer
  autoSaveTimer = setInterval(saveEditorData, AUTO_SAVE_INTERVAL);
  
  return () => {
    document.removeEventListener('mousemove', handleGlobalMouseMove);
    document.removeEventListener('mouseup', handleGlobalMouseUp);
    clearInterval(autoSaveTimer);
  };
});

// Save editor data
function saveEditorData() {
  const editorData = {
    clips,
    totalDuration,
    lastEditedAt: new Date().toISOString()
  };
  
  dispatch('save', editorData);
}

// Panel resizing functions
function startLayersPanelResize(event: MouseEvent) {
  isResizingLayersPanel = true;
  resizeStartX = event.clientX;
  resizeStartWidth = layersPanelWidth;
  event.preventDefault();
}

function startPropertiesPanelResize(event: MouseEvent) {
  isResizingPropertiesPanel = true;
  resizeStartX = event.clientX;
  resizeStartWidth = propertiesPanelWidth;
  event.preventDefault();
}

function handleGlobalMouseMove(event: MouseEvent) {
  if (isResizingLayersPanel) {
    const deltaX = event.clientX - resizeStartX;
    const newWidth = Math.max(
      MIN_PANEL_WIDTH,
      Math.min(MAX_PANEL_WIDTH, resizeStartWidth + deltaX)
    );
    layersPanelWidth = newWidth;
  }
  
  if (isResizingPropertiesPanel) {
    const deltaX = resizeStartX - event.clientX; // Reverse direction for right panel
    const newWidth = Math.max(
      MIN_PANEL_WIDTH,
      Math.min(MAX_PANEL_WIDTH, resizeStartWidth + deltaX)
    );
    propertiesPanelWidth = newWidth;
  }
}

function handleGlobalMouseUp() {
  isResizingLayersPanel = false;
  isResizingPropertiesPanel = false;
}

function selectClip(event) {
  selectedClip = event.detail;
}

function deleteClip(event) {
  const clipId = event.detail;
  clips = clips.filter(clip => clip.id !== clipId);
  if (selectedClip?.id === clipId) {
    selectedClip = null;
  }
  
  // Save after deleting a clip
  saveEditorData();
}

function createLayer(event) {
  const newClip = event.detail;
  
  // Initialize animation properties with defaults
  newClip.animation = newClip.animation || 'none';
  newClip.animationDuration = newClip.animationDuration || 1;
  newClip.animationDelay = newClip.animationDelay || 0;
  
  // Set defaults for image layers
  if (newClip.type === 'image' && newClip.sampleData?.type !== 'sticker') {
    newClip.position = { x: 50, y: 50 };
    newClip.scale = { x: 100, y: 100 };
  }
  
  // Set defaults for video layers
  if (newClip.type === 'video') {
    newClip.position = { x: 50, y: 50 };
    newClip.scale = { x: 100, y: 100 };
    newClip.mixBlendMode = 'normal';
  }
  
  clips = [...clips, newClip];
  selectedClip = newClip;
  
  // Save after creating a new layer
  saveEditorData();
}

function reorderLayers(event) {
  const { fromIndex, toIndex } = event.detail;
  
  if (fromIndex === toIndex) return;
  
  // Create a temporary array that represents the current visual order (sorted by layer descending)
  const visuallySortedClips = [...clips].sort((a, b) => b.layer - a.layer);
  
  // Find the dragged clip using fromIndex (which corresponds to the original clips array)
  const draggedClip = clips[fromIndex];
  if (!draggedClip) return;
  
  // Remove the dragged clip from the visually sorted array
  const draggedClipVisualIndex = visuallySortedClips.findIndex(clip => clip.id === draggedClip.id);
  if (draggedClipVisualIndex === -1) return;
  
  visuallySortedClips.splice(draggedClipVisualIndex, 1);
  
  // Insert the dragged clip at the new position in the visually sorted array
  visuallySortedClips.splice(toIndex, 0, draggedClip);
  
  // Reassign layer properties based on the new visual order
  // Top of visual list (index 0) gets highest layer number
  visuallySortedClips.forEach((clip, index) => {
    clip.layer = (visuallySortedClips.length - 1) - index;
  });
  
  // Update the main clips array with the reordered clips
  clips = [...visuallySortedClips];
  
  // Update selectedClip reference if it was the dragged clip
  if (selectedClip?.id === draggedClip.id) {
    selectedClip = draggedClip;
  }
  
  // Save after reordering layers
  saveEditorData();
}

async function addMediaFile(event) {
  const file = event.detail;
  if (!file) return;
  
  // Create a URL for the file
  const url = URL.createObjectURL(file);
  
  // Determine the file type
  const fileType = file.type.startsWith('audio/') ? 'audio' : 
                  file.type.startsWith('video/') ? 'video' : 
                  file.type.startsWith('image/') ? 'image' : null;
  
  if (!fileType) {
    console.error('Unsupported file type:', file.type);
    return;
  }
  
  // Create appropriate media element to get duration
  const mediaElement = fileType === 'audio' ? document.createElement('audio') : 
                      fileType === 'video' ? document.createElement('video') : null;
  
  if (mediaElement) {
    mediaElement.onloadedmetadata = () => {
      const duration = mediaElement.duration;
      
      const clip: VideoClip = {
        id: Math.random().toString(36).substr(2, 9),
        file,
        url,
        duration,
        contentStartTime: 0,
        contentEndTime: duration,
        layer: clips.length,
        timelineStart: 0,
        timelineEnd: duration,
        name: file.name,
        type: fileType,
        icon: fileType === 'audio' ? '🎵' : fileType === 'video' ? '▶️' : '🖼️',
        position: { x: 50, y: 50 },
        scale: { x: 100, y: 100 },
        rotation: 0,
        opacity: 1,
        volume: 1,
        brightness: 1,
        contrast: 1,
        saturation: 1,
        blur: 0,
        mixBlendMode: 'normal',
        // Initialize animation properties
        animation: 'none',
        animationDuration: 1,
        animationDelay: 0
      };
      
      clips = [...clips, clip];
      
      // Save after adding a media file
      saveEditorData();
    };
    
    mediaElement.src = url;
  } else if (fileType === 'image') {
    // For images, we don't need to get duration
    const clip: VideoClip = {
      id: Math.random().toString(36).substr(2, 9),
      file,
      url,
      duration: 10, // Default duration for images
      contentStartTime: 0,
      contentEndTime: 10,
      layer: clips.length,
      timelineStart: 0,
      timelineEnd: 10,
      name: file.name,
      type: 'image',
      icon: '🖼️',
      position: { x: 50, y: 50 },
      scale: { x: 100, y: 100 },
      rotation: 0,
      opacity: 1,
      brightness: 1,
      contrast: 1,
      saturation: 1,
      blur: 0,
      mixBlendMode: 'normal',
      // Initialize animation properties
      animation: 'none',
      animationDuration: 1,
      animationDelay: 0
    };
    
    clips = [...clips, clip];
    
    // Save after adding an image file
    saveEditorData();
  }
}

function updateClipProperty(event) {
  const { clipId, property, value } = event.detail;
  clips = clips.map(clip => {
    if (clip.id === clipId) {
      const updatedClip = { ...clip, [property]: value };
      
      if (selectedClip?.id === clipId) {
        selectedClip = updatedClip;
      }
      
      return updatedClip;
    }
    return clip;
  });
  
  // Save after updating a clip property
  // Throttle saveEditorData to avoid excessive calls
  if (!updateClipProperty._throttleTimeout) {
    updateClipProperty._throttleTimeout = setTimeout(() => {
      saveEditorData();
      updateClipProperty._throttleTimeout = null;
    }, 800);
  }
}

function updateClipTiming(event) {
  const { clipId, timelineStart, timelineEnd, contentStartTime, contentEndTime } = event.detail;
  clips = clips.map(clip => {
    if (clip.id === clipId) {
      const updatedClip = { ...clip };
      
      // Update timeline positions if provided
      if (timelineStart !== undefined) {
        updatedClip.timelineStart = timelineStart;
      }
      if (timelineEnd !== undefined) {
        updatedClip.timelineEnd = timelineEnd;
      }
      
      // Update content timing if provided
      if (contentStartTime !== undefined) {
        updatedClip.contentStartTime = Math.max(0, Math.min(contentStartTime, updatedClip.contentEndTime - 0.1));
      }
      if (contentEndTime !== undefined) {
        updatedClip.contentEndTime = Math.min(updatedClip.duration, Math.max(contentEndTime, updatedClip.contentStartTime + 0.1));
      }
      
      // If content timing changed, adjust timeline duration to match
      if (contentStartTime !== undefined || contentEndTime !== undefined) {
        const contentDuration = updatedClip.contentEndTime - updatedClip.contentStartTime;
        updatedClip.timelineEnd = updatedClip.timelineStart + contentDuration;
      }
      
      if (selectedClip?.id === clipId) {
        selectedClip = updatedClip;
      }
      
      return updatedClip;
    }
    return clip;
  });
  
  // Save after updating clip timing
  saveEditorData();
}

function handlePlayPause() {
  isPlaying = !isPlaying;
  if (isPlaying) {
    play();
  }
}

function play() {
  const interval = setInterval(() => {
    if (!isPlaying) {
      clearInterval(interval);
      return;
    }
    
    currentTime += 0.1;
    if (currentTime >= totalDuration) {
      currentTime = totalDuration;
      isPlaying = false;
      clearInterval(interval);
    }
  }, 100);
}

function handleSeek(event) {
  currentTime = event.detail;
}

function handleTimelineResize(event) {
  timelineHeight = event.detail;
}

function handleResetProperties() {
  selectedClip = null;
}

function handlePublishPiece(event) {
  dispatch('publishPiece', event.detail);
}

function handleKeyDown(event: KeyboardEvent) {
  // Check if the event originated from an input element
  const target = event.target as HTMLElement;
  if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT')) {
    // If we're in an input field, don't handle global shortcuts
    return;
  }

  if (event.key === 'Delete' || event.key === 'Backspace') {
    if (selectedClip && !showLayerPopup) {
      deleteClip({ detail: selectedClip.id });
    }
  }
  if (event.key === 'Escape' && showLayerPopup) {
    showLayerPopup = false;
  }
  
  // Save on Ctrl+S or Cmd+S
  if ((event.ctrlKey || event.metaKey) && event.key === 's') {
    event.preventDefault();
    saveEditorData();
  }
}

// Get active clips at current time for canvas rendering
$: activeClips = clips
  .filter(clip => currentTime >= clip.timelineStart && currentTime <= clip.timelineEnd)
  .sort((a, b) => a.layer - b.layer);
</script>

<svelte:window on:keydown={handleKeyDown} />

<div class="piece-editor" style="--timeline-height: {timelineHeight}px">
  <!-- Main Content Area -->
  <div class="main-content" style="height: calc(100vh - {timelineHeight}px - 8px)">
    <!-- Left Sidebar -->
    <div class="layers-panel-container" style="width: {layersPanelWidth}px">
      <LayersPanel 
        bind:clips
        bind:selectedClip
        bind:activeTab
        bind:showLayerPopup
        bind:popupStep
        bind:newLayerName
        bind:newLayerType
        bind:newLayerContent
        bind:newLayerFile
        {currentTime}
        on:selectClip={selectClip}
        on:deleteClip={deleteClip}
        on:createLayer={createLayer}
        on:addVideoFile={addMediaFile}
        on:reorderLayers={reorderLayers}
      />
      
      <!-- Layers Panel Resize Handle -->
      <div 
        class="panel-resize-handle panel-resize-handle-right"
        class:resizing={isResizingLayersPanel}
        on:mousedown={startLayersPanelResize}
      >
        <div class="resize-indicator">
          <div class="resize-dots">
            <div class="dot"></div>
            <div class="dot"></div>
            <div class="dot"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Canvas Area -->
    <CanvasArea 
      {timelineHeight} 
      {activeClips}
      {currentTime}
      {isPlaying}
      on:resetProperties={handleResetProperties}
    />

    <!-- Right Sidebar -->
    <div class="properties-panel-container" style="width: {propertiesPanelWidth}px">
      <!-- Properties Panel Resize Handle -->
      <div 
        class="panel-resize-handle panel-resize-handle-left"
        class:resizing={isResizingPropertiesPanel}
        on:mousedown={startPropertiesPanelResize}
      >
        <div class="resize-indicator">
          <div class="resize-dots">
            <div class="dot"></div>
            <div class="dot"></div>
            <div class="dot"></div>
          </div>
        </div>
      </div>
      
      <PropertiesPanel 
        {selectedClip}
        {totalDuration}
        {pieceId}
        {currentProjectStatus}
        on:updateClipProperty={updateClipProperty}
        on:publishPiece={handlePublishPiece}
      />
    </div>
  </div>

  <!-- Timeline -->
  <EditingTimeline 
    {clips}
    {currentTime}
    {totalDuration}
    {isPlaying}
    {selectedClip}
    bind:timelineHeight
    on:playPause={handlePlayPause}
    on:seek={handleSeek}
    on:selectClip={selectClip}
    on:timelineResize={handleTimelineResize}
    on:updateClipTiming={updateClipTiming}
    on:reorderLayers={reorderLayers}
  />
</div>

<style>
  .piece-editor {
    width: 100%;
    height: 100vh;
    background: #f5f5f5;
    display: flex;
    flex-direction: column;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    color: #333;
    user-select: none;
  }

  /* Main Content */
  .main-content {
    display: flex;
    min-height: 0;
    transition: height 0.1s ease;
  }

  /* Panel Containers */
  .layers-panel-container {
    position: relative;
    display: flex;
    flex-shrink: 0;
    transition: width 0.1s ease;
  }

  .properties-panel-container {
    position: relative;
    display: flex;
    flex-shrink: 0;
    transition: width 0.1s ease;
  }

  /* Panel Resize Handles */
  .panel-resize-handle {
    width: 6px;
    background: var(--color-neutral-400);
    border-left: 1px solid var(--color-neutral-400);
    border-right: 1px solid var(--color-neutral-400);
    cursor: ew-resize;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s ease;
    position: relative;
    z-index: 10;
    flex-shrink: 0;
  }

  .panel-resize-handle:hover {
    background: var(--color-neutral-500);
  }

  .panel-resize-handle.resizing {
    background: var(--color-neutral-600);
  }

  .panel-resize-handle-right {
    border-left: none;
  }

  .panel-resize-handle-left {
    border-right: none;
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
    flex-direction: column;
    gap: 3px;
    align-items: center;
  }

  .dot {
    width: 3px;
    height: 3px;
    border-radius: 50%;
    background: var(--color-neutral-100);
    transition: background 0.2s ease;
  }

  .panel-resize-handle:hover .dot {
    background: var(--color-neutral-100);
  }

  .panel-resize-handle.resizing .dot {
    background: var(--color-neutral-100);
  }

  /* Prevent text selection during resize */
  .panel-resize-handle.resizing,
  .panel-resize-handle.resizing * {
    user-select: none;
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
  }
</style>