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

// Create a named version
function createNamedVersion() {
  const editorData = {
    clips,
    totalDuration,
    lastEditedAt: new Date().toISOString()
  };
  
  dispatch('createNamedVersion', editorData);
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
        icon: fileType === 'audio' ? 
          '<svg width="19" height="15" viewBox="0 0 19 15" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M11.3009 14.9992C10.4759 14.9992 9.7696 14.7054 9.18211 14.1179C8.59461 13.5304 8.30086 12.8242 8.30086 11.9992C8.30086 11.1742 8.59461 10.4679 9.18211 9.88041C9.7696 9.29291 10.4759 8.99916 11.3009 8.99916C11.6842 8.99916 12.048 9.06741 12.3924 9.20391C12.7365 9.34041 13.0394 9.54524 13.3009 9.81841V1.49916C13.3009 1.27032 13.379 1.07849 13.5354 0.923656C13.6917 0.768822 13.8854 0.691406 14.1166 0.691406H17.3794C17.6104 0.691406 17.8024 0.768822 17.9556 0.923656C18.1089 1.07849 18.1856 1.27032 18.1856 1.49916V2.19141C18.1856 2.42024 18.1082 2.61207 17.9534 2.76691C17.7985 2.92174 17.6067 2.99916 17.3779 2.99916H14.3009V11.9992C14.3009 12.8242 14.0071 13.5304 13.4196 14.1179C12.8321 14.7054 12.1259 14.9992 11.3009 14.9992ZM4.03936 4.71266C3.16236 5.58949 2.45469 6.60132 1.91636 7.74816C1.37786 8.89499 1.07402 10.1222 1.00486 11.4299C0.997022 11.5851 0.945188 11.7187 0.849355 11.8309C0.753522 11.9431 0.634772 11.9992 0.493105 11.9992C0.338105 11.9992 0.216022 11.9389 0.126855 11.8184C0.0376884 11.6979 -0.0029782 11.5601 0.00485513 11.4049C0.0868551 9.95491 0.422355 8.59757 1.01136 7.33291C1.60052 6.06807 2.37202 4.95874 3.32586 4.00491C4.27969 3.05107 5.38577 2.28282 6.64411 1.70016C7.90244 1.11749 9.25661 0.785073 10.7066 0.702907C10.8618 0.69524 10.9996 0.735989 11.1201 0.825156C11.2406 0.914156 11.3009 1.03307 11.3009 1.18191C11.3009 1.33057 11.2448 1.45266 11.1326 1.54816C11.0204 1.64366 10.8868 1.69524 10.7316 1.70291C9.42394 1.77224 8.20086 2.07199 7.06236 2.60216C5.92402 3.13216 4.91636 3.83566 4.03936 4.71266ZM6.96061 7.65291C6.46311 8.15041 6.05794 8.72316 5.74511 9.37116C5.43227 10.0193 5.24511 10.7177 5.18361 11.4664C5.15861 11.6212 5.09819 11.7487 5.00236 11.8489C4.90652 11.9491 4.78777 11.9992 4.64611 11.9992C4.50444 11.9992 4.38677 11.9431 4.29311 11.8309C4.1996 11.7187 4.15669 11.5915 4.16436 11.4492C4.22969 10.562 4.44536 9.73732 4.81136 8.97516C5.17752 8.21299 5.65611 7.53641 6.24711 6.94541C6.83811 6.35424 7.51469 5.87566 8.27686 5.50966C9.03902 5.14366 9.86369 4.92799 10.7509 4.86266C10.8932 4.85499 11.0204 4.89749 11.1326 4.99016C11.2448 5.08282 11.3009 5.20074 11.3009 5.34391C11.3009 5.48707 11.2508 5.60632 11.1506 5.70166C11.0504 5.79699 10.9229 5.85707 10.7681 5.88191C10.0194 5.94341 9.32202 6.12957 8.67586 6.44041C8.02969 6.75141 7.45794 7.15557 6.96061 7.65291Z" fill="#1C1B1F"/></svg>' 
          : fileType === 'video' ? 
          '<svg width="24" height="18" viewBox="0 0 24 18" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10.2766 12.9663L15.8028 9.435C15.9582 9.32604 16.0359 9.18104 16.0359 9C16.0359 8.81896 15.9582 8.67396 15.8028 8.565L10.2766 5.03375C10.1001 4.92 9.92656 4.90958 9.75594 5.0025C9.58531 5.09542 9.5 5.24281 9.5 5.44469V12.5553C9.5 12.7572 9.58531 12.9046 9.75594 12.9975C9.92656 13.0904 10.1001 13.08 10.2766 12.9663ZM2.76937 17.75C2.19396 17.75 1.71354 17.5573 1.32812 17.1719C0.942708 16.7865 0.75 16.306 0.75 15.7306V2.26937C0.75 1.69396 0.942708 1.21354 1.32812 0.828125C1.71354 0.442708 2.19396 0.25 2.76937 0.25H21.2306C21.806 0.25 22.2865 0.442708 22.6719 0.828125C23.0573 1.21354 23.25 1.69396 23.25 2.26937V15.7306C23.25 16.306 23.0573 16.7865 22.6719 17.1719C22.2865 17.5573 21.806 17.75 21.2306 17.75H2.76937ZM2.76937 16.5H21.2306C21.4231 16.5 21.5995 16.4199 21.7597 16.2597C21.9199 16.0995 22 15.9231 22 15.7306V2.26937C22 2.07687 21.9199 1.90052 21.7597 1.74031C21.5995 1.5801 21.4231 1.5 21.2306 1.5H2.76937C2.57687 1.5 2.40052 1.5801 2.24031 1.74031C2.0801 1.90052 2 2.07687 2 2.26937V15.7306C2 15.9231 2.0801 16.0995 2.24031 16.2597C2.40052 16.4199 2.57687 16.5 2.76937 16.5Z" fill="#1C1B1F"/></svg>' 
          : 
          '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M2.01937 20C1.44396 20 0.963542 19.8073 0.578125 19.4219C0.192708 19.0365 0 18.556 0 17.9806V2.01937C0 1.44396 0.192708 0.963542 0.578125 0.578125C0.963542 0.192708 1.44396 0 2.01937 0H17.9806C18.556 0 19.0365 0.192708 19.4219 0.578125C19.8073 0.963542 20 1.44396 20 2.01937V17.9806C20 18.556 19.8073 19.0365 19.4219 19.4219C19.0365 19.8073 18.556 20 17.9806 20H2.01937ZM2.01937 18.75H17.9806C18.1731 18.75 18.3495 18.6699 18.5097 18.5097C18.6699 18.3495 18.75 18.1731 18.75 17.9806V2.01937C18.75 1.82687 18.6699 1.65052 18.5097 1.49031C18.3495 1.3301 18.1731 1.25 17.9806 1.25H2.01937C1.82687 1.25 1.65052 1.3301 1.49031 1.49031C1.3301 1.65052 1.25 1.82687 1.25 2.01937V17.9806C1.25 18.1731 1.3301 18.3495 1.49031 18.5097C1.65052 18.6699 1.82687 18.75 2.01937 18.75ZM5.38469 15.625H14.8078C15.0097 15.625 15.1571 15.5345 15.25 15.3534C15.3429 15.1724 15.3301 14.9936 15.2116 14.8172L12.6875 11.4256C12.5785 11.2908 12.444 11.2234 12.2838 11.2234C12.1233 11.2234 11.9886 11.2908 11.8797 11.4256L9.01437 15.0481L7.23063 12.8919C7.12167 12.7733 6.99115 12.7141 6.83906 12.7141C6.68677 12.7141 6.55615 12.7814 6.44719 12.9159L5.00469 14.8172C4.8701 14.9936 4.84927 15.1724 4.94219 15.3534C5.03531 15.5345 5.18281 15.625 5.38469 15.625Z" fill="#1C1B1F"/></svg>',
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
      icon: '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M2.01937 20C1.44396 20 0.963542 19.8073 0.578125 19.4219C0.192708 19.0365 0 18.556 0 17.9806V2.01937C0 1.44396 0.192708 0.963542 0.578125 0.578125C0.963542 0.192708 1.44396 0 2.01937 0H17.9806C18.556 0 19.0365 0.192708 19.4219 0.578125C19.8073 0.963542 20 1.44396 20 2.01937V17.9806C20 18.556 19.8073 19.0365 19.4219 19.4219C19.0365 19.8073 18.556 20 17.9806 20H2.01937ZM2.01937 18.75H17.9806C18.1731 18.75 18.3495 18.6699 18.5097 18.5097C18.6699 18.3495 18.75 18.1731 18.75 17.9806V2.01937C18.75 1.82687 18.6699 1.65052 18.5097 1.49031C18.3495 1.3301 18.1731 1.25 17.9806 1.25H2.01937C1.82687 1.25 1.65052 1.3301 1.49031 1.49031C1.3301 1.65052 1.25 1.82687 1.25 2.01937V17.9806C1.25 18.1731 1.3301 18.3495 1.49031 18.5097C1.65052 18.6699 1.82687 18.75 2.01937 18.75ZM5.38469 15.625H14.8078C15.0097 15.625 15.1571 15.5345 15.25 15.3534C15.3429 15.1724 15.3301 14.9936 15.2116 14.8172L12.6875 11.4256C12.5785 11.2908 12.444 11.2234 12.2838 11.2234C12.1233 11.2234 11.9886 11.2908 11.8797 11.4256L9.01437 15.0481L7.23063 12.8919C7.12167 12.7733 6.99115 12.7141 6.83906 12.7141C6.68677 12.7141 6.55615 12.7814 6.44719 12.9159L5.00469 14.8172C4.8701 14.9936 4.84927 15.1724 4.94219 15.3534C5.03531 15.5345 5.18281 15.625 5.38469 15.625Z" fill="#1C1B1F"/></svg>',
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
  
  // Create named version on Ctrl+Shift+S or Cmd+Shift+S
  if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.key === 's') {
    event.preventDefault();
    createNamedVersion();
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
        on:createNamedVersion={createNamedVersion}
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
    background: #fbfbfb;
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