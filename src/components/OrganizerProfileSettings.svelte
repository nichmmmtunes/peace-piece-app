<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  
  let organizerName = '';
  let organizerDescription = '';
  let avatarUrl: string | null = null;
  let loading = false;
  let message = '';
  let uploading = false;
  let messageTimeout: number;
  let organizerExists = false;
  let organizerId: string | null = null;
  
  async function loadOrganizerProfile() {
    try {
      loading = true;
      
      const { data, error } = await supabase
        .from('organizers')
        .select('id, name, description, avatar_url')
        .eq('user_id', $user?.id)
        .maybeSingle();
        
      if (error) throw error;
      
      if (data) {
        organizerExists = true;
        organizerId = data.id;
        organizerName = data.name || '';
        organizerDescription = data.description || '';
        avatarUrl = data.avatar_url;
      } else {
        organizerExists = false;
        organizerId = null;
      }
    } catch (error) {
      console.error('Error loading organizer profile:', error);
    } finally {
      loading = false;
    }
  }
  
  async function saveOrganizerProfile() {
    try {
      loading = true;
      message = '';
      
      if (!organizerName.trim()) {
        throw new Error('Organizer name is required');
      }
      
      if (organizerExists && organizerId) {
        // Update existing organizer profile
        const { error } = await supabase
          .from('organizers')
          .update({
            name: organizerName.trim(),
            description: organizerDescription.trim(),
            avatar_url: avatarUrl,
            updated_at: new Date().toISOString(),
          })
          .eq('id', organizerId);
          
        if (error) throw error;
        
        message = 'Organizer profile updated successfully!';
      } else {
        // Create new organizer profile
        const { data, error } = await supabase
          .from('organizers')
          .insert({
            name: organizerName.trim(),
            description: organizerDescription.trim(),
            avatar_url: avatarUrl,
            user_id: $user?.id,
          })
          .select('id')
          .single();
          
        if (error) throw error;
        
        organizerId = data.id;
        organizerExists = true;
        message = 'Organizer profile created successfully!';
      }
      
      // Clear the message after 3 seconds
      if (messageTimeout) clearTimeout(messageTimeout);
      messageTimeout = setTimeout(() => {
        message = '';
      }, 3000);
      
    } catch (error: any) {
      message = error.message;
    } finally {
      loading = false;
    }
  }
  
  async function uploadAvatar(event: Event) {
    try {
      uploading = true;
      const target = event.target as HTMLInputElement;
      const file = target.files?.[0];
      
      if (!file) return;
      
      const fileExt = file.name.split('.').pop();
      // Create a path that includes the user ID to ensure proper RLS
      const filePath = `${$user?.id}/organizer_avatar.${fileExt}`;
      
      const { error: uploadError } = await supabase.storage
        .from('organizer_avatars')
        .upload(filePath, file, { upsert: true });
        
      if (uploadError) throw uploadError;
      
      const { data: { publicUrl } } = supabase.storage
        .from('organizer_avatars')
        .getPublicUrl(filePath);
        
      avatarUrl = publicUrl;
      
      // If organizer profile already exists, update it with the new avatar URL
      if (organizerExists && organizerId) {
        const { error } = await supabase
          .from('organizers')
          .update({
            avatar_url: avatarUrl,
            updated_at: new Date().toISOString(),
          })
          .eq('id', organizerId);
          
        if (error) throw error;
        
        message = 'Organizer avatar updated successfully!';
        
        // Clear the message after 3 seconds
        if (messageTimeout) clearTimeout(messageTimeout);
        messageTimeout = setTimeout(() => {
          message = '';
        }, 3000);
      }
      
    } catch (error: any) {
      message = error.message;
    } finally {
      uploading = false;
    }
  }
  
  function deleteOrganizerProfile() {
    if (!organizerId) return;
    
    if (confirm('Are you sure you want to delete your organizer profile? This action cannot be undone.')) {
      supabase
        .from('organizers')
        .delete()
        .eq('id', organizerId)
        .then(({ error }) => {
          if (error) {
            message = `Error deleting profile: ${error.message}`;
          } else {
            message = 'Organizer profile deleted successfully';
            organizerExists = false;
            organizerId = null;
            organizerName = '';
            organizerDescription = '';
            avatarUrl = null;
            
            // Redirect back to settings after a short delay
            setTimeout(() => {
              push('/settings');
            }, 2000);
          }
        });
    }
  }
  
  onMount(() => {
    if ($user) {
      loadOrganizerProfile();
    }
  });
