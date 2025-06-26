<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import type { VideoClip } from './types';

  export let selectedClip: VideoClip | null = null;
  export let totalDuration: number = 60;
  export let pieceId: string = '';
  export let currentProjectStatus: string = '';

  let activeTab: 'properties' | 'effects' | 'animation' | 'export' = 'properties';
  let versionName = '';
  let isCreatingNamedVersion = false;
  let exportVideoUrl = '';
  let isExporting = false;
  let exportError = '';
  let newProjectStatus = currentProjectStatus;

  const dispatch = createEventDispatcher();

  // Properties for text clips
  let fontSize = 2.5; // % of canvas width
  let fontFamily = 'Arial, sans-serif';
  let fontWeight = 'normal';
  let fontStyle = 'normal';
  let textColor = '#FFFFFF';
  let textAlign = 'center';
  let textShadow = 'none';
  let lineHeight = 1.2;
  let letterSpacing = 0;

  // Properties for media clips
  let volume = 0.6; // 0-1
  let playbackRate = 1.0; // 0.5-2.0
  let brightness = 1.0; // 0-2
  let contrast = 1.0; // 0-2
  let saturation = 1.0; // 0-2
  let blur = 0; // 0-10px
  let mixBlendMode = 'normal';

  // Properties for all clips
  let opacity = 1.0; // 0-1
  let positionX = 50; // % of canvas width
  let positionY = 50; // % of canvas height
  let scaleX = 100; // % of original size
  let scaleY = 100; // % of original size
  let rotation = 0; // degrees

  // Animation properties
  let animation = 'none';
  let animationDuration = 1; // seconds
  let animationDelay = 0; // seconds

  // Timing properties
  let timelineStart = 0;
  let timelineEnd = 10;
  let contentStartTime = 0;
  let contentEndTime = 10;
  let clipDuration = 10;

  // Project status options
  const projectStatusOptions = [
    { value: 'open_to_applications', label: 'Open to Applications' },
    { value: 'seeking_funding', label: 'Seeking Funding' },
    { value: 'published', label: 'Published' }
  ];

  // Blend mode options
  const blendModes = [
    'normal', 'multiply', 'screen', 'overlay', 'darken', 'lighten', 
    'color-dodge', 'color-burn', 'hard-light', 'soft-light', 'difference', 
    'exclusion', 'hue', 'saturation', 'color', 'luminosity'
  ];

  // Animation options
  const animations = [
    { value: 'none', label: 'None' },
    { value: 'fadeIn', label: 'Fade In' },
    { value: 'slideInLeft', label: 'Slide In (Left)' },
    { value: 'slideInRight', label: 'Slide In (Right)' },
    { value: 'slideInUp', label: 'Slide In (Up)' },
    { value: 'slideInDown', label: 'Slide In (Down)' },
    { value: 'zoomIn', label: 'Zoom In' }
  ];

  // Font family options
  const fontFamilies = [
    'Arial, sans-serif',
    'Helvetica, sans-serif',
    'Times New Roman, serif',
    'Georgia, serif',
    'Courier New, monospace',
    'Verdana, sans-serif',
    'Impact, sans-serif',
    'Comic Sans MS, cursive'
  ];

  // Font weight options
  const fontWeights = [
    'normal',
    'bold',
    '100',
    '200',
    '300',
    '400',
    '500',
    '600',
    '700',
    '800',
    '900'
  ];

  // Text align options
  const textAligns = [
    'left',
    'center',
    'right',
    'justify'
  ];

  // Update local state when selectedClip changes
  $: if (selectedClip) {
    // Update common properties
    opacity = selectedClip.opacity !== undefined ? selectedClip.opacity : 1;
    
    if (selectedClip.position) {
      positionX = selectedClip.position.x;
      positionY = selectedClip.position.y;
    }
    
    if (selectedClip.scale) {
      scaleX = selectedClip.scale.x;
      scaleY = selectedClip.scale.y;
    }
    
    rotation = selectedClip.rotation || 0;
    
    // Update timing properties
    timelineStart = selectedClip.timelineStart;
    timelineEnd = selectedClip.timelineEnd;
    contentStartTime = selectedClip.contentStartTime || 0;
    contentEndTime = selectedClip.contentEndTime || selectedClip.duration;
    clipDuration = selectedClip.duration;
    
    // Update animation properties
    animation = selectedClip.animation || 'none';
    animationDuration = selectedClip.animationDuration || 1;
    animationDelay = selectedClip.animationDelay || 0;
    
    // Update type-specific properties
    if (selectedClip.type === 'text') {
      fontSize = selectedClip.fontSize || 2.5;
      fontFamily = selectedClip.fontFamily || 'Arial, sans-serif';
      fontWeight = selectedClip.fontWeight || 'normal';
      fontStyle = selectedClip.fontStyle || 'normal';
      textColor = selectedClip.textColor || '#FFFFFF';
      textAlign = selectedClip.textAlign || 'center';
      textShadow = selectedClip.textShadow || 'none';
      lineHeight = selectedClip.lineHeight || 1.2;
      letterSpacing = selectedClip.letterSpacing || 0;
    } else if (selectedClip.type === 'video' || selectedClip.type === 'image') {
      brightness = selectedClip.brightness !== undefined ? selectedClip.brightness : 1;
      contrast = selectedClip.contrast !== undefined ? selectedClip.contrast : 1;
      saturation = selectedClip.saturation !== undefined ? selectedClip.saturation : 1;
      blur = selectedClip.blur || 0;
      mixBlendMode = selectedClip.mixBlendMode || 'normal';
      
      if (selectedClip.type === 'video' || selectedClip.type === 'audio') {
        volume = selectedClip.volume !== undefined ? selectedClip.volume : 0.6;
        playbackRate = selectedClip.playbackRate || 1.0;
      }
    }
  }

  function updateClipProperty(property: string, value: any) {
    if (!selectedClip) return;
    
    dispatch('updateClipProperty', {
      clipId: selectedClip.id,
      property,
      value
    });
  }

  function updatePosition() {
    if (!selectedClip) return;
    
    updateClipProperty('position', { x: positionX, y: positionY });
  }

  function updateScale() {
    if (!selectedClip) return;
    
    updateClipProperty('scale', { x: scaleX, y: scaleY });
  }

  function createNamedVersion() {
    isCreatingNamedVersion = true;
  }

  function cancelNamedVersion() {
    isCreatingNamedVersion = false;
    versionName = '';
  }

  function confirmNamedVersion() {
    if (!versionName.trim()) return;
    
    dispatch('createNamedVersion', { versionName: versionName.trim() });
    isCreatingNamedVersion = false;
    versionName = '';
  }

  async function exportVideo() {
    if (!pieceId) return;
    
    try {
      isExporting = true;
      exportError = '';
      exportVideoUrl = '';
      
      // In a real implementation, this would call an API endpoint to render the video
      // For now, we'll simulate a successful export after a delay
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Simulate a successful export with a placeholder URL
      exportVideoUrl = 'https://example.com/exported-video.mp4';
      
    } catch (error: any) {
      exportError = error.message || 'Failed to export video';
    } finally {
      isExporting = false;
    }
  }

  function publishPiece() {
    if (!pieceId || !exportVideoUrl) return;
    
    dispatch('publishPiece', {
      pieceId,
      videoUrl: exportVideoUrl,
      newProjectStatus
    });
  }
