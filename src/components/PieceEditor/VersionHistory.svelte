<script lang="ts">
  import { onMount, createEventDispatcher } from 'svelte';
  import { supabase } from '../../lib/supabase';

  export let pieceId: string;
  export let isSaving: boolean = false;
  export let saveMessage: string = '';
  export let currentEditorData: any = null;

  type Version = {
    id: string;
    version_name: string | null;
    created_at: string;
    created_by: string | null;
    editor_data: any;
  };

  let versions: Version[] = [];
  let selectedVersionId: string = 'current';
  let loadingVersions: boolean = false;
  let saveStatusColor: string = 'var(--color-success-600)';

  const dispatch = createEventDispatcher();

  async function loadVersions() {
    if (!pieceId) return;

    try {
      loadingVersions = true;
      
      const { data, error } = await supabase
        .from('editor_data_history')
        .select('*')
        .eq('piece_id', pieceId)
        .order('created_at', { ascending: false });
        
      if (error) throw error;
      
      versions = data || [];
      
    } catch (error) {
      console.error('Error loading version history:', error);
    } finally {
      loadingVersions = false;
    }
  }

  function handleVersionChange() {
    if (selectedVersionId === 'current') {
      // No need to restore if current version is selected
      return;
    }

    const selectedVersion = versions.find(v => v.id === selectedVersionId);
    if (selectedVersion && selectedVersion.editor_data) {
      dispatch('restoreVersion', selectedVersion.editor_data);
    }
  }

  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    });
  }

  onMount(() => {
    loadVersions();
  });

  // Update save status color based on saving state and message
  $: {
    if (isSaving) {
      saveStatusColor = 'var(--color-warning-500)'; // Yellow when saving
    } else if (saveMessage && saveMessage.includes('Error')) {
      saveStatusColor = 'var(--color-error-600)'; // Red on error
    } else {
      saveStatusColor = 'var(--color-success-600)'; // Green when saved
    }
  }
</script>

<div class="version-history">
  <div class="version-container">
    <div class="save-status-indicator" style="background-color: {saveStatusColor}"></div>
    
    <select 
      bind:value={selectedVersionId} 
      on:change={handleVersionChange}
      disabled={loadingVersions || isSaving}
      class="version-select"
    >
      <option value="current">Current Version</option>
      {#each versions as version}
        <option value={version.id}>
          {version.version_name ? version.version_name : formatDate(version.created_at)}
        </option>
      {/each}
    </select>
    
    {#if loadingVersions}
      <div class="loading-indicator">
        <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
            <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
          </circle>
        </svg>
      </div>
    {/if}
  </div>
  
  {#if isSaving}
    <div class="save-status">Saving...</div>
  {:else if saveMessage}
    <div class="save-status" class:error={saveMessage.includes('Error')}>{saveMessage}</div>
  {/if}
</div>

<style>
  .version-history {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-right: 16px;
  }
  
  .version-container {
    display: flex;
    align-items: center;
    gap: 8px;
    position: relative;
  }

  .save-status {
    display: none;
  }
  
  .save-status-indicator {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    transition: background-color 0.3s ease;
  }
  
  .version-select {
    background: #FBFBFB;
    border: 1px solid #E0E0E0;
    border-radius: 4px;
    padding: 4px 8px;
    font-size: 12px;
    min-width: 180px;
    cursor: pointer;
  }
  
  .version-select:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }
  
  .loading-indicator {
    position: absolute;
    right: 8px;
    top: 50%;
    transform: translateY(-50%);
    pointer-events: none;
  }
  
  .spinner {
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  .save-status {
    font-size: 12px;
    color: var(--color-success-600);
  }
  
  .save-status.error {
    color: var(--color-error-600);
  }
</style>