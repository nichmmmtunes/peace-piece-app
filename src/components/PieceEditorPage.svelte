<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import PieceEditor from './PieceEditor/PieceEditor.svelte';
  import type { VideoClip } from './PieceEditor/types';
  
  export let params = { id: '' };
  
  let piece: any = null;
  let loading = true;
  let error: string | null = null;
  let saving = false;
  let saveMessage = '';
  let saveTimeout: number;
  let editorData: any = null;
  let canEdit = false;
  let isOrganizer = false;
  let isContributor = false;
  
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
      
      // Load editor data if it exists
      editorData = piece.editor_data || null;
      
      // Log the loaded editor data for debugging
      console.log('DEBUG: Loaded editor data:', editorData);
      if (editorData && editorData.clips) {
        console.log('DEBUG: Loaded clips:', editorData.clips);
        console.log('DEBUG: Clip URLs:', editorData.clips.map(clip => ({ id: clip.id, type: clip.type, url: clip.url })));
      }
      
      // Check if current user is the organizer of this piece
      if ($user && piece.organizer_id) {
        // Get the organizer data to check if current user owns this organizer
        const { data: organizerData } = await supabase
          .from('organizers')
          .select('user_id')
          .eq('id', piece.organizer_id)
          .single();
        
        if (organizerData && organizerData.user_id === $user.id) {
          isOrganizer = true;
          canEdit = true;
        }
      }
      
      // Check if current user is a contributor to this piece
      if ($user && !isOrganizer && piece.contributors) {
        // Get the user's profile to check if they're a contributor
        const { data: profileData } = await supabase
          .from('profiles')
          .select('id')
          .eq('id', $user.id)
          .single();
          
        if (profileData) {
          // Check if user's profile ID matches any contributor's ID
          const isUserContributor = piece.contributors.some(
            (contributor: any) => contributor.id === profileData.id
          );
          
          if (isUserContributor) {
            isContributor = true;
            canEdit = true;
          }
        }
      }
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
  
  // Helper function to upload a file to Supabase Storage
  async function uploadFileToStorage(file: File, bucket: string): Promise<string> {
    // Validate file object and its name property
    if (!file || typeof file.name !== 'string' || !file.name.trim()) {
      throw new Error('Invalid file: file name is missing or invalid');
    }
    
    const fileExt = file.name.split('.').pop();
    const fileName = `${crypto.randomUUID()}.${fileExt}`;
    
    console.log(`DEBUG: Uploading file to bucket '${bucket}' with name '${fileName}'`);
    
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(fileName, file);
      
    if (error) {
      console.error(`DEBUG: Error uploading file to ${bucket}:`, error);
      throw error;
    }
    
    console.log(`DEBUG: File uploaded successfully to ${bucket}/${fileName}`);
    
    const { data: { publicUrl } } = supabase.storage
      .from(bucket)
      .getPublicUrl(fileName);
      
    console.log(`DEBUG: Generated public URL: ${publicUrl}`);
    
    // Test URL validity
    try {
      const response = await fetch(publicUrl, { method: 'HEAD' });
      console.log(`DEBUG: URL test response status: ${response.status}`);
      if (!response.ok) {
        console.warn(`DEBUG: URL test failed with status ${response.status}`);
      }
    } catch (e) {
      console.error(`DEBUG: URL test fetch error:`, e);
    }
    
    return publicUrl;
  }
  
  async function saveEditorData(data: any) {
    if (!$user || !canEdit || !piece) return;
    
    try {
      saving = true;
      saveMessage = 'Saving...';
      
      // Process clips to upload any local files to storage
      if (data.clips && Array.isArray(data.clips)) {
        console.log(`DEBUG: Processing ${data.clips.length} clips for saving`);
        
        for (let i = 0; i < data.clips.length; i++) {
          const clip = data.clips[i];
          
          console.log(`DEBUG: Processing clip ${i}:`, {
            id: clip.id,
            type: clip.type,
            name: clip.name,
            url: clip.url,
            hasFile: !!clip.file
          });
          
          // Check if clip has a file that needs to be uploaded
          if (clip.file && clip.url && clip.url.startsWith('blob:')) {
            console.log(`DEBUG: Clip ${clip.id} has a blob URL that needs to be uploaded:`, clip.url);
            
            try {
              // Determine the appropriate bucket based on file type
              let bucket = 'pieces'; // default bucket
              if (clip.type === 'audio') {
                bucket = 'audio';
              } else if (clip.type === 'video') {
                bucket = 'videos';
              }
              
              console.log(`DEBUG: Selected clip file for upload ${clip.file}`);
              
              // Upload the file and get the public URL
              const publicUrl = await uploadFileToStorage(clip.file, bucket);
              
              console.log(`DEBUG: Clip ${clip.id} URL before update:`, clip.url);
              
              // Update the clip with the new URL and remove the file reference
              data.clips[i] = {
                ...clip,
                url: publicUrl,
                file: undefined // Remove file reference as it's now uploaded
              };
              
              console.log(`DEBUG: Clip ${clip.id} URL after update:`, data.clips[i].url);
            } catch (uploadError) {
              console.error(`DEBUG: Error uploading file for clip ${clip.id}:`, uploadError);
              // Continue with other clips even if one fails
            }
          } else if (clip.url) {
            console.log(`DEBUG: Clip ${clip.id} already has a permanent URL:`, clip.url);
          } else {
            console.log(`DEBUG: Clip ${clip.id} has no URL to process`);
          }
        }
      }
      
      // Log the data being saved for debugging
      console.log('DEBUG: Saving editor data with clips:', data.clips);
      if (data.clips) {
        console.log('DEBUG: Clip URLs being saved:', data.clips.map(clip => ({ 
          id: clip.id, 
          type: clip.type, 
          url: clip.url,
          isBlob: clip.url?.startsWith('blob:') || false
        })));
      }
      
      const { error: updateError } = await supabase
        .from('pieces')
        .update({
          editor_data: data,
          updated_at: new Date().toISOString()
        })
        .eq('id', params.id);
        
      if (updateError) throw updateError;
      
      saveMessage = 'Changes saved successfully!';
      
      // Clear the message after 3 seconds
      if (saveTimeout) clearTimeout(saveTimeout);
      saveTimeout = setTimeout(() => {
        saveMessage = '';
      }, 3000);
      
    } catch (e: any) {
      saveMessage = `Error saving changes: ${e.message}`;
      console.error('DEBUG: Error in saveEditorData:', e);
    } finally {
      saving = false;
    }
  }
  
  // Throttle helper
  function throttle<T extends (...args: any[]) => void>(fn: T, wait: number) {
    let lastCall = 0;
    let timeout: ReturnType<typeof setTimeout> | null = null;
    let lastArgs: any;

    return function (...args: Parameters<T>) {
      const now = Date.now();
      lastArgs = args;
      if (now - lastCall >= wait) {
        lastCall = now;
        fn(...args);
      } else if (!timeout) {
        timeout = setTimeout(() => {
          lastCall = Date.now();
          timeout = null;
          fn(...lastArgs);
        }, wait - (now - lastCall));
      }
    };
  }

  // Throttled save handler
  const throttledSaveEditorData = throttle(saveEditorData, 1000);

  function handleEditorSave(event: CustomEvent<any>) {
    const editorData = event.detail;
    throttledSaveEditorData(editorData);
  }

  async function handlePublishPiece(event: CustomEvent<{ pieceId: string, videoUrl: string, newProjectStatus: string }>) {
    const { pieceId, videoUrl, newProjectStatus } = event.detail;
    
    try {
      saving = true;
      saveMessage = 'Publishing piece...';

      const { error: updateError } = await supabase
        .from('pieces')
        .update({
          video_url: videoUrl,
          project_status: newProjectStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', pieceId);
        
      if (updateError) throw updateError;
      
      saveMessage = 'Piece published successfully!';
      
      if (saveTimeout) clearTimeout(saveTimeout);
      saveTimeout = setTimeout(() => {
        saveMessage = '';
      }, 3000);

    } catch (e: any) {
      saveMessage = `Error publishing piece: ${e.message}`;
    } finally {
      saving = false;
    }
  }
  
  onMount(() => {
    if (params.id) {
      loadPiece();
    }
    
    return () => {
      if (saveTimeout) clearTimeout(saveTimeout);
    };
  });
</script>

<div class="piece-editor-page">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading piece editor...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Error Loading Piece</h2>
        <p>{error}</p>
        <a href="/piece/{params.id}" use:link class="back-button">Back to Piece</a>
      </div>
    </div>
  {:else if !canEdit}
    <div class="unauthorized-container" transition:fade>
      <div class="unauthorized-card">
        <h2>Access Denied</h2>
        <p>You don't have permission to edit this piece. Only the organizer and contributors can edit this piece.</p>
        <a href="/piece/{params.id}" use:link class="back-button">Back to Piece</a>
      </div>
    </div>
  {:else if piece}
    <div class="editor-container" in:fly={{ y: 20, duration: 300 }}>
      <div class="editor-header">
        <div class="header-left">
          <a href="/piece/{params.id}" use:link class="back-link">
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M19 12H5"></path>
              <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
            Back to Piece
          </a>
          <h1>{piece.title} <span class="inter">- Editor</span></h1>
        </div>
        
        <div class="header-right">
          {#if saveMessage}
            <div class="save-message" class:error={saveMessage.includes('Error')} transition:fade>
              {saveMessage}
            </div>
          {/if}
          
          <div class="editor-status">
            <div class="saved-indicator saved"></div>
            {#if isOrganizer}
              <span class="status-badge organizer">Organizer</span>
            {:else if isContributor}
              <span class="status-badge contributor">Contributor</span>
            {/if}
          </div>
        </div>
      </div>
      
      <div class="editor-content">
        <PieceEditor 
          initialData={editorData}
          pieceId={params.id}
          currentProjectStatus={piece.project_status}
          on:save={handleEditorSave}
          on:publishPiece={handlePublishPiece}
        />
      </div>
    </div>
  {/if}
</div>

<style>
  .piece-editor-page {
    width: 100%;
    height: 100vh;
    display: flex;
    flex-direction: column;
    background: var(--bg-color);
    padding: 0px !important
  }

  .loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 400px;
    gap: var(--space-4);
  }

  .loading-spinner {
    width: 40px;
    height: 40px;
    border: 3px solid var(--border-color);
    border-top: 3px solid var(--color-primary-600);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .error-container,
  .unauthorized-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
    padding: var(--space-6);
  }

  .error-card,
  .unauthorized-card {
    background: var(--card-bg);
    border: 1px solid var(--color-error-200);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    max-width: 500px;
  }

  .error-card h2,
  .unauthorized-card h2 {
    color: var(--color-error-600);
    margin-bottom: var(--space-4);
  }

  .back-button {
    display: inline-block;
    margin-top: var(--space-4);
    padding: var(--space-2) var(--space-4);
    background-color: var(--color-primary-600);
    color: white;
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    transition: background-color 0.2s;
  }

  .back-button:hover {
    background-color: var(--color-primary-700);
  }

  .editor-container {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .editor-header {
    padding: 0px var(--space-4);
    background: var(--color-neutral-900);
    border-bottom: 1px solid var(--color-neutral-700);
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
    position: relative;
    min-height: 42px;
  }

  .header-left {
    display: flex;
    align-items: center;
    gap: var(--space-4);
  }

  .back-link {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    color: var(--color-neutral-400);
    text-decoration: none;
    font-weight: 500;
    transition: color 0.2s;
    font-size: 16px;
    font-weight: 400;
  }

  .back-link:hover {
    color: var(--color-primary-00);
  }

  .header-left h1 {
    font-size: 1.25rem;
    font-weight: 600;
    margin: 0;
    color: var(--color-neutral-100);
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
    white-space: nowrap;
  }

  .header-left h1 .inter {
    font-family: 'Inter';
    font-weight: 400;
    font-size: 16px;
  }

  .header-right {
    display: flex;
    align-items: center;
    gap: var(--space-4);
  }

  .save-message {
    padding: var(--space-2) var(--space-4);
    background-color: var(--color-success-50);
    color: var(--color-success-700);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
    transition: all 0.2s;
    display: none;
  }

  .save-message.error {
    background-color: var(--color-error-50);
    color: var(--color-error-700);
  }

  .editor-status {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .editor-status .saved-indicator {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background-color: var(--color-success-600);
    transition: background-color 0.2s;
  }

  .editor-status .saved-indicator.saved {
    background-color: var(--color-success-600);
  }

  .editor-status .saved-indicator.saving {
    background-color: var(--color-warning-600);
  }

  .editor-status .saved-indicator.error {
    background-color: var(--color-error-600);
  }

  .status-badge {
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-md);
    font-size: 0.75rem;
    font-weight: 500;
  }

  .status-badge.organizer {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .status-badge.contributor {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
  }

  .editor-content {
    flex: 1;
    overflow: hidden;
  }

  @media (max-width: 768px) {
    .editor-header {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-3);
    }

    .header-left {
      width: 100%;
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-2);
    }

    .header-right {
      width: 100%;
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-2);
    }
  }
</style>