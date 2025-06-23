<script lang="ts">
  import type { VideoClip } from './types';

  export let clips: VideoClip[] = [];
  export let selectedClip: VideoClip | null = null;
  export let activeTab: 'layers' | 'assets' = 'layers';
  export let showLayerPopup = false;
  export let popupStep: 'name' | 'content' = 'name';
  export let newLayerName = '';
  export let newLayerType: 'video' | 'image' | 'sticker' | 'music' | 'text' = 'video';
  export let newLayerContent = '';
  export let newLayerFile: File | null = null;
  export let currentTime = 0;

  let layerNameInput: HTMLInputElement;
  let textContentInput: HTMLTextAreaElement;
  let fileInput: HTMLInputElement;

  // Drag and drop state
  let draggedLayer: VideoClip | null = null;
  let dragOverIndex = -1;
  let isDragging = false;

  const layerTypes = [
    { value: 'video', label: 'Video', icon: '▶️', accept: 'video/*' },
    { value: 'image', label: 'Overlay Image', icon: '🖼️', accept: 'image/*' },
    { value: 'sticker', label: 'Sticker', icon: '🏷️', accept: 'image/png' },
    { value: 'music', label: 'Music', icon: '🎵', accept: 'audio/*' },
    { value: 'text', label: 'Text', icon: '📝', accept: '' }
  ];

  // Event dispatchers
  import { createEventDispatcher } from 'svelte';
  const dispatch = createEventDispatcher();

  function selectClip(clip: VideoClip) {
    dispatch('selectClip', clip);
  }

  function deleteClip(clipId: string) {
    dispatch('deleteClip', clipId);
  }

  function reorderLayers(fromIndex: number, toIndex: number) {
    dispatch('reorderLayers', { fromIndex, toIndex });
  }

  // Drag and drop functions
  function handleDragStart(event: DragEvent, clip: VideoClip, index: number) {
    if (!event.dataTransfer) return;
    
    draggedLayer = clip;
    isDragging = true;
    
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', clip.id);
    
    // Add visual feedback
    const target = event.target as HTMLElement;
    target.style.opacity = '0.5';
  }

  function handleDragEnd(event: DragEvent) {
    isDragging = false;
    draggedLayer = null;
    dragOverIndex = -1;
    
    // Reset visual feedback
    const target = event.target as HTMLElement;
    target.style.opacity = '1';
  }

  function handleDragOver(event: DragEvent, index: number) {
    event.preventDefault();
    if (!draggedLayer) return;
    
    dragOverIndex = index;
    
    if (event.dataTransfer) {
      event.dataTransfer.dropEffect = 'move';
    }
  }

  function handleDragLeave(event: DragEvent) {
    // Only clear dragOverIndex if we're leaving the entire layer item
    const target = event.target as HTMLElement;
    const relatedTarget = event.relatedTarget as HTMLElement;
    
    if (!target.contains(relatedTarget)) {
      dragOverIndex = -1;
    }
  }

  function handleDrop(event: DragEvent, dropIndex: number) {
    event.preventDefault();
    
    if (!draggedLayer) return;
    
    const draggedIndex = clips.findIndex(clip => clip.id === draggedLayer!.id);
    
    if (draggedIndex !== -1 && draggedIndex !== dropIndex) {
      reorderLayers(draggedIndex, dropIndex);
    }
    
    draggedLayer = null;
    dragOverIndex = -1;
    isDragging = false;
  }

  function openLayerPopup() {
    showLayerPopup = true;
    popupStep = 'name';
    newLayerName = '';
    newLayerType = 'video';
    newLayerContent = '';
    newLayerFile = null;
    
    setTimeout(() => {
      if (layerNameInput) {
        layerNameInput.focus();
      }
    }, 100);
  }

  function closeLayerPopup() {
    showLayerPopup = false;
    popupStep = 'name';
    newLayerName = '';
    newLayerType = 'video';
    newLayerContent = '';
    newLayerFile = null;
  }

  function proceedToContent() {
    if (!newLayerName.trim()) return;
    
    popupStep = 'content';
    
    setTimeout(() => {
      if (newLayerType === 'text' && textContentInput) {
        textContentInput.focus();
      } else if (newLayerType !== 'text' && fileInput) {
        fileInput.click();
      }
    }, 100);
  }

  function handleLayerFileUpload(event: Event) {
    const target = event.target as HTMLInputElement;
    if (target.files && target.files[0]) {
      newLayerFile = target.files[0];
    }
  }

  async function createLayer() {
    if (!newLayerName.trim()) return;
    
    if (newLayerType === 'text' && !newLayerContent.trim()) return;
    if (newLayerType !== 'text' && !newLayerFile) return;

    const layerTypeConfig = layerTypes.find(t => t.value === newLayerType);
    let duration = 10;
    let url: string | undefined = undefined;

    if (newLayerFile) {
      url = URL.createObjectURL(newLayerFile);
      
      if (newLayerType === 'video' || newLayerType === 'music') {
        const media = document.createElement(newLayerType === 'video' ? 'video' : 'audio');
        media.onloadedmetadata = () => {
          duration = media.duration;
        };
        media.src = url;
      }
    }

    const newClip: VideoClip = {
      id: Math.random().toString(36).substr(2, 9),
      name: newLayerName,
      type: newLayerType === 'music' ? 'audio' : newLayerType === 'sticker' ? 'image' : newLayerType,
      icon: layerTypeConfig?.icon || '▶️',
      layer: clips.length,
      timelineStart: currentTime,
      timelineEnd: currentTime + duration,
      duration: duration,
      contentStartTime: 0,
      contentEndTime: duration,
      file: newLayerFile,
      url: url,
      content: newLayerType === 'text' ? newLayerContent : undefined,
      // Set proper sampleData type for correct identification
      sampleData: {
        type: newLayerType === 'sticker' ? 'sticker' : 
              newLayerType === 'image' ? 'image' : 
              newLayerType === 'music' ? 'audio' : newLayerType
      }
    };
    
    dispatch('createLayer', newClip);
    closeLayerPopup();
  }

  function handleFileUpload(event: Event) {
    const target = event.target as HTMLInputElement;
    if (target.files) {
      Array.from(target.files).forEach(file => {
        dispatch('addVideoFile', file);
      });
    }
  }

  function handlePopupKeyDown(event: KeyboardEvent) {
    if (event.key === 'Enter') {
      if (popupStep === 'name') {
        proceedToContent();
      } else if (popupStep === 'content' && newLayerType === 'text') {
        createLayer();
      }
    }
  }

  $: selectedLayerType = layerTypes.find(t => t.value === newLayerType);

  // Sort clips by layer order for display (highest layer number at top)
  $: sortedClips = [...clips].sort((a, b) => b.layer - a.layer);
