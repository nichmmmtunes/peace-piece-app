<script lang="ts">
  import type { VideoClip } from './types';
  import { createEventDispatcher } from 'svelte';

  export let selectedClip: VideoClip | null = null;
  export let totalDuration = 60;
  export let pieceId: string = '';
  export let currentProjectStatus: string = '';

  // Tab state
  let activeTab: 'properties' | 'export' = 'properties';

  // Export settings
  let exportSettings = {
    format: 'mp4',
    quality: 'high',
    resolution: '1920x1080',
    framerate: 30,
    bitrate: 'auto',
    audioQuality: 'high',
    includeAudio: true,
    filename: 'my-video'
  };

  const dispatch = createEventDispatcher();

  // Reactive console.log to track selectedClip changes
  $: {
    console.log('PropertiesPanel - selectedClip changed:', selectedClip);
    if (selectedClip) {
      console.log('  - ID:', selectedClip.id);
      console.log('  - Name:', selectedClip.name);
      console.log('  - Position:', selectedClip.position);
      console.log('  - Scale:', selectedClip.scale);
      console.log('  - Rotation:', selectedClip.rotation);
      console.log('  - Opacity:', selectedClip.opacity);
    }
  }

  // Font options
  const fontFamilies = [
    'Arial, sans-serif',
    'Helvetica, sans-serif',
    'Georgia, serif',
    'Times New Roman, serif',
    'Courier New, monospace',
    'Verdana, sans-serif',
    'Impact, sans-serif',
    'Comic Sans MS, cursive',
    'Trebuchet MS, sans-serif',
    'Palatino, serif'
  ];

  const fontWeights = [
    { value: 'normal', label: 'Normal' },
    { value: 'bold', label: 'Bold' },
    { value: '100', label: 'Thin' },
    { value: '300', label: 'Light' },
    { value: '500', label: 'Medium' },
    { value: '600', label: 'Semi Bold' },
    { value: '700', label: 'Bold' },
    { value: '800', label: 'Extra Bold' },
    { value: '900', label: 'Black' }
  ];

  const textAlignOptions = [
    { value: 'left', label: 'Left', icon: '⬅️' },
    { value: 'center', label: 'Center', icon: '↔️' },
    { value: 'right', label: 'Right', icon: '➡️' },
    { value: 'justify', label: 'Justify', icon: '⬌' }
  ];

  const animationOptions = [
    { value: 'none', label: 'None' },
    { value: 'fadeIn', label: 'Fade In' },
    { value: 'slideInLeft', label: 'Slide In Left' },
    { value: 'slideInRight', label: 'Slide In Right' },
    { value: 'slideInUp', label: 'Slide In Up' },
    { value: 'slideInDown', label: 'Slide In Down' },
    { value: 'zoomIn', label: 'Zoom In' }
  ];

  const mixBlendModeOptions = [
    { value: 'normal', label: 'Normal' },
    { value: 'multiply', label: 'Multiply' },
    { value: 'screen', label: 'Screen' },
    { value: 'overlay', label: 'Overlay' },
    { value: 'darken', label: 'Darken' },
    { value: 'lighten', label: 'Lighten' },
    { value: 'color-dodge', label: 'Color Dodge' },
    { value: 'color-burn', label: 'Color Burn' },
    { value: 'hard-light', label: 'Hard Light' },
    { value: 'soft-light', label: 'Soft Light' },
    { value: 'difference', label: 'Difference' },
    { value: 'exclusion', label: 'Exclusion' },
    { value: 'hue', label: 'Hue' },
    { value: 'saturation', label: 'Saturation' },
    { value: 'color', label: 'Color' },
    { value: 'luminosity', label: 'Luminosity' }
  ];

  // Export options
  const exportFormats = [
    { value: 'mp4', label: 'MP4 (H.264)', description: 'Best for web and general use' },
    { value: 'webm', label: 'WebM (VP9)', description: 'Optimized for web streaming' },
    { value: 'mov', label: 'MOV (QuickTime)', description: 'High quality for editing' },
    { value: 'avi', label: 'AVI', description: 'Compatible with older systems' }
  ];

  const qualityPresets = [
    { value: 'low', label: 'Low', description: 'Smaller file size, lower quality' },
    { value: 'medium', label: 'Medium', description: 'Balanced quality and file size' },
    { value: 'high', label: 'High', description: 'Best quality, larger file size' },
    { value: 'custom', label: 'Custom', description: 'Manual bitrate control' }
  ];

  const resolutionOptions = [
    { value: '3840x2160', label: '4K (3840×2160)', description: 'Ultra HD' },
    { value: '2560x1440', label: '2K (2560×1440)', description: 'Quad HD' },
    { value: '1920x1080', label: 'Full HD (1920×1080)', description: 'Standard HD' },
    { value: '1280x720', label: 'HD (1280×720)', description: 'HD Ready' },
    { value: '854x480', label: 'SD (854×480)', description: 'Standard Definition' },
    { value: 'custom', label: 'Custom', description: 'Set custom dimensions' }
  ];

  const framerateOptions = [
    { value: 24, label: '24 fps', description: 'Cinematic' },
    { value: 25, label: '25 fps', description: 'PAL standard' },
    { value: 30, label: '30 fps', description: 'NTSC standard' },
    { value: 50, label: '50 fps', description: 'Smooth motion' },
    { value: 60, label: '60 fps', description: 'Ultra smooth' }
  ];

  const bitrateOptions = [
    { value: 'auto', label: 'Auto', description: 'Automatic based on quality' },
    { value: '1000', label: '1 Mbps', description: 'Low bandwidth' },
    { value: '2500', label: '2.5 Mbps', description: 'Standard web' },
    { value: '5000', label: '5 Mbps', description: 'High quality web' },
    { value: '10000', label: '10 Mbps', description: 'Professional' },
    { value: 'custom', label: 'Custom', description: 'Manual bitrate' }
  ];

  const audioQualityOptions = [
    { value: 'low', label: 'Low (96 kbps)', description: 'Smaller file size' },
    { value: 'medium', label: 'Medium (128 kbps)', description: 'Standard quality' },
    { value: 'high', label: 'High (192 kbps)', description: 'CD quality' },
    { value: 'lossless', label: 'Lossless (320 kbps)', description: 'Maximum quality' }
  ];

  function updateClipProperty(clipId: string, property: keyof VideoClip, value: any) {
    dispatch('updateClipProperty', { clipId, property, value });
  }

  function handleTimelineStartChange(value: number) {
    if (!selectedClip) return;
    
    const newStart = Math.max(0, Math.min(value, selectedClip.timelineEnd - 0.1));
    updateClipProperty(selectedClip.id, 'timelineStart', newStart);
  }

  function handleTimelineEndChange(value: number) {
    if (!selectedClip) return;
    
    const newEnd = Math.min(totalDuration, Math.max(value, selectedClip.timelineStart + 0.1));
    updateClipProperty(selectedClip.id, 'timelineEnd', newEnd);
  }

  // Media replacement functionality
  function handleMediaFileUpload(event: Event) {
    const target = event.target as HTMLInputElement;
    if (!target.files || !target.files[0] || !selectedClip) return;
    
    const file = target.files[0];
    const url = URL.createObjectURL(file);
    
    // Clean up old URL if it exists
    if (selectedClip.url && selectedClip.url.startsWith('blob:')) {
      URL.revokeObjectURL(selectedClip.url);
    }
    
    // Update clip with new file and URL
    updateClipProperty(selectedClip.id, 'file', file);
    updateClipProperty(selectedClip.id, 'url', url);
    
    // For video/audio files, update duration if possible
    if (selectedClip.type === 'video' || selectedClip.type === 'audio') {
      const media = document.createElement(selectedClip.type === 'video' ? 'video' : 'audio');
      media.onloadedmetadata = () => {
        if (selectedClip) {
          const newDuration = media.duration;
          const currentClipDuration = selectedClip.timelineEnd - selectedClip.timelineStart;
          const newTimelineEnd = selectedClip.timelineStart + Math.min(newDuration, currentClipDuration);
          
          updateClipProperty(selectedClip.id, 'duration', newDuration);
          updateClipProperty(selectedClip.id, 'contentEndTime', newDuration);
          updateClipProperty(selectedClip.id, 'timelineEnd', newTimelineEnd);
        }
      };
      media.src = url;
    }
    
    // Reset file input
    target.value = '';
  }

  function getMediaAcceptType() {
    if (!selectedClip) return '';
    
    switch (selectedClip.type) {
      case 'video':
        return 'video/*';
      case 'audio':
        return 'audio/*';
      case 'image':
        return selectedClip.sampleData?.type === 'sticker' ? 'image/png,image/svg+xml' : 'image/*';
      default:
        return '';
    }
  }

  function getMediaTypeLabel() {
    if (!selectedClip) return '';
    
    switch (selectedClip.type) {
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'image':
        return selectedClip.sampleData?.type === 'sticker' ? 'Sticker' : 'Image';
      default:
        return 'Media';
    }
  }

  function getCurrentMediaName() {
    if (!selectedClip) return 'No media selected';
    
    if (selectedClip.file) {
      return selectedClip.file.name;
    } else if (selectedClip.url) {
      return 'External media';
    } else if (selectedClip.sampleData?.thumbnail) {
      return 'Sample media';
    }
    
    return 'No media selected';
  }

  // Check if current clip is an image layer (not sticker)
  function isImageLayer() {
    return selectedClip?.type === 'image' && selectedClip?.sampleData?.type !== 'sticker';
  }

  // Check if current clip is a video layer
  function isVideoLayer() {
    return selectedClip?.type === 'video';
  }

  // Check if current clip supports media replacement
  function supportsMediaReplacement() {
    return selectedClip && ['video', 'audio', 'image'].includes(selectedClip.type);
  }

  // Check if current clip supports blending
  function supportsBlending() {
    return selectedClip && ['video', 'image', 'text'].includes(selectedClip.type);
  }

  // Export functions
  function handleExport() {
    // In a real scenario, this would involve complex video generation.
    // For now, we'll simulate an export and provide a placeholder URL.
    const exportedVideoUrl = 'https://videos.pexels.com/video-files/15432179/15432179-uhd_2560_1440_50fps.mp4'; // Placeholder URL

    dispatch('publishPiece', {
      pieceId: pieceId,
      videoUrl: exportedVideoUrl,
      newProjectStatus: 'published'
    });

    alert(`Publishing started!\nFormat: ${exportSettings.format}\nQuality: ${exportSettings.quality}\nResolution: ${exportSettings.resolution}`);
  }

  function resetExportSettings() {
    exportSettings = {
      format: 'mp4',
      quality: 'high',
      resolution: '1920x1080',
      framerate: 30,
      bitrate: 'auto',
      audioQuality: 'high',
      includeAudio: true,
      filename: 'my-video'
    };
  }

  // Calculate estimated file size (rough approximation)
  function getEstimatedFileSize() {
    const durationInSeconds = totalDuration;
    let bitrate = 5000; // Default 5 Mbps
    
    if (exportSettings.bitrate !== 'auto' && exportSettings.bitrate !== 'custom') {
      bitrate = parseInt(exportSettings.bitrate);
    } else {
      // Estimate based on quality and resolution
      const resolutionMultiplier = exportSettings.resolution.includes('3840') ? 4 : 
                                   exportSettings.resolution.includes('2560') ? 2.5 :
                                   exportSettings.resolution.includes('1920') ? 1 :
                                   exportSettings.resolution.includes('1280') ? 0.6 : 0.3;
      
      const qualityMultiplier = exportSettings.quality === 'low' ? 0.5 :
                               exportSettings.quality === 'medium' ? 1 :
                               exportSettings.quality === 'high' ? 1.5 : 1;
      
      bitrate = Math.round(2500 * resolutionMultiplier * qualityMultiplier);
    }
    
    // Calculate file size in MB
    const fileSizeMB = (bitrate * durationInSeconds) / (8 * 1000);
    
    if (fileSizeMB < 1000) {
      return `~${Math.round(fileSizeMB)} MB`;
    } else {
      return `~${(fileSizeMB / 1000).toFixed(1)} GB`;
    }
  }
