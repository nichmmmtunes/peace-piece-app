<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import PieceEditor from './PieceEditor/PieceEditor.svelte';
  import VersionHistory from './PieceEditor/VersionHistory.svelte';
  import type { VideoClip } from './PieceEditor/types';
  
  export let params = { id: '' };
  
  let piece: any = null;
  let organizer: any = null;
  let contributors: any[] = [];
  let loading = true;
  let error: string | null = null;
  let saving = false;
  let saveMessage = '';
  let saveTimeout: number;
  let editorData: any = null;
  let canEdit = false;
  let isOrganizer = false;
  let isContributor = false;
  let versionName = '';
  let showVersionDialog = false;
  let isCreatingNamedVersion = false;
  let pendingEditorData: any = null;
  
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
          .select('*')
          .eq('id', piece.organizer_id)
          .single();
        
        if (organizerData && organizerData.user_id === $user.id) {
          isOrganizer = true;
          canEdit = true;
        }

        organizer = organizerData;
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

      if (piece.contributors) {
        // Get the full contributor profiles
        const { data: contributorProfiles, error: contributorError } = await supabase
          .from('artists')
          .select('*')
          .in('id', piece.contributors.map((c: any) => c.id));

        if (contributorError) {
          console.error('DEBUG: Error loading contributors:', contributorError);
          throw contributorError; 
        }

        contributors = contributorProfiles || [];
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
  
  async function saveEditorData(data: any, createNamedVersion = false) {
    if (!$user || !canEdit || !piece) return;
    
    try {
      saving = true;
      saveMessage = 'Saving...';
      
      // If we're creating a named version, first get the current editor data
      if (createNamedVersion && versionName.trim()) {
        // Get the current editor data from the database
        const { data: currentPieceData, error: currentDataError } = await supabase
          .from('pieces')
          .select('editor_data')
          .eq('id', params.id)
          .single();
          
        if (currentDataError) throw currentDataError;
        
        if (currentPieceData && currentPieceData.editor_data) {
          // Save the current editor data to the history table with the version name
          const { error: historyError } = await supabase
            .from('editor_data_history')
            .insert({
              piece_id: params.id,
              editor_data: currentPieceData.editor_data,
              version_name: versionName.trim(),
              created_by: $user.id
            });
            
          if (historyError) throw historyError;
          
          saveMessage = `Version "${versionName}" saved successfully!`;
          versionName = '';
        }
      } else {
        // For regular saves (not named versions), save the current state to history
        // Get the current editor data from the database
        const { data: currentPieceData, error: currentDataError } = await supabase
          .from('pieces')
          .select('editor_data')
          .eq('id', params.id)
          .single();
          
        if (currentDataError) throw currentDataError;
        
        if (currentPieceData && currentPieceData.editor_data) {
          // Save the current editor data to the history table (without a version name)
          const { error: historyError } = await supabase
            .from('editor_data_history')
            .insert({
              piece_id: params.id,
              editor_data: currentPieceData.editor_data,
              created_by: $user.id
            });
            
          if (historyError) {
            console.warn('Failed to save history, but continuing with update:', historyError);
          }
        }
      }
      
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
      
      if (!createNamedVersion) {
        saveMessage = 'Changes saved successfully!';
      }
      
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
      showVersionDialog = false;
      isCreatingNamedVersion = false;
      pendingEditorData = null;
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

  // Throttled save handler - changed from 1000ms to 30000ms (30 seconds)
  const throttledSaveEditorData = throttle(saveEditorData, 30000);

  function handleEditorSave(event: CustomEvent<any>) {
    const editorData = event.detail;
    throttledSaveEditorData(editorData);
  }
  
  function handleCreateNamedVersion(event: CustomEvent<any>) {
    pendingEditorData = event.detail;
    showVersionDialog = true;
    isCreatingNamedVersion = true;
  }
  
  function confirmCreateNamedVersion() {
    if (pendingEditorData && versionName.trim()) {
      saveEditorData(pendingEditorData, true);
    }
  }
  
  function cancelCreateNamedVersion() {
    showVersionDialog = false;
    isCreatingNamedVersion = false;
    pendingEditorData = null;
    versionName = '';
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

  function handleRestoreVersion(event: CustomEvent<any>) {
    const restoredEditorData = event.detail;
    if (restoredEditorData) {
      editorData = restoredEditorData;
      saveMessage = 'Restored to previous version';
      
      // Save the restored version
      saveEditorData(restoredEditorData);
    }
  }

  function getInitials(fullName: string | null): string {
    if (!fullName) {
      return ""; // Handle cases where the name might be null or empty
    }

    const nameParts = fullName.split(" ");

    if (nameParts.length > 1) {
      // If there's more than one part, assume first and last name
      const firstNameInitial = nameParts[0].charAt(0);
      const lastNameInitial = nameParts[nameParts.length - 1].charAt(0);
      return `${firstNameInitial}${lastNameInitial}`.toUpperCase();
    } else {
      // If only one part (or no spaces), just take the first initial
      return nameParts[0].charAt(0).toUpperCase();
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
        <a href="/piece/{params.id}" use:link class="back-button">Back</a>
      </div>
    </div>
  {:else if !canEdit}
    <div class="unauthorized-container" transition:fade>
      <div class="unauthorized-card">
        <h2>Access Denied</h2>
        <p>You don't have permission to edit this piece. Only the organizer and contributors can edit this piece.</p>
        <a href="/piece/{params.id}" use:link class="back-button">Back</a>
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
            Back
          </a>
          <h1>{piece.title} <span class="inter">- Editor</span></h1>
        </div>
        
        <div class="header-right">
          <VersionHistory 
            pieceId={params.id}
            isSaving={saving}
            saveMessage={saveMessage}
            currentEditorData={editorData}
            on:restoreVersion={handleRestoreVersion}
          />
          
          <div class="editor-status">
            <div class="editor-badges">
              <span class="status-badge organizer">
                <span class="badge-name">{organizer ? organizer.name : 'Unknown Organizer'}</span>
                <span class="badge-initial">{getInitials(organizer ? organizer.name : '')}</span>
                {#if organizer.avatar_url}
                  <img src="{organizer.avatar_url}" width="30px" height="auto" alt="{organizer.name}" />
                {/if}
              </span>
              {#each contributors as contributor, index (contributor.id)}
                <span class="status-badge contributor">
                  <span class="badge-name">{contributor.name}</span>
                  <span class="badge-initial">{getInitials(contributor.name)}</span>
                  {#if contributor.avatar_url}
                    <img src="{contributor.avatar_url}" width="30px" height="auto" alt="{contributor.name}" />
                  {/if}
                </span>
              {/each}
            </div>
          </div>
        </div>
      </div>
      
      <div class="editor-content">
        <PieceEditor 
          initialData={editorData}
          pieceId={params.id}
          currentProjectStatus={piece.project_status}
          on:save={handleEditorSave}
          on:createNamedVersion={handleCreateNamedVersion}
          on:publishPiece={handlePublishPiece}
        />
      </div>
    </div>
    
    <!-- Version Name Dialog -->
    {#if showVersionDialog}
      <div class="version-dialog-overlay" transition:fade>
        <div class="version-dialog" in:fly={{ y: 20, duration: 300 }}>
          <h2>Save Version</h2>
          <p>Enter a name for this version to help you identify it later.</p>
          
          <div class="version-form">
            <input 
              type="text" 
              bind:value={versionName} 
              placeholder="Version name (e.g., First Draft, Final Cut)"
              class="version-input"
            />
            
            <div class="version-actions">
              <button class="cancel-button" on:click={cancelCreateNamedVersion}>Cancel</button>
              <button 
                class="save-button" 
                on:click={confirmCreateNamedVersion}
                disabled={!versionName.trim() || saving}
              >
                {#if saving}
                  <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                      <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                    </circle>
                  </svg>
                  Saving...
                {:else}
                  Save Version
                {/if}
              </button>
            </div>
          </div>
        </div>
      </div>
    {/if}
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
    min-height: 200px;
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
    background: #FBFBFB;
    border-bottom: 1px solid var(--color-neutral-300);
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
    position: relative;
    min-height: 49px;
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
    color: black;
    text-decoration: none;
    font-weight: 500;
    transition: color 0.2s;
    font-size: .9rem;
    font-weight: 400;
    user-select: none;
  }

  .back-link:hover {
    color: var(--color-primary-600);
  }

  .header-left h1 {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0;
    color: var(--color-neutral-900);
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
    gap: 1rem;
  }

  .editor-badges {
    padding: 0px;
    border-radius: var(--radius-md);
    font-size: 0.75rem;
    font-weight: 500;
    display: flex;
  }

  .status-badge {
    width: 24px;
    height: 27px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-left: -2px;
    outline: solid 2.2px var(--color-primary-00);
    position: relative;
    overflow: hidden;
  }

  .status-badge .badge-name {
    display: none;
  }

  .status-badge .badge-initial {
    font-size: 10px;
    font-weight: 600;
    color: var(--color-neutral-800);
    text-transform: uppercase;
    user-select: none;
  }

  .status-badge img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    top: 0;
    left: 0;
    position: absolute;
    mix-blend-mode: overlay;
    opacity: .8;
  }

  .status-badge.organizer {
    background-color: var(--color-neutral-400);
    color: var(--color-primary-700);
    outline-color: var(--color-primary-600);
    z-index: 1;
  }

  .status-badge.contributor {
    background-color: var(--color-neutral-400);
    color: var(--color-accent-700);
    outline-color: var(--color-accent-700);
  }

  .editor-content {
    flex: 1;
    overflow: hidden;
  }
  
  /* Version Dialog Styles */
  .version-dialog-overlay {
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
  
  .version-dialog {
    background: white;
    border-radius: 8px;
    padding: 24px;
    width: 90%;
    max-width: 500px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  }
  
  .version-dialog h2 {
    margin: 0 0 8px 0;
    font-size: 1.5rem;
    color: var(--color-neutral-900);
  }
  
  .version-dialog p {
    margin: 0 0 20px 0;
    color: var(--color-neutral-600);
  }
  
  .version-form {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }
  
  .version-input {
    padding: 12px;
    border: 1px solid var(--color-neutral-300);
    border-radius: 6px;
    font-size: 1rem;
  }
  
  .version-input:focus {
    outline: none;
    border-color: var(--color-primary-500);
    box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
  }
  
  .version-actions {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
  }
  
  .cancel-button {
    padding: 8px 16px;
    background: var(--color-neutral-100);
    color: var(--color-neutral-700);
    border: 1px solid var(--color-neutral-300);
    border-radius: 6px;
    font-weight: 500;
    cursor: pointer;
  }
  
  .save-button {
    padding: 8px 16px;
    background: var(--color-primary-600);
    color: white;
    border: none;
    border-radius: 6px;
    font-weight: 500;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
  }
  
  .save-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
  
  .spinner {
    animation: spin 1s linear infinite;
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
    
    .version-dialog {
      width: 95%;
      padding: 16px;
    }
    
    .version-actions {
      flex-direction: column;
    }
    
    .cancel-button, .save-button {
      width: 100%;
    }
  }
</style>