</script>

<div class="left-sidebar">
  <!-- Tab Navigation -->
  <div class="tab-nav">
    <button 
      class="tab-btn" 
      class:active={activeTab === 'layers'}
      on:click={() => activeTab = 'layers'}
    >
      Layers
    </button>
    <button 
      class="tab-btn" 
      class:active={activeTab === 'assets'}
      on:click={() => activeTab = 'assets'}
    >
      Assets
    </button>
  </div>

  <!-- Tab Content -->
  <div class="tab-content">
    {#if activeTab === 'layers'}
      <div class="layers-panel">
        <div class="layers-header">
          <button class="add-layer-btn" on:click={openLayerPopup}>
            + Add Layer
          </button>
          <div class="layer-info">
            <span class="layer-count">{clips.length} layers</span>
            <span class="layer-hint">Drag to reorder</span>
          </div>
        </div>
        
        <div class="layers-list">
          {#each sortedClips as clip, index}
            <div 
              class="layer-item" 
              class:selected={selectedClip?.id === clip.id}
              class:dragging={isDragging && draggedLayer?.id === clip.id}
              class:drag-over={dragOverIndex === index}
              draggable="true"
              on:click={() => selectClip(clip)}
              on:dragstart={(e) => handleDragStart(e, clip, index)}
              on:dragend={handleDragEnd}
              on:dragover={(e) => handleDragOver(e, index)}
              on:dragleave={handleDragLeave}
              on:drop={(e) => handleDrop(e, index)}
            >
              <div class="layer-drag-handle" title="Drag to reorder">
                <div class="drag-dots">
                  <div class="dot"></div>
                  <div class="dot"></div>
                  <div class="dot"></div>
                  <div class="dot"></div>
                  <div class="dot"></div>
                  <div class="dot"></div>
                </div>
              </div>
              
              <span class="layer-icon">{clip.icon}</span>
              
              <div class="layer-content">
                <span class="layer-name">{clip.name}</span>
                <span class="layer-info-text">Layer {clip.layer}</span>
              </div>
              
              <button 
                class="delete-layer-btn"
                on:click|stopPropagation={() => deleteClip(clip.id)}
                title="Delete layer"
              >
                ×
              </button>
            </div>
          {/each}
          
          {#if clips.length === 0}
            <div class="empty-layers">
              <div class="empty-icon">📋</div>
              <div class="empty-text">No layers yet</div>
              <div class="empty-hint">Click "Add Layer" to get started</div>
            </div>
          {/if}
        </div>
      </div>
    {:else}
      <div class="assets-panel">
        <input
          type="file"
          multiple
          accept="video/*,image/*,audio/*"
          on:change={handleFileUpload}
          id="asset-upload"
          class="file-input"
        />
        <label for="asset-upload" class="upload-btn">
          + Add Assets
        </label>
      </div>
    {/if}
  </div>
</div>

<!-- Layer Creation Popup -->
{#if showLayerPopup}
  <div class="popup-overlay" on:click={closeLayerPopup}>
    <div class="popup-content" on:click|stopPropagation on:keydown={handlePopupKeyDown}>
      {#if popupStep === 'name'}
        <div class="popup-header">
          <h3>Create New Layer</h3>
          <button class="popup-close" on:click={closeLayerPopup}>×</button>
        </div>
        
        <div class="popup-body">
          <div class="form-group">
            <label for="layer-name">Layer Name</label>
            <input
              id="layer-name"
              type="text"
              bind:value={newLayerName}
              bind:this={layerNameInput}
              class="popup-input"
              placeholder="Enter layer name..."
            />
          </div>
          
          <div class="form-group">
            <label>Layer Type</label>
            <div class="layer-type-grid">
              {#each layerTypes as layerType}
                <button
                  class="layer-type-btn"
                  class:selected={newLayerType === layerType.value}
                  on:click={() => newLayerType = layerType.value}
                >
                  <span class="layer-type-icon">{layerType.icon}</span>
                  <span class="layer-type-label">{layerType.label}</span>
                </button>
              {/each}
            </div>
          </div>
        </div>
        
        <div class="popup-footer">
          <button class="popup-btn secondary" on:click={closeLayerPopup}>Cancel</button>
          <button 
            class="popup-btn primary" 
            on:click={proceedToContent}
            disabled={!newLayerName.trim()}
          >
            Next
          </button>
        </div>
      {:else if popupStep === 'content'}
        <div class="popup-header">
          <h3>Add {selectedLayerType?.label} Content</h3>
          <button class="popup-close" on:click={closeLayerPopup}>×</button>
        </div>
        
        <div class="popup-body">
          <div class="content-preview">
            <div class="content-icon">{selectedLayerType?.icon}</div>
            <div class="content-name">{newLayerName}</div>
          </div>
          
          {#if newLayerType === 'text'}
            <div class="form-group">
              <label for="text-content">Text Content</label>
              <textarea
                id="text-content"
                bind:value={newLayerContent}
                bind:this={textContentInput}
                class="popup-textarea"
                placeholder="Enter your text content..."
                rows="4"
              ></textarea>
            </div>
          {:else}
            <div class="form-group">
              <label>Upload {selectedLayerType?.label}</label>
              <input
                type="file"
                accept={selectedLayerType?.accept}
                on:change={handleLayerFileUpload}
                bind:this={fileInput}
                class="file-input"
                id="layer-file-input"
              />
              <label for="layer-file-input" class="file-upload-btn">
                {#if newLayerFile}
                  <span class="file-name">✓ {newLayerFile.name}</span>
                {:else}
                  <span class="upload-text">📁 Choose {selectedLayerType?.label} File</span>
                {/if}
              </label>
            </div>
          {/if}
        </div>
        
        <div class="popup-footer">
          <button class="popup-btn secondary" on:click={() => popupStep = 'name'}>Back</button>
          <button 
            class="popup-btn primary" 
            on:click={createLayer}
            disabled={newLayerType === 'text' ? !newLayerContent.trim() : !newLayerFile}
          >
            Add Layer
          </button>
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
  /* Left Sidebar */
  .left-sidebar {
    width: 100%;
    background: var(--color-neutral-100);
    border-right: 1px solid #d0d0d0;
    display: flex;
    flex-direction: column;
    height: 100%;
  }

  .tab-nav {
    display: flex;
    border-bottom: 1px solid #d0d0d0;
    flex-shrink: 0;
  }

  .tab-btn {
    flex: 1;
    padding: 0.75rem;
    background: none;
    border: none;
    cursor: pointer;
    font-size: 0.9rem;
    color: #666;
    border-bottom: 2px solid transparent;
    border-radius: 0px;
  }

  .tab-btn.active {
    color: var(--color-primary-600);
    border-bottom-color: var(--color-primary-500);
    background-color: white;
  }

  .tab-content {
    flex: 1;
    padding: 1rem;
    overflow-y: auto;
  }

  .layers-panel {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    height: 100%;
  }

  .layers-header {
    margin-bottom: 0.5rem;
  }

  .add-layer-btn {
    width: 100%;
    padding: 0.5rem;
    background: var(--color-primary-500);
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.8rem;
    margin-bottom: 0.5rem;
    height: 45.5px;
  }

  .layer-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 0.7rem;
    color: #666;
  }

  .layer-count {
    font-weight: 500;
  }

  .layer-hint {
    opacity: 0.7;
  }

  .layers-list {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .layer-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem;
    border-radius: 4px;
    cursor: pointer;
    transition: all 0.2s;
    position: relative;
    border: 2px solid transparent;
    background: white;
  }

  .layer-item:hover {
    background: var(--color-neutral-300);
  }

  .layer-item.selected {
    background: var(--color-neutral-600);
    color: white;
  }

  .layer-item.dragging {
    opacity: 0.5;
    transform: rotate(2deg);
    z-index: 1000;
  }

  .layer-item.drag-over {
    border-color: #007AFF;
    border-top: solid 2px;
    border-left: 0px;
    border-right: 0px;
    border-bottom: 0px;
    background: #f8f9ff;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 122, 255, 0.2);
  }

  .layer-drag-handle {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 16px;
    height: 16px;
    cursor: grab;
    opacity: 0.5;
    transition: opacity 0.2s;
  }

  .layer-item:hover .layer-drag-handle {
    opacity: 1;
  }

  .layer-drag-handle:active {
    cursor: grabbing;
  }

  .drag-dots {
    display: grid;
    grid-template-columns: repeat(2, 2px);
    grid-template-rows: repeat(3, 2px);
    gap: 2px;
  }

  .dot {
    width: 2px;
    height: 2px;
    background: var(--color-neutral-300);
    border-radius: 50%;
  }

  .layer-item.selected .dot {
    background: var(--color-neutral-300);
  }

  .layer-icon {
    font-size: 0.9rem;
    flex-shrink: 0;
  }

  .layer-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 2px;
    overflow: hidden;
  }

  .layer-name {
    font-size: 0.9rem;
    font-weight: 500;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .layer-info-text {
    font-size: 0.7rem;
    opacity: 0.7;
  }

  .layer-item.selected .layer-info-text {
    opacity: 0.9;
  }

  .delete-layer-btn {
    background: none;
    border: none;
    color: #999;
    cursor: pointer;
    font-size: 1.2rem;
    padding: 0;
    width: 20px;
    height: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: all 0.2s;
    flex-shrink: 0;
  }

  .delete-layer-btn:hover {
    background: rgba(255, 0, 0, 0.1);
    color: #ff4444;
  }

  .layer-item.selected .delete-layer-btn {
    color: rgba(255, 255, 255, 0.7);
  }

  .layer-item.selected .delete-layer-btn:hover {
    background: rgba(255, 255, 255, 0.2);
    color: white;
  }

  .empty-layers {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 2rem 1rem;
    text-align: center;
    color: #666;
    flex: 1;
  }

  .empty-icon {
    font-size: 2rem;
    margin-bottom: 0.5rem;
    opacity: 0.5;
  }

  .empty-text {
    font-size: 0.9rem;
    font-weight: 500;
    margin-bottom: 0.25rem;
  }

  .empty-hint {
    font-size: 0.8rem;
    opacity: 0.7;
  }

  .assets-panel {
    display: flex;
    flex-direction: column;
  }

  .file-input {
    display: none;
  }

  .upload-btn {
    display: block;
    padding: 0.75rem;
    background: var(--color-primary-500);
    color: white;
    text-align: center;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.9rem;
  }

  /* Popup Styles */
  .popup-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    backdrop-filter: blur(4px);
  }

  .popup-content {
    background: white;
    border-radius: 8px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
    width: 90%;
    max-width: 500px;
    max-height: 80vh;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  .popup-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1.5rem;
    border-bottom: 1px solid #e0e0e0;
  }

  .popup-header h3 {
    margin: 0;
    font-size: 1.2rem;
    font-weight: 600;
  }

  .popup-close {
    background: none;
    border: none;
    font-size: 22px;
    cursor: pointer;
    color: #666;
    padding: 0;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: background 0.2s;
  }

  .popup-close:hover {
    background: #f0f0f0;
  }

  .popup-body {
    flex: 1;
    padding: 1.5rem;
    overflow-y: auto;
  }

  .form-group {
    margin-bottom: 1.5rem;
  }

  .form-group label {
    display: block;
    font-size: 0.9rem;
    font-weight: 500;
    color: #333;
    margin-bottom: 0.5rem;
  }

  .popup-input {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    font-size: 1rem;
    transition: border-color 0.2s;
  }

  .popup-input:focus {
    outline: none;
    border-color: #007AFF;
  }

  .popup-textarea {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    font-size: 1rem;
    resize: vertical;
    min-height: 100px;
    font-family: inherit;
    transition: border-color 0.2s;
  }

  .popup-textarea:focus {
    outline: none;
    border-color: #007AFF;
  }

  .layer-type-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 0.75rem;
  }

  .layer-type-btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
    padding: 1rem;
    border: 2px solid #e0e0e0;
    border-radius: 8px;
    background: white;
    cursor: pointer;
    transition: all 0.2s;
    color: black;
  }

  .layer-type-btn:hover {
    border-color: #007AFF;
    background: #f8f9ff;
  }

  .layer-type-btn.selected {
    border-color: #007AFF;
    background: #007AFF;
    color: white;
  }

  .layer-type-icon {
    font-size: 22px;
  }

  .layer-type-label {
    font-size: 0.8rem;
    font-weight: 500;
    text-align: center;
  }

  .content-preview {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    background: #f8f9ff;
    border-radius: 8px;
    margin-bottom: 1.5rem;
  }

  .content-icon {
    font-size: 2rem;
  }

  .content-name {
    font-size: 1.1rem;
    font-weight: 500;
    color: #333;
  }

  .file-upload-btn {
    display: block;
    width: 100%;
    padding: 1rem;
    border: 2px dashed #d0d0d0;
    border-radius: 8px;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s;
    background: #fafafa;
  }

  .file-upload-btn:hover {
    border-color: #007AFF;
    background: #f8f9ff;
  }

  .file-name {
    color: #007AFF;
    font-weight: 500;
  }

  .upload-text {
    color: #666;
  }

  .popup-footer {
    display: flex;
    gap: 1rem;
    padding: 1.5rem;
    border-top: 1px solid #e0e0e0;
    justify-content: flex-end;
  }

  .popup-btn {
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 6px;
    font-size: 0.9rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .popup-btn.secondary {
    background: #f0f0f0;
    color: #666;
  }

  .popup-btn.secondary:hover {
    background: #e0e0e0;
  }

  .popup-btn.primary {
    background: #007AFF;
    color: white;
  }

  .popup-btn.primary:hover {
    background: #0056CC;
  }

  .popup-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .popup-btn:disabled:hover {
    background: #007AFF;
  }

  .popup-btn.secondary:disabled:hover {
    background: #f0f0f0;
  }
</style>