</script>

<div class="right-sidebar">
  <!-- Tab Navigation -->
  <div class="tab-nav">
    <button 
      class="tab-btn" 
      class:active={activeTab === 'properties'}
      on:click={() => activeTab = 'properties'}
    >
      Properties
    </button>
    <button 
      class="tab-btn" 
      class:active={activeTab === 'export'}
      on:click={() => activeTab = 'export'}
    >
      Publishing
    </button>
  </div>

  <!-- Tab Content -->
  <div class="tab-content">
    {#if activeTab === 'properties'}
      <!-- Properties Tab Content -->
      <div class="properties-header">
        <h3>Properties</h3>
      </div>
      <div class="properties-content">
        {#if selectedClip}
          <!-- Basic Properties -->
          <div class="property-section">
            <h4>Basic</h4>
            
            <div class="property-group">
              <label>Layer Name</label>
              <input 
                type="text" 
                value={selectedClip.name ?? ''}
                on:input={(e) => updateClipProperty(selectedClip.id, 'name', e.target.value)}
                class="property-input" 
              />
            </div>

            <div class="property-row">
              <div class="property-group">
                <label>Start Time</label>
                <input 
                  type="number" 
                  value={(selectedClip.timelineStart ?? 0).toFixed(1)}
                  on:input={(e) => handleTimelineStartChange(parseFloat(e.target.value) || 0)}
                  step="0.1"
                  min="0"
                  max={totalDuration}
                  class="property-input" 
                />
              </div>
              <div class="property-group">
                <label>End Time</label>
                <input 
                  type="number" 
                  value={(selectedClip.timelineEnd ?? 0).toFixed(1)}
                  on:input={(e) => handleTimelineEndChange(parseFloat(e.target.value) || 0)}
                  step="0.1"
                  min={selectedClip.timelineStart + 0.1}
                  max={totalDuration}
                  class="property-input" 
                />
              </div>
            </div>

            <div class="property-group">
              <label>Duration</label>
              <span class="property-value">
                {(selectedClip.timelineEnd - selectedClip.timelineStart).toFixed(1)}s
              </span>
            </div>
          </div>

          <!-- Media Source (for video, audio, image, sticker layers) -->
          {#if supportsMediaReplacement()}
            <div class="property-section">
              <h4>Media Source</h4>
              
              <div class="property-group">
                <label>Current {getMediaTypeLabel()}</label>
                <div class="current-media-info">
                  <span class="media-name">{getCurrentMediaName()}</span>
                </div>
              </div>
              
              <div class="property-group">
                <label>Replace {getMediaTypeLabel()}</label>
                <input
                  type="file"
                  accept={getMediaAcceptType()}
                  on:change={handleMediaFileUpload}
                  class="file-input"
                  id="media-replace-input"
                />
                <label for="media-replace-input" class="media-upload-btn">
                  <span class="upload-icon">📁</span>
                  <span class="upload-text">Choose New {getMediaTypeLabel()}</span>
                </label>
              </div>
            </div>
          {/if}

          <!-- Transform Properties -->
          <div class="property-section">
            <h4>Transform</h4>
            
            <!-- Position controls - hidden for image and video layers -->
            {#if !isImageLayer() && !isVideoLayer()}
              <div class="property-row">
                <div class="property-group">
                  <label>X Position (%)</label>
                  <input 
                    type="number" 
                    value={selectedClip.position?.x ?? 50}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'position', { ...(selectedClip.position || { x: 50, y: 50 }), x: parseFloat(e.target.value) || 0 })}
                    step="0.1"
                    min="0"
                    max="100"
                    class="property-input" 
                  />
                </div>
                <div class="property-group">
                  <label>Y Position (%)</label>
                  <input 
                    type="number" 
                    value={selectedClip.position?.y ?? 50}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'position', { ...(selectedClip.position || { x: 50, y: 50 }), y: parseFloat(e.target.value) || 0 })}
                    step="0.1"
                    min="0"
                    max="100"
                    class="property-input" 
                  />
                </div>
              </div>
            {/if}

            <!-- Size controls - hidden for image and video layers -->
            {#if !isImageLayer() && !isVideoLayer()}
              <div class="property-row">
                <div class="property-group">
                  <label>Width (% of canvas)</label>
                  <input 
                    type="number" 
                    value={selectedClip.scale?.x ?? 20}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'scale', { ...(selectedClip.scale || { x: 20, y: 20 }), x: parseFloat(e.target.value) || 1 })}
                    step="1"
                    min="1"
                    max="200"
                    class="property-input" 
                  />
                </div>
                <div class="property-group">
                  <label>Height (% of canvas)</label>
                  <input 
                    type="number" 
                    value={selectedClip.scale?.y ?? 20}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'scale', { ...(selectedClip.scale || { x: 20, y: 20 }), y: parseFloat(e.target.value) || 1 })}
                    step="1"
                    min="1"
                    max="200"
                    class="property-input" 
                  />
                </div>
              </div>
            {/if}

            <div class="property-group">
              <label>Rotation (degrees)</label>
              <input 
                type="number" 
                value={selectedClip.rotation ?? 0}
                on:input={(e) => updateClipProperty(selectedClip.id, 'rotation', parseFloat(e.target.value) || 0)}
                step="1"
                min="-360"
                max="360"
                class="property-input" 
              />
            </div>

            <div class="property-group">
              <label>Opacity</label>
              <div class="slider-container">
                <input 
                  type="range" 
                  value={selectedClip.opacity ?? 1}
                  on:input={(e) => updateClipProperty(selectedClip.id, 'opacity', parseFloat(e.target.value))}
                  min="0"
                  max="1"
                  step="0.01"
                  class="property-slider" 
                />
                <span class="slider-value">{Math.round((selectedClip.opacity ?? 1) * 100)}%</span>
              </div>
            </div>
          </div>

          <!-- Text Properties (for text layers) -->
          {#if selectedClip.type === 'text'}
            <div class="property-section">
              <h4>Text</h4>
              
              <div class="property-group">
                <label>Text Content</label>
                <textarea 
                  value={selectedClip.content ?? ''}
                  on:input={(e) => updateClipProperty(selectedClip.id, 'content', e.target.value)}
                  class="property-input text-content"
                  rows="3"
                ></textarea>
              </div>

              <div class="property-row">
                <div class="property-group">
                  <label>Font Size (% of canvas)</label>
                  <input 
                    type="number" 
                    value={selectedClip.fontSize ?? 2.5}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'fontSize', parseFloat(e.target.value) || 2.5)}
                    step="0.1"
                    min="0.5"
                    max="20"
                    class="property-input" 
                  />
                </div>
                <div class="property-group">
                  <label>Line Height</label>
                  <input 
                    type="number" 
                    value={selectedClip.lineHeight ?? 1.2}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'lineHeight', parseFloat(e.target.value) || 1.2)}
                    step="0.1"
                    min="0.5"
                    max="3"
                    class="property-input" 
                  />
                </div>
              </div>

              <div class="property-group">
                <label>Font Family</label>
                <select 
                  value={selectedClip.fontFamily ?? 'Arial, sans-serif'}
                  on:change={(e) => updateClipProperty(selectedClip.id, 'fontFamily', e.target.value)}
                  class="property-select"
                >
                  {#each fontFamilies as font}
                    <option value={font}>{font.split(',')[0]}</option>
                  {/each}
                </select>
              </div>

              <div class="property-row">
                <div class="property-group">
                  <label>Font Weight</label>
                  <select 
                    value={selectedClip.fontWeight ?? 'normal'}
                    on:change={(e) => updateClipProperty(selectedClip.id, 'fontWeight', e.target.value)}
                    class="property-select"
                  >
                    {#each fontWeights as weight}
                      <option value={weight.value}>{weight.label}</option>
                    {/each}
                  </select>
                </div>
                <div class="property-group">
                  <label>Font Style</label>
                  <select 
                    value={selectedClip.fontStyle ?? 'normal'}
                    on:change={(e) => updateClipProperty(selectedClip.id, 'fontStyle', e.target.value)}
                    class="property-select"
                  >
                    <option value="normal">Normal</option>
                    <option value="italic">Italic</option>
                    <option value="oblique">Oblique</option>
                  </select>
                </div>
              </div>

              <div class="property-group">
                <label>Text Alignment</label>
                <div class="button-group">
                  {#each textAlignOptions as align}
                    <button
                      class="align-btn"
                      class:active={(selectedClip.textAlign ?? 'center') === align.value}
                      on:click={() => updateClipProperty(selectedClip.id, 'textAlign', align.value)}
                      title={align.label}
                    >
                      {align.icon}
                    </button>
                  {/each}
                </div>
              </div>

              <div class="property-group">
                <label>Text Color</label>
                <div class="color-input-container">
                  <input 
                    type="color" 
                    value={selectedClip.textColor ?? '#FFFFFF'}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'textColor', e.target.value)}
                    class="color-input" 
                  />
                  <input 
                    type="text" 
                    value={selectedClip.textColor ?? '#FFFFFF'}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'textColor', e.target.value)}
                    class="property-input color-text" 
                  />
                </div>
              </div>

              <div class="property-group">
                <label>Letter Spacing</label>
                <input 
                  type="number" 
                  value={selectedClip.letterSpacing ?? 0}
                  on:input={(e) => updateClipProperty(selectedClip.id, 'letterSpacing', parseFloat(e.target.value) || 0)}
                  step="0.1"
                  min="-5"
                  max="10"
                  class="property-input" 
                />
              </div>

              <div class="property-group">
                <label>Text Shadow</label>
                <input 
                  type="text" 
                  value={selectedClip.textShadow ?? 'none'}
                  on:input={(e) => updateClipProperty(selectedClip.id, 'textShadow', e.target.value)}
                  placeholder="e.g., 2px 2px 4px rgba(0,0,0,0.5)"
                  class="property-input" 
                />
              </div>
            </div>
          {/if}

          <!-- Media Properties (for video/audio/image layers) -->
          {#if selectedClip.type === 'video' || selectedClip.type === 'audio' || selectedClip.type === 'image'}
            <div class="property-section">
              <h4>Media</h4>
              
              {#if selectedClip.type === 'video' || selectedClip.type === 'audio'}
                <div class="property-group">
                  <label>Volume</label>
                  <div class="slider-container">
                    <input 
                      type="range" 
                      value={selectedClip.volume ?? 1}
                      on:input={(e) => updateClipProperty(selectedClip.id, 'volume', parseFloat(e.target.value))}
                      min="0"
                      max="2"
                      step="0.01"
                      class="property-slider" 
                    />
                    <span class="slider-value">{Math.round((selectedClip.volume ?? 1) * 100)}%</span>
                  </div>
                </div>

                <div class="property-group">
                  <label>Playback Rate</label>
                  <input 
                    type="number" 
                    value={selectedClip.playbackRate ?? 1}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'playbackRate', parseFloat(e.target.value) || 1)}
                    step="0.1"
                    min="0.1"
                    max="4"
                    class="property-input" 
                  />
                </div>
              {/if}

              {#if selectedClip.type === 'video' || selectedClip.type === 'image'}
                <div class="property-group">
                  <label>Brightness</label>
                  <div class="slider-container">
                    <input 
                      type="range" 
                      value={selectedClip.brightness ?? 1}
                      on:input={(e) => updateClipProperty(selectedClip.id, 'brightness', parseFloat(e.target.value))}
                      min="0"
                      max="2"
                      step="0.01"
                      class="property-slider" 
                    />
                    <span class="slider-value">{Math.round((selectedClip.brightness ?? 1) * 100)}%</span>
                  </div>
                </div>

                <div class="property-group">
                  <label>Contrast</label>
                  <div class="slider-container">
                    <input 
                      type="range" 
                      value={selectedClip.contrast ?? 1}
                      on:input={(e) => updateClipProperty(selectedClip.id, 'contrast', parseFloat(e.target.value))}
                      min="0"
                      max="2"
                      step="0.01"
                      class="property-slider" 
                    />
                    <span class="slider-value">{Math.round((selectedClip.contrast ?? 1) * 100)}%</span>
                  </div>
                </div>

                <div class="property-group">
                  <label>Saturation</label>
                  <div class="slider-container">
                    <input 
                      type="range" 
                      value={selectedClip.saturation ?? 1}
                      on:input={(e) => updateClipProperty(selectedClip.id, 'saturation', parseFloat(e.target.value))}
                      min="0"
                      max="2"
                      step="0.01"
                      class="property-slider" 
                    />
                    <span class="slider-value">{Math.round((selectedClip.saturation ?? 1) * 100)}%</span>
                  </div>
                </div>

                <div class="property-group">
                  <label>Blur</label>
                  <div class="slider-container">
                    <input 
                      type="range" 
                      value={selectedClip.blur ?? 0}
                      on:input={(e) => updateClipProperty(selectedClip.id, 'blur', parseFloat(e.target.value))}
                      min="0"
                      max="20"
                      step="0.1"
                      class="property-slider" 
                    />
                    <span class="slider-value">{(selectedClip.blur ?? 0).toFixed(1)}px</span>
                  </div>
                </div>
              {/if}
            </div>
          {/if}

          <!-- Blending Properties (for video, image and text layers) -->
          {#if supportsBlending()}
            <div class="property-section">
              <h4>Blending</h4>
              
              <div class="property-group">
                <label>Mix Blend Mode</label>
                <select 
                  value={selectedClip.mixBlendMode ?? 'normal'}
                  on:change={(e) => updateClipProperty(selectedClip.id, 'mixBlendMode', e.target.value)}
                  class="property-select"
                >
                  {#each mixBlendModeOptions as blendMode}
                    <option value={blendMode.value}>{blendMode.label}</option>
                  {/each}
                </select>
              </div>
            </div>
          {/if}

          <!-- Animation Properties -->
          <div class="property-section">
            <h4>Animation</h4>
            
            <div class="property-group">
              <label>Animation Type</label>
              <select 
                value={selectedClip.animation ?? 'none'}
                on:change={(e) => updateClipProperty(selectedClip.id, 'animation', e.target.value)}
                class="property-select"
              >
                {#each animationOptions as animation}
                  <option value={animation.value}>{animation.label}</option>
                {/each}
              </select>
            </div>

            {#if (selectedClip.animation ?? 'none') !== 'none'}
              <div class="property-row">
                <div class="property-group">
                  <label>Duration (s)</label>
                  <input 
                    type="number" 
                    value={selectedClip.animationDuration ?? 1}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'animationDuration', parseFloat(e.target.value) || 1)}
                    step="0.1"
                    min="0.1"
                    max="10"
                    class="property-input" 
                  />
                </div>
                <div class="property-group">
                  <label>Delay (s)</label>
                  <input 
                    type="number" 
                    value={selectedClip.animationDelay ?? 0}
                    on:input={(e) => updateClipProperty(selectedClip.id, 'animationDelay', parseFloat(e.target.value) || 0)}
                    step="0.1"
                    min="0"
                    max="10"
                    class="property-input" 
                  />
                </div>
              </div>
            {/if}
          </div>

        {:else}
          <div class="property-section">
            <h4>Canvas</h4>
            <div class="property-group">
              <label>Background</label>
              <input type="text" value="#000000" class="property-input" />
            </div>
            <div class="property-group">
              <label>Aspect Ratio</label>
              <span class="property-value">16:9</span>
            </div>
          </div>
        {/if}
      </div>

    {:else if activeTab === 'export'}
      <!-- Export Tab Content -->
      <div class="export-header">
        <h3>Publish Settings</h3>
        <button class="reset-btn" on:click={resetExportSettings} title="Reset to defaults">
          🔄
        </button>
      </div>
      
      <div class="export-content">
        <!-- Output Format -->
        <div class="export-section">
          <h4>Output Format</h4>
          
          <div class="property-group">
            <label>File Format</label>
            <select 
              bind:value={exportSettings.format}
              class="property-select"
            >
              {#each exportFormats as format}
                <option value={format.value}>{format.label}</option>
              {/each}
            </select>
            <div class="format-description">
              {exportFormats.find(f => f.value === exportSettings.format)?.description}
            </div>
          </div>

          <div class="property-group">
            <label>Filename</label>
            <div class="filename-container">
              <input 
                type="text" 
                bind:value={exportSettings.filename}
                class="property-input filename-input" 
                placeholder="my-video"
              />
              <span class="file-extension">.{exportSettings.format}</span>
            </div>
          </div>
        </div>

        <!-- Video Quality -->
        <div class="export-section">
          <h4>Video Quality</h4>
          
          <div class="property-group">
            <label>Quality Preset</label>
            <select 
              bind:value={exportSettings.quality}
              class="property-select"
            >
              {#each qualityPresets as preset}
                <option value={preset.value}>{preset.label}</option>
              {/each}
            </select>
            <div class="format-description">
              {qualityPresets.find(p => p.value === exportSettings.quality)?.description}
            </div>
          </div>

          <div class="property-group">
            <label>Resolution</label>
            <select 
              bind:value={exportSettings.resolution}
              class="property-select"
            >
              {#each resolutionOptions as resolution}
                <option value={resolution.value}>{resolution.label}</option>
              {/each}
            </select>
            <div class="format-description">
              {resolutionOptions.find(r => r.value === exportSettings.resolution)?.description}
            </div>
          </div>

          <div class="property-row">
            <div class="property-group">
              <label>Frame Rate</label>
              <select 
                bind:value={exportSettings.framerate}
                class="property-select"
              >
                {#each framerateOptions as fps}
                  <option value={fps.value}>{fps.label}</option>
                {/each}
              </select>
            </div>
            <div class="property-group">
              <label>Bitrate</label>
              <select 
                bind:value={exportSettings.bitrate}
                class="property-select"
              >
                {#each bitrateOptions as bitrate}
                  <option value={bitrate.value}>{bitrate.label}</option>
                {/each}
              </select>
            </div>
          </div>
        </div>

        <!-- Audio Settings -->
        <div class="export-section">
          <h4>Audio Settings</h4>
          
          <div class="property-group">
            <label class="checkbox-label">
              <input 
                type="checkbox" 
                bind:checked={exportSettings.includeAudio}
                class="checkbox-input"
              />
              <span class="checkbox-custom"></span>
              Include Audio
            </label>
          </div>

          {#if exportSettings.includeAudio}
            <div class="property-group">
              <label>Audio Quality</label>
              <select 
                bind:value={exportSettings.audioQuality}
                class="property-select"
              >
                {#each audioQualityOptions as quality}
                  <option value={quality.value}>{quality.label}</option>
                {/each}
              </select>
              <div class="format-description">
                {audioQualityOptions.find(q => q.value === exportSettings.audioQuality)?.description}
              </div>
            </div>
          {/if}
        </div>

        <!-- Export Summary -->
        <div class="export-section">
          <h4>Export Summary</h4>
          
          <div class="export-summary">
            <div class="summary-row">
              <span class="summary-label">Duration:</span>
              <span class="summary-value">{totalDuration.toFixed(1)}s</span>
            </div>
            <div class="summary-row">
              <span class="summary-label">Format:</span>
              <span class="summary-value">{exportSettings.format.toUpperCase()}</span>
            </div>
            <div class="summary-row">
              <span class="summary-label">Resolution:</span>
              <span class="summary-value">{exportSettings.resolution}</span>
            </div>
            <div class="summary-row">
              <span class="summary-label">Frame Rate:</span>
              <span class="summary-value">{exportSettings.framerate} fps</span>
            </div>
            <div class="summary-row">
              <span class="summary-label">Estimated Size:</span>
              <span class="summary-value">{getEstimatedFileSize()}</span>
            </div>
          </div>
        </div>

        <!-- Export Actions -->
        <div class="export-actions">
          <button class="export-btn primary" on:click={handleExport}>
            <span class="export-icon">🎬</span>
            Publish Piece
          </button>
          <button class="export-btn secondary" on:click={resetExportSettings}>
            Reset Settings
          </button>
        </div>
      </div>
    {/if}
  </div>
</div>

<style>
  /* Right Sidebar */
  .right-sidebar {
    width: 100%;
    background: white;
    border-left: 1px solid #d0d0d0;
    display: flex;
    flex-direction: column;
    height: 100%;
  }

  /* Tab Navigation */
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
    transition: all 0.2s ease;
    border-radius: 0px;
  }

  .tab-btn:hover {
    background: #f8f8f8;
    color: #333;
  }

  .tab-btn.active {
    color: #007AFF;
    border-bottom-color: #007AFF;
    background: #f8f9ff;
  }

  /* Tab Content */
  .tab-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .properties-header, .export-header {
    padding: 1rem;
    border-bottom: 1px solid #d0d0d0;
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .properties-header h3, .export-header h3 {
    margin: 0;
    font-size: 1rem;
    font-weight: 500;
  }

  .reset-btn {
    background: none;
    border: none;
    font-size: 1rem;
    cursor: pointer;
    padding: 0.25rem;
    border-radius: 4px;
    transition: background 0.2s;
  }

  .reset-btn:hover {
    background: #f0f0f0;
  }

  .properties-content, .export-content {
    flex: 1;
    padding: 1rem;
    overflow-y: auto;
  }

  .property-section, .export-section {
    margin-bottom: 1.5rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #f0f0f0;
  }

  .property-section:last-of-type, .export-section:last-of-type {
    border-bottom: none;
  }

  .property-section h4, .export-section h4 {
    margin: 0 0 1rem 0;
    font-size: 0.9rem;
    font-weight: 600;
    color: #333;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .property-group {
    margin-bottom: 1rem;
  }

  .property-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  .property-group label {
    display: block;
    font-size: 0.8rem;
    color: #666;
    margin-bottom: 0.25rem;
    font-weight: 500;
  }

  .property-input {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    font-size: 0.9rem;
    transition: border-color 0.2s;
  }

  .property-input:focus {
    outline: none;
    border-color: #007AFF;
  }

  .property-select {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    font-size: 0.9rem;
    background: white;
    cursor: pointer;
  }

  .property-select:focus {
    outline: none;
    border-color: #007AFF;
  }

  .text-content {
    resize: vertical;
    min-height: 60px;
    font-family: inherit;
  }

  .property-value {
    display: block;
    padding: 0.5rem;
    background: #f8f8f8;
    border: 1px solid #e0e0e0;
    border-radius: 4px;
    font-size: 0.9rem;
    color: #666;
  }

  .slider-container {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .property-slider {
    flex: 1;
    height: 4px;
    background: #e0e0e0;
    border-radius: 2px;
    outline: none;
    cursor: pointer;
  }

  .property-slider::-webkit-slider-thumb {
    appearance: none;
    width: 16px;
    height: 16px;
    background: #007AFF;
    border-radius: 50%;
    cursor: pointer;
  }

  .property-slider::-moz-range-thumb {
    width: 16px;
    height: 16px;
    background: #007AFF;
    border-radius: 50%;
    cursor: pointer;
    border: none;
  }

  .slider-value {
    font-size: 0.8rem;
    color: #666;
    min-width: 40px;
    text-align: right;
  }

  .button-group {
    display: flex;
    gap: 0.25rem;
  }

  .align-btn {
    flex: 1;
    padding: 0.5rem;
    border: 1px solid #d0d0d0;
    background: white;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.9rem;
    transition: all 0.2s;
  }

  .align-btn:hover {
    background: #f0f0f0;
  }

  .align-btn.active {
    background: #007AFF;
    color: white;
    border-color: #007AFF;
  }

  .color-input-container {
    display: flex;
    gap: 0.5rem;
    align-items: center;
  }

  .color-input {
    width: 40px;
    height: 40px;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    cursor: pointer;
    padding: 0;
  }

  .color-text {
    flex: 1;
    font-family: monospace;
    text-transform: uppercase;
  }

  /* Media Source Styles */
  .current-media-info {
    padding: 0.5rem;
    background: #f8f8f8;
    border: 1px solid #e0e0e0;
    border-radius: 4px;
    margin-bottom: 0.5rem;
  }

  .media-name {
    font-size: 0.8rem;
    color: #666;
    word-break: break-all;
  }

  .file-input {
    display: none;
  }

  .media-upload-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    width: 100%;
    padding: 0.75rem;
    border: 2px dashed #d0d0d0;
    border-radius: 6px;
    background: #fafafa;
    cursor: pointer;
    transition: all 0.2s;
    font-size: 0.9rem;
    color: #666;
  }

  .media-upload-btn:hover {
    border-color: #007AFF;
    background: #f8f9ff;
    color: #007AFF;
  }

  .upload-icon {
    font-size: 1.1rem;
  }

  .upload-text {
    font-weight: 500;
  }

  /* Export Specific Styles */
  .format-description {
    font-size: 0.7rem;
    color: #888;
    margin-top: 0.25rem;
    font-style: italic;
  }

  .filename-container {
    display: flex;
    align-items: center;
    border: 1px solid #d0d0d0;
    border-radius: 4px;
    overflow: hidden;
  }

  .filename-input {
    border: none;
    border-radius: 0;
    flex: 1;
  }

  .filename-input:focus {
    border: none;
  }

  .file-extension {
    padding: 0.5rem;
    background: #f8f8f8;
    border-left: 1px solid #e0e0e0;
    font-size: 0.9rem;
    color: #666;
    font-family: monospace;
  }

  .checkbox-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
    font-size: 0.9rem;
    margin-bottom: 0 !important;
  }

  .checkbox-input {
    display: none;
  }

  .checkbox-custom {
    width: 18px;
    height: 18px;
    border: 2px solid #d0d0d0;
    border-radius: 3px;
    position: relative;
    transition: all 0.2s;
  }

  .checkbox-input:checked + .checkbox-custom {
    background: #007AFF;
    border-color: #007AFF;
  }

  .checkbox-input:checked + .checkbox-custom::after {
    content: '✓';
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: white;
    font-size: 0.8rem;
    font-weight: bold;
  }

  .export-summary {
    background: #f8f9ff;
    border: 1px solid #e0e8ff;
    border-radius: 6px;
    padding: 1rem;
  }

  .summary-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
  }

  .summary-row:last-child {
    margin-bottom: 0;
  }

  .summary-label {
    font-size: 0.8rem;
    color: #666;
    font-weight: 500;
  }

  .summary-value {
    font-size: 0.8rem;
    color: #333;
    font-weight: 600;
    font-family: monospace;
  }

  .export-actions {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    margin-top: 1.5rem;
    padding-top: 1rem;
    border-top: 1px solid #f0f0f0;
  }

  .export-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    border: none;
    border-radius: 6px;
    font-size: 0.9rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .export-btn.primary {
    background: #007AFF;
    color: white;
  }

  .export-btn.primary:hover {
    background: #0056CC;
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(0, 122, 255, 0.3);
  }

  .export-btn.secondary {
    background: #f0f0f0;
    color: #666;
    border: 1px solid #d0d0d0;
  }

  .export-btn.secondary:hover {
    background: #e0e0e0;
    color: #333;
  }

  .export-icon {
    font-size: 1.1rem;
  }
</style>