</script>

<div class="organizer-profile-settings">
  <div class="settings-header">
    <div class="breadcrumb">
      <a href="/settings" use:link>← Back to Settings</a>
    </div>
    <h1>{organizerExists ? 'Update' : 'Create'} Organizer Profile</h1>
    <p>Manage your organization details and create Peace Pieces</p>
  </div>

  <div class="settings-content">
    <div class="settings-card">
      {#if message}
        <div class="message" class:error={message.includes('Error') || message.includes('error')} transition:fade>
          {message}
        </div>
      {/if}
      
      <form on:submit|preventDefault={saveOrganizerProfile}>
        <!-- Avatar Section -->
        <div class="avatar-section">
          <div class="avatar-container" on:click={() => document.getElementById('avatar-input')?.click()}>
            {#if avatarUrl}
              <img src={avatarUrl} alt="Organizer Avatar" class="avatar" />
            {:else}
              <div class="avatar-placeholder">
                {organizerName ? organizerName[0].toUpperCase() : $user?.email?.[0].toUpperCase() || 'O'}
              </div>
            {/if}
            <div class="avatar-overlay">
              <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"></path>
                <circle cx="12" cy="13" r="4"></circle>
              </svg>
              <span>Change Photo</span>
            </div>
          </div>
          <input
            type="file"
            id="avatar-input"
            accept="image/*"
            on:change={uploadAvatar}
            style="display: none;"
          />
          <div class="avatar-info">
            <p class="avatar-label">Organizer Logo/Avatar</p>
            <p class="avatar-description">This image will be displayed on your Peace Pieces and organization profile</p>
          </div>
        </div>

        <div class="form-group">
          <label for="organizerName">Organizer Name *</label>
          <input
            type="text"
            id="organizerName"
            bind:value={organizerName}
            required
            disabled={loading}
            placeholder="Enter your organization name"
          />
          <p class="field-description">This is the name that will be displayed as the organizer of your Peace Pieces</p>
        </div>
        
        <div class="form-group">
          <label for="organizerDescription">Description</label>
          <textarea
            id="organizerDescription"
            bind:value={organizerDescription}
            rows="5"
            disabled={loading}
            placeholder="Describe your organization, its mission, and the types of projects you create"
          ></textarea>
          <p class="field-description">A compelling description helps others understand your organization's purpose and values</p>
        </div>
        
        <div class="form-actions">
          <button type="submit" class="primary" disabled={loading || uploading || !organizerName.trim()}>
            {#if loading}
              <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                  <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                </circle>
              </svg>
              {organizerExists ? 'Updating...' : 'Creating...'}
            {:else}
              {organizerExists ? 'Update' : 'Create'} Organizer Profile
            {/if}
          </button>
          
          {#if organizerExists}
            <button type="button" class="danger" on:click={deleteOrganizerProfile} disabled={loading}>
              Delete Organizer Profile
            </button>
          {/if}
        </div>
      </form>
    </div>
    
    {#if organizerExists}
      <div class="settings-card info-card">
        <h2>What's Next?</h2>
        <p>Now that you have an organizer profile, you can:</p>
        <ul>
          <li>Create new Peace Pieces to support causes you care about</li>
          <li>Invite artists to collaborate on your projects</li>
          <li>Manage funding and sponsorships for your initiatives</li>
        </ul>
        <a href="/create-peace" use:link class="create-button">
          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
          Create New Peace Piece
        </a>
      </div>
    {/if}
  </div>
</div>

<style>
  .organizer-profile-settings {
    padding: var(--space-6);
    max-width: 800px;
    margin: 0 auto;
  }

  .settings-header {
    margin-bottom: var(--space-6);
  }

  .breadcrumb {
    margin-bottom: var(--space-4);
  }

  .breadcrumb a {
    color: var(--text-muted);
    text-decoration: none;
    font-size: 0.875rem;
    display: inline-flex;
    align-items: center;
    gap: var(--space-1);
  }

  .breadcrumb a:hover {
    text-decoration: underline;
  }

  .settings-header h1 {
    font-weight: 700;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .settings-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
  }

  .settings-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .settings-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .info-card {
    background-color: var(--color-primary-50);
    border-color: var(--color-primary-200);
  }

  .info-card h2 {
    color: var(--color-primary-700);
  }

  .info-card ul {
    margin: var(--space-4) 0;
    padding-left: var(--space-6);
  }

  .info-card li {
    margin-bottom: var(--space-2);
    color: var(--color-primary-800);
  }

  .message {
    padding: var(--space-3);
    border-radius: var(--radius-md);
    margin-bottom: var(--space-4);
    background-color: var(--color-success-50);
    color: var(--color-success-700);
    border: 1px solid var(--color-success-200);
  }
  
  .message.error {
    background-color: var(--color-error-50);
    color: var(--color-error-700);
    border-color: var(--color-error-200);
  }

  .avatar-section {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    margin-bottom: var(--space-6);
    padding-bottom: var(--space-6);
    border-bottom: 1px solid var(--border-color);
  }

  .avatar-container {
    position: relative;
    width: 80px;
    height: 97px;
    border-radius: 100px;
    overflow: hidden;
    cursor: pointer;
    background-color: var(--color-neutral-100);
    flex-shrink: 0;
  }

  .avatar {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2.5rem;
    font-weight: 600;
    color: var(--color-neutral-500);
    background-color: var(--color-neutral-200);
  }

  .avatar-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.6);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    opacity: 0;
    transition: opacity 0.2s;
    gap: var(--space-1);
    text-align: center;
  }

  .avatar-overlay svg {
    stroke: #fff;
  }

  .avatar-overlay span {
    color: white;
    font-size: 0.75rem;
    font-weight: 500;
  }

  .avatar-container:hover .avatar-overlay {
    opacity: 1;
  }

  .avatar-info {
    flex: 1;
  }

  .avatar-label {
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .avatar-description {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
  }

  .form-group {
    margin-bottom: var(--space-6);
  }

  .form-group label {
    display: block;
    font-weight: 500;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .form-group input[type="text"],
  .form-group textarea {
    width: 100%;
    padding: var(--space-3);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    background: var(--card-bg);
    color: var(--text-color);
    font-size: 1rem;
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  .form-group input[type="text"]:focus,
  .form-group textarea:focus {
    outline: none;
    border-color: var(--color-primary-500);
    box-shadow: 0 0 0 3px var(--color-primary-100);
  }

  .field-description {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-top: var(--space-1);
  }

  .form-actions {
    display: flex;
    gap: var(--space-3);
    margin-top: var(--space-6);
    padding-top: var(--space-6);
    border-top: 1px solid var(--border-color);
  }

  .spinner {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .danger {
    background: var(--color-error-600);
    color: white;
    margin-left: auto;
  }

  .danger:hover {
    background-color: var(--color-error-700);
  }

  .create-button {
    display: inline-flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-3) var(--space-4);
    background-color: var(--color-primary-600);
    color: white;
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    margin-top: var(--space-4);
    transition: background-color 0.2s;
  }

  .create-button:hover {
    background-color: var(--color-primary-700);
  }

  @media (max-width: 768px) {
    .organizer-profile-settings {
      padding: var(--space-4);
    }

    .settings-header h1 {
      font-size: 2rem;
    }

    .avatar-section {
      flex-direction: column;
      text-align: center;
    }

    .form-actions {
      flex-direction: column;
    }

    .danger {
      margin-left: 0;
    }
  }
</style>