</script>

<div class="properties-panel">
  <div class="panel-header">
    <div class="tab-buttons">
      <button 
        class:active={activeTab === 'properties'} 
        on:click={() => activeTab = 'properties'}
      >
        Properties
      </button>
      <button 
        class:active={activeTab === 'effects'} 
        on:click={() => activeTab = 'effects'}
      >
        Effects
      </button>
      <button 
        class:active={activeTab === 'animation'} 
        on:click={() => activeTab = 'animation'}
      >
        Animation
      </button>
      <button 
        class:active={activeTab === 'export'} 
        on:click={() => activeTab = 'export'}
      >
        Export
      </button>
    </div>
  </div>
  
  <div class="panel-content">
    {#if activeTab === 'properties'}
      <div class="properties-content">
        {#if selectedClip}
          <div class="section-title">
            <h3>{selectedClip.name}</h3>
            <span class="clip-type">{selectedClip.type}</span>
          </div>
          
          <!-- Common Properties -->
          <div class="property-section">
            <h4>Position & Size</h4>
            
            <div class="property-group">
              <label>Position</label>
              <div class="property-row">
                <div class="property-field">
                  <span class="field-label">X</span>
                  <input 
                    type="number" 
                    bind:value={positionX} 
                    on:change={updatePosition}
                    min="0" 
                    max="100" 
                    step="1"
                  />
                  <span class="field-unit">%</span>
                </div>
                <div class="property-field">
                  <span class="field-label">Y</span>
                  <input 
                    type="number" 
                    bind:value={positionY} 
                    on:change={updatePosition}
                    min="0" 
                    max="100" 
                    step="1"
                  />
                  <span class="field-unit">%</span>
                </div>
              </div>
            </div>
            
            <div class="property-group">
              <label>Scale</label>
              <div class="property-row">
                <div class="property-field">
                  <span class="field-label">W</span>
                  <input 
                    type="number" 
                    bind:value={scaleX} 
                    on:change={updateScale}
                    min="1" 
                    max="200" 
                    step="1"
                  />
                  <span class="field-unit">%</span>
                </div>
                <div class="property-field">
                  <span class="field-label">H</span>
                  <input 
                    type="number" 
                    bind:value={scaleY} 
                    on:change={updateScale}
                    min="1" 
                    max="200" 
                    step="1"
                  />
                  <span class="field-unit">%</span>
                </div>
              </div>
            </div>
            
            <div class="property-group">
              <label>Rotation</label>
              <div class="property-row">
                <div class="property-field full-width">
                  <input 
                    type="range" 
                    bind:value={rotation} 
                    on:change={() => updateClipProperty('rotation', rotation)}
                    min="-180" 
                    max="180" 
                    step="1"
                  />
                  <div class="range-value">{rotation}°</div>
                </div>
              </div>
            </div>
            
            <div class="property-group">
              <label>Opacity</label>
              <div class="property-row">
                <div class="property-field full-width">
                  <input 
                    type="range" 
                    bind:value={opacity} 
                    on:change={() => updateClipProperty('opacity', opacity)}
                    min="0" 
                    max="1" 
                    step="0.01"
                  />
                  <div class="range-value">{Math.round(opacity * 100)}%</div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Text-specific Properties -->
          {#if selectedClip.type === 'text'}
            <div class="property-section">
              <h4>Text Properties</h4>
              
              <div class="property-group">
                <label>Font</label>
                <select 
                  bind:value={fontFamily} 
                  on:change={() => updateClipProperty('fontFamily', fontFamily)}
                >
                  {#each fontFamilies as family}
                    <option value={family}>{family.split(',')[0]}</option>
                  {/each}
                </select>
              </div>
              
              <div class="property-group">
                <label>Font Size</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={fontSize} 
                      on:change={() => updateClipProperty('fontSize', fontSize)}
                      min="0.5" 
                      max="10" 
                      step="0.1"
                    />
                    <div class="range-value">{fontSize}%</div>
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Font Weight</label>
                <select 
                  bind:value={fontWeight} 
                  on:change={() => updateClipProperty('fontWeight', fontWeight)}
                >
                  {#each fontWeights as weight}
                    <option value={weight}>{weight}</option>
                  {/each}
                </select>
              </div>
              
              <div class="property-group">
                <label>Text Align</label>
                <div class="button-group">
                  {#each textAligns as align}
                    <button 
                      class:active={textAlign === align}
                      on:click={() => {
                        textAlign = align;
                        updateClipProperty('textAlign', align);
                      }}
                    >
                      {#if align === 'left'}
                        <span>Left</span>
                      {:else if align === 'center'}
                        <span>Center</span>
                      {:else if align === 'right'}
                        <span>Right</span>
                      {:else if align === 'justify'}
                        <span>Justify</span>
                      {/if}
                    </button>
                  {/each}
                </div>
              </div>
              
              <div class="property-group">
                <label>Text Color</label>
                <div class="property-row">
                  <div class="property-field color-field">
                    <input 
                      type="color" 
                      bind:value={textColor} 
                      on:change={() => updateClipProperty('textColor', textColor)}
                    />
                    <input 
                      type="text" 
                      bind:value={textColor} 
                      on:change={() => updateClipProperty('textColor', textColor)}
                    />
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Line Height</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={lineHeight} 
                      on:change={() => updateClipProperty('lineHeight', lineHeight)}
                      min="0.8" 
                      max="2" 
                      step="0.1"
                    />
                    <div class="range-value">{lineHeight}</div>
                  </div>
                </div>
              </div>
            </div>
          {/if}
          
          <!-- Media-specific Properties -->
          {#if selectedClip.type === 'video' || selectedClip.type === 'audio'}
            <div class="property-section">
              <h4>Media Properties</h4>
              
              <div class="property-group">
                <label>Volume</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={volume} 
                      on:change={() => updateClipProperty('volume', volume)}
                      min="0" 
                      max="1" 
                      step="0.01"
                    />
                    <div class="range-value">{Math.round(volume * 100)}%</div>
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Playback Speed</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={playbackRate} 
                      on:change={() => updateClipProperty('playbackRate', playbackRate)}
                      min="0.5" 
                      max="2" 
                      step="0.1"
                    />
                    <div class="range-value">{playbackRate}x</div>
                  </div>
                </div>
              </div>
            </div>
          {/if}
          
          <!-- Timing Properties -->
          <div class="property-section">
            <h4>Timing</h4>
            
            <div class="property-group">
              <label>Timeline Start</label>
              <div class="property-row">
                <div class="property-field full-width">
                  <input 
                    type="range" 
                    bind:value={timelineStart} 
                    on:change={() => updateClipProperty('timelineStart', timelineStart)}
                    min="0" 
                    max={totalDuration - 1} 
                    step="0.1"
                  />
                  <div class="range-value">{timelineStart.toFixed(1)}s</div>
                </div>
              </div>
            </div>
            
            <div class="property-group">
              <label>Timeline End</label>
              <div class="property-row">
                <div class="property-field full-width">
                  <input 
                    type="range" 
                    bind:value={timelineEnd} 
                    on:change={() => updateClipProperty('timelineEnd', timelineEnd)}
                    min={timelineStart + 0.1} 
                    max={totalDuration} 
                    step="0.1"
                  />
                  <div class="range-value">{timelineEnd.toFixed(1)}s</div>
                </div>
              </div>
            </div>
            
            {#if selectedClip.type === 'video' || selectedClip.type === 'audio'}
              <div class="property-group">
                <label>Content Start Time</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={contentStartTime} 
                      on:change={() => updateClipProperty('contentStartTime', contentStartTime)}
                      min="0" 
                      max={contentEndTime - 0.1} 
                      step="0.1"
                    />
                    <div class="range-value">{contentStartTime.toFixed(1)}s</div>
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Content End Time</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={contentEndTime} 
                      on:change={() => updateClipProperty('contentEndTime', contentEndTime)}
                      min={contentStartTime + 0.1} 
                      max={clipDuration} 
                      step="0.1"
                    />
                    <div class="range-value">{contentEndTime.toFixed(1)}s</div>
                  </div>
                </div>
              </div>
            {/if}
          </div>
        {:else}
          <div class="no-selection">
            <p>Select a layer to edit its properties</p>
          </div>
        {/if}
      </div>
    {:else if activeTab === 'effects'}
      <div class="effects-content">
        {#if selectedClip}
          <div class="section-title">
            <h3>{selectedClip.name}</h3>
            <span class="clip-type">{selectedClip.type}</span>
          </div>
          
          {#if selectedClip.type === 'video' || selectedClip.type === 'image'}
            <div class="property-section">
              <h4>Visual Effects</h4>
              
              <div class="property-group">
                <label>Brightness</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={brightness} 
                      on:change={() => updateClipProperty('brightness', brightness)}
                      min="0" 
                      max="2" 
                      step="0.05"
                    />
                    <div class="range-value">{Math.round(brightness * 100)}%</div>
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Contrast</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={contrast} 
                      on:change={() => updateClipProperty('contrast', contrast)}
                      min="0" 
                      max="2" 
                      step="0.05"
                    />
                    <div class="range-value">{Math.round(contrast * 100)}%</div>
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Saturation</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={saturation} 
                      on:change={() => updateClipProperty('saturation', saturation)}
                      min="0" 
                      max="2" 
                      step="0.05"
                    />
                    <div class="range-value">{Math.round(saturation * 100)}%</div>
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Blur</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={blur} 
                      on:change={() => updateClipProperty('blur', blur)}
                      min="0" 
                      max="10" 
                      step="0.5"
                    />
                    <div class="range-value">{blur}px</div>
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Blend Mode</label>
                <select 
                  bind:value={mixBlendMode} 
                  on:change={() => updateClipProperty('mixBlendMode', mixBlendMode)}
                >
                  {#each blendModes as mode}
                    <option value={mode}>{mode}</option>
                  {/each}
                </select>
              </div>
            </div>
          {:else}
            <div class="no-effects">
              <p>No effects available for this layer type</p>
            </div>
          {/if}
        {:else}
          <div class="no-selection">
            <p>Select a layer to edit its effects</p>
          </div>
        {/if}
      </div>
    {:else if activeTab === 'animation'}
      <div class="animation-content">
        {#if selectedClip}
          <div class="section-title">
            <h3>{selectedClip.name}</h3>
            <span class="clip-type">{selectedClip.type}</span>
          </div>
          
          <div class="property-section">
            <h4>Animation</h4>
            
            <div class="property-group">
              <label>Animation Type</label>
              <select 
                bind:value={animation} 
                on:change={() => updateClipProperty('animation', animation)}
              >
                {#each animations as anim}
                  <option value={anim.value}>{anim.label}</option>
                {/each}
              </select>
            </div>
            
            {#if animation !== 'none'}
              <div class="property-group">
                <label>Duration</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={animationDuration} 
                      on:change={() => updateClipProperty('animationDuration', animationDuration)}
                      min="0.1" 
                      max="5" 
                      step="0.1"
                    />
                    <div class="range-value">{animationDuration.toFixed(1)}s</div>
                  </div>
                </div>
              </div>
              
              <div class="property-group">
                <label>Delay</label>
                <div class="property-row">
                  <div class="property-field full-width">
                    <input 
                      type="range" 
                      bind:value={animationDelay} 
                      on:change={() => updateClipProperty('animationDelay', animationDelay)}
                      min="0" 
                      max="5" 
                      step="0.1"
                    />
                    <div class="range-value">{animationDelay.toFixed(1)}s</div>
                  </div>
                </div>
              </div>
              
              <div class="animation-preview">
                <div class="preview-label">Preview</div>
                <div class="preview-container">
                  <div 
                    class="preview-element"
                    class:preview-fade-in={animation === 'fadeIn'}
                    class:preview-slide-left={animation === 'slideInLeft'}
                    class:preview-slide-right={animation === 'slideInRight'}
                    class:preview-slide-up={animation === 'slideInUp'}
                    class:preview-slide-down={animation === 'slideInDown'}
                    class:preview-zoom-in={animation === 'zoomIn'}
                    style="animation-duration: {animationDuration}s; animation-delay: {animationDelay}s;"
                  >
                    {selectedClip.type === 'text' ? 'Text' : 'Layer'}
                  </div>
                </div>
              </div>
            {/if}
          </div>
        {:else}
          <div class="no-selection">
            <p>Select a layer to edit its animation</p>
          </div>
        {/if}
      </div>
    {:else if activeTab === 'export'}
      <div class="export-content">
        <div class="section-title">
          <h3>Export & Publish</h3>
        </div>
        
        <div class="property-section">
          <h4>Export Video</h4>
          <p class="section-description">Export your piece as a video to share or publish it.</p>
          
          <div class="export-actions">
            <button 
              class="export-button"
              on:click={exportVideo}
              disabled={isExporting}
            >
              {#if isExporting}
                <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                    <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                  </circle>
                </svg>
                Exporting...
              {:else}
                Export Video
              {/if}
            </button>
          </div>
          
          {#if exportError}
            <div class="export-error">
              {exportError}
            </div>
          {/if}
          
          {#if exportVideoUrl}
            <div class="export-success">
              <p>Video exported successfully!</p>
              <a href={exportVideoUrl} target="_blank" rel="noopener noreferrer" class="view-video-link">
                View Exported Video
              </a>
            </div>
          {/if}
        </div>
        
        {#if exportVideoUrl}
          <div class="property-section">
            <h4>Publish Piece</h4>
            <p class="section-description">Make your piece available to the public.</p>
            
            <div class="property-group">
              <label>Project Status</label>
              <select bind:value={newProjectStatus}>
                {#each projectStatusOptions as option}
                  <option value={option.value}>{option.label}</option>
                {/each}
              </select>
            </div>
            
            <div class="publish-actions">
              <button 
                class="publish-button"
                on:click={publishPiece}
              >
                Publish Piece
              </button>
            </div>
          </div>
        {/if}
        
        <div class="property-section">
          <h4>Save Version</h4>
          <p class="section-description">Create a named version of your current work.</p>
          
          <div class="version-actions">
            <button 
              class="version-button"
              on:click={createNamedVersion}
            >
              Save Named Version
            </button>
          </div>
        </div>
      </div>
    {/if}
  </div>
  
  {#if isCreatingNamedVersion}
    <div class="version-dialog">
      <div class="dialog-header">
        <h3>Save Version</h3>
        <button class="close-button" on:click={cancelNamedVersion}>×</button>
      </div>
      <div class="dialog-content">
        <p>Enter a name for this version to help you identify it later.</p>
        <input 
          type="text" 
          bind:value={versionName} 
          placeholder="Version name (e.g., First Draft, Final Cut)"
          class="version-input"
        />
      </div>
      <div class="dialog-actions">
        <button class="cancel-button" on:click={cancelNamedVersion}>Cancel</button>
        <button 
          class="save-button" 
          on:click={confirmNamedVersion}
          disabled={!versionName.trim()}
        >
          Save Version
        </button>
      </div>
    </div>
  {/if}
</div>

<style>
  .properties-panel {
    height: 100%;
    background: #FBFBFB;
    border-left: 1px solid #d0d0d0;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    position: relative;
  }
  
  .panel-header {
    padding: 0;
    border-bottom: 1px solid #d0d0d0;
    flex-shrink: 0;
  }
  
  .tab-buttons {
    display: flex;
    width: 100%;
  }
  
  .tab-buttons button {
    flex: 1;
    padding: 0.75rem 0.5rem;
    background: none;
    border: none;
    border-bottom: 2px solid transparent;
    cursor: pointer;
    font-size: 0.8rem;
    color: #666;
    transition: all 0.2s;
    border-radius: 0;
  }
  
  .tab-buttons button:hover {
    background-color: #f0f0f0;
  }
  
  .tab-buttons button.active {
    color: var(--color-primary-600);
    border-bottom-color: var(--color-primary-600);
    background-color: #f5f5f5;
  }
  
  .panel-content {
    flex: 1;
    overflow-y: auto;
    padding: 1rem;
  }
  
  .section-title {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
  }
  
  .section-title h3 {
    margin: 0;
    font-size: 1rem;
    font-weight: 500;
    color: #333;
  }
  
  .clip-type {
    font-size: 0.75rem;
    color: #666;
    background: #f0f0f0;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
  }
  
  .property-section {
    margin-bottom: 1.5rem;
    padding-bottom: 1.5rem;
    border-bottom: 1px solid #e0e0e0;
  }
  
  .property-section:last-child {
    margin-bottom: 0;
    padding-bottom: 0;
    border-bottom: none;
  }
  
  .property-section h4 {
    margin: 0 0 0.75rem 0;
    font-size: 0.9rem;
    font-weight: 500;
    color: #333;
  }
  
  .section-description {
    font-size: 0.8rem;
    color: #666;
    margin-bottom: 1rem;
  }
  
  .property-group {
    margin-bottom: 1rem;
  }
  
  .property-group label {
    display: block;
    font-size: 0.8rem;
    color: #666;
    margin-bottom: 0.25rem;
  }
  
  .property-row {
    display: flex;
    gap: 0.5rem;
  }
  
  .property-field {
    display: flex;
    align-items: center;
    gap: 0.25rem;
    flex: 1;
  }
  
  .property-field.full-width {
    flex-direction: column;
    align-items: stretch;
  }
  
  .field-label {
    font-size: 0.75rem;
    color: #666;
    width: 12px;
    text-align: center;
  }
  
  .field-unit {
    font-size: 0.75rem;
    color: #666;
  }
  
  .property-field input[type="number"] {
    width: 50px;
    padding: 0.25rem;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    font-size: 0.8rem;
  }
  
  .property-field input[type="range"] {
    width: 100%;
    margin: 0;
  }
  
  .range-value {
    font-size: 0.75rem;
    color: #666;
    text-align: center;
    margin-top: 0.25rem;
  }
  
  .property-group select {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    font-size: 0.8rem;
    background: white;
  }
  
  .button-group {
    display: flex;
    gap: 0.25rem;
  }
  
  .button-group button {
    flex: 1;
    padding: 0.5rem;
    background: white;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    font-size: 0.8rem;
    cursor: pointer;
    transition: all 0.2s;
  }
  
  .button-group button.active {
    background: var(--color-primary-600);
    color: white;
    border-color: var(--color-primary-600);
  }
  
  .color-field {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  
  .color-field input[type="color"] {
    width: 30px;
    height: 30px;
    padding: 0;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
  }
  
  .color-field input[type="text"] {
    flex: 1;
    padding: 0.25rem 0.5rem;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    font-size: 0.8rem;
  }
  
  .no-selection,
  .no-effects {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 200px;
    color: #999;
    font-size: 0.9rem;
    text-align: center;
    padding: 0 1rem;
  }
  
  /* Animation Preview */
  .animation-preview {
    margin-top: 1rem;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    overflow: hidden;
  }
  
  .preview-label {
    padding: 0.5rem;
    background: #f0f0f0;
    font-size: 0.8rem;
    color: #666;
    border-bottom: 1px solid #d0d0d0;
  }
  
  .preview-container {
    height: 100px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #fff;
    position: relative;
  }
  
  .preview-element {
    padding: 0.5rem 1rem;
    background: var(--color-primary-600);
    color: white;
    border-radius: 4px;
    font-size: 0.8rem;
    animation-fill-mode: both;
    animation-iteration-count: infinite;
  }
  
  .preview-fade-in {
    animation-name: previewFadeIn;
  }
  
  .preview-slide-left {
    animation-name: previewSlideLeft;
  }
  
  .preview-slide-right {
    animation-name: previewSlideRight;
  }
  
  .preview-slide-up {
    animation-name: previewSlideUp;
  }
  
  .preview-slide-down {
    animation-name: previewSlideDown;
  }
  
  .preview-zoom-in {
    animation-name: previewZoomIn;
  }
  
  @keyframes previewFadeIn {
    0%, 100% { opacity: 0; }
    50% { opacity: 1; }
  }
  
  @keyframes previewSlideLeft {
    0%, 100% { transform: translateX(-100%); opacity: 0; }
    50% { transform: translateX(0); opacity: 1; }
  }
  
  @keyframes previewSlideRight {
    0%, 100% { transform: translateX(100%); opacity: 0; }
    50% { transform: translateX(0); opacity: 1; }
  }
  
  @keyframes previewSlideUp {
    0%, 100% { transform: translateY(100%); opacity: 0; }
    50% { transform: translateY(0); opacity: 1; }
  }
  
  @keyframes previewSlideDown {
    0%, 100% { transform: translateY(-100%); opacity: 0; }
    50% { transform: translateY(0); opacity: 1; }
  }
  
  @keyframes previewZoomIn {
    0%, 100% { transform: scale(0); opacity: 0; }
    50% { transform: scale(1); opacity: 1; }
  }
  
  /* Export tab */
  .export-actions,
  .publish-actions,
  .version-actions {
    margin-top: 1rem;
  }
  
  .export-button,
  .publish-button,
  .version-button {
    padding: 0.5rem 1rem;
    font-size: 0.9rem;
    border-radius: 4px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    transition: all 0.2s;
  }
  
  .export-button {
    background: var(--color-primary-600);
    color: white;
    border: none;
  }
  
  .export-button:hover:not(:disabled) {
    background: var(--color-primary-700);
  }
  
  .export-button:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
  
  .publish-button {
    background: var(--color-success-600);
    color: white;
    border: none;
  }
  
  .publish-button:hover {
    background: var(--color-success-700);
  }
  
  .version-button {
    background: #f0f0f0;
    color: #333;
    border: 1px solid #d0d0d0;
  }
  
  .version-button:hover {
    background: #e0e0e0;
  }
  
  .export-error {
    margin-top: 1rem;
    padding: 0.5rem;
    background: var(--color-error-50);
    color: var(--color-error-600);
    border: 1px solid var(--color-error-200);
    border-radius: 4px;
    font-size: 0.8rem;
  }
  
  .export-success {
    margin-top: 1rem;
    padding: 0.5rem;
    background: var(--color-success-50);
    color: var(--color-success-600);
    border: 1px solid var(--color-success-200);
    border-radius: 4px;
    font-size: 0.8rem;
  }
  
  .view-video-link {
    display: inline-block;
    margin-top: 0.5rem;
    color: var(--color-primary-600);
    text-decoration: none;
  }
  
  .view-video-link:hover {
    text-decoration: underline;
  }
  
  .spinner {
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  /* Version Dialog */
  .version-dialog {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 90%;
    max-width: 300px;
    background: white;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    z-index: 1000;
  }
  
  .dialog-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    border-bottom: 1px solid #e0e0e0;
  }
  
  .dialog-header h3 {
    margin: 0;
    font-size: 1rem;
    font-weight: 500;
  }
  
  .close-button {
    background: none;
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
    color: #666;
    padding: 0;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: background 0.2s;
  }
  
  .close-button:hover {
    background: #f0f0f0;
  }
  
  .dialog-content {
    padding: 1rem;
  }
  
  .dialog-content p {
    margin: 0 0 1rem 0;
    font-size: 0.9rem;
    color: #666;
  }
  
  .version-input {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    font-size: 0.9rem;
  }
  
  .dialog-actions {
    display: flex;
    justify-content: flex-end;
    gap: 0.5rem;
    padding: 0 1rem 1rem;
  }
  
  .cancel-button,
  .save-button {
    padding: 0.5rem 1rem;
    border-radius: 4px;
    font-size: 0.9rem;
    cursor: pointer;
  }
  
  .cancel-button {
    background: #f0f0f0;
    color: #333;
    border: 1px solid #d0d0d0;
  }
  
  .cancel-button:hover {
    background: #e0e0e0;
  }
  
  .save-button {
    background: var(--color-primary-600);
    color: white;
    border: none;
  }
  
  .save-button:hover:not(:disabled) {
    background: var(--color-primary-700);
  }
  
  .save-button:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
</style>