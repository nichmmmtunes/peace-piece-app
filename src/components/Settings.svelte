<script lang="ts">
  import { user } from '../stores/authStore';
  import { supabase } from '../lib/supabase';
  import { fade } from 'svelte/transition';
  import { link } from 'svelte-spa-router';
  
  let username = '';
  let website = '';
  let avatarUrl: string | null = null;
  let loading = false;
  let message = '';
  let uploading = false;
  let messageTimeout: number;
  let hasArtistProfile = false;
  let artistUsername = '';
  let hasOrganizerProfile = false;
  let organizerUsername = '';
  
  async function loadProfile() {
    try {
      loading = true;
      
      const { data, error } = await supabase
        .from('profiles')
        .select('username, website, avatar_url')
        .eq('id', $user?.id)
        .maybeSingle();
        
      if (error) throw error;
      
      if (data) {
        username = data.username || '';
        website = data.website || '';
        avatarUrl = data.avatar_url;
      }
      
      // Check if user has an artist profile
      const { data: artistData, error: artistError } = await supabase
        .from('artists')
        .select('id, artist_username')
        .eq('user_id', $user?.id)
        .maybeSingle();
        
      if (artistError) throw artistError;

      hasArtistProfile = !!artistData;

      if (artistData) {
        artistUsername = artistData.artist_username || '';
      }
      
      // Check if user has an organizer profile
      const { data: organizerData, error: organizerError } = await supabase
        .from('organizers')
        .select('id, organizer_username')
        .eq('user_id', $user?.id)
        .maybeSingle();
        
      if (organizerError) throw organizerError;
      
      hasOrganizerProfile = !!organizerData;

      if (organizerData) {
        organizerUsername = organizerData.organizer_username || '';
      }
      
    } catch (error) {
      console.error('Error loading profile:', error);
    } finally {
      loading = false;
    }
  }
  
  async function updateProfile() {
    try {
      loading = true;
      message = '';
      
      const { error } = await supabase
        .from('profiles')
        .upsert({
          id: $user?.id,
          username,
          website,
          avatar_url: avatarUrl,
          updated_at: new Date().toISOString(),
        });
        
      if (error) throw error;
      
      message = 'Settings updated successfully!';
      
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
      const filePath = `${$user?.id}/avatar.${fileExt}`;
      
      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(filePath, file, { upsert: true });
        
      if (uploadError) throw uploadError;
      
      const { data: { publicUrl } } = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);
        
      avatarUrl = publicUrl;
      await updateProfile();
      
    } catch (error: any) {
      message = error.message;
    } finally {
      uploading = false;
    }
  }
  
  $: if ($user) {
    loadProfile();
  }
</script>

<div class="settings-container">
  <div class="settings-header">
    <h1>Settings</h1>
    <p>Manage your account preferences and profile information</p>
  </div>

  <div class="settings-content">
    <!-- Artist Profile Section -->
    <div class="settings-card artist-profile-card">
      <div class="artist-profile-header">
        <div>
          <h2>Artist Profile</h2>
          <p class="artist-profile-description">
            {hasArtistProfile 
              ? 'Manage your artist profile to update your artistic mediums and bio' 
              : 'Create an artist profile to apply for Peace Pieces and showcase your work'}
          </p>
        </div>
      </div>

      <div class="artist-profile-actions">
        <a href="/settings/artist-profile" use:link class="artist-profile-button">
          {hasArtistProfile ? 'Manage Artist Profile' : 'Create Artist Profile'}
        </a>
        
        {#if hasArtistProfile && artistUsername !==''}
          <div class="artist-profile-status">
            <a href="/artist/{ artistUsername }" use:link class="artist-profile-button">
            View Artist Profile
            </a>
          </div>
        {/if}
      </div>
    </div>

    <!-- Organizer Profile Section -->
    <div class="settings-card organizer-profile-card">
      <div class="organizer-profile-header">
        <div>
          <h2>Organizer Profile</h2>
          <p class="organizer-profile-description">
            {hasOrganizerProfile 
              ? 'Manage your organizer profile to update your organization details' 
              : 'Create an organizer profile to start new Peace Pieces and manage projects'}
          </p>
        </div>
      </div>
      
      <div class="organizer-profile-actions">
        <a href="/settings/organizer-profile" use:link class="organizer-profile-button">
          {hasOrganizerProfile ? 'Manage Organizer Profile' : 'Create Organizer Profile'}
        </a>
        {#if hasOrganizerProfile && organizerUsername !== ''}
          <div class="organizer-profile-status">
            <a href="/organizer/{ organizerUsername }" use:link class="organizer-profile-button">
              View Organizer Profile
            </a>
          </div>
        {/if}
      </div>
    </div>

    <div class="settings-card">
      <h2>Profile Information</h2>
      
      {#if message}
        <div class="message" class:error={message.includes('error')} transition:fade>
          {message}
        </div>
      {/if}
      
      <form on:submit|preventDefault={updateProfile}>
        <div class="avatar-section">
          <div class="avatar-container" on:click={() => document.getElementById('avatar-input')?.click()}>
            {#if avatarUrl}
              <img src={avatarUrl} alt="Profile" class="avatar" />
            {:else}
              <div class="avatar-placeholder">
                {username ? username[0].toUpperCase() : $user?.email?.[0].toUpperCase() || '?'}
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
            <p class="avatar-label">Profile Photo</p>
            <p class="avatar-description">Click to upload a new photo. JPG, PNG or GIF (max 5MB)</p>
          </div>
        </div>

        <div class="form-grid">
          <div class="form-group">
            <label for="email">Email Address</label>
            <input
              type="email"
              id="email"
              value={$user?.email || ''}
              disabled
              class="disabled-input"
            />
            <p class="field-description">Your email address cannot be changed</p>
          </div>
          
          <div class="form-group">
            <label for="username">Username</label>
            <input
              type="text"
              id="username"
              bind:value={username}
              disabled={loading}
              placeholder="Enter your username"
            />
            <p class="field-description">This will be displayed on your public profile</p>
          </div>
          
          <div class="form-group">
            <label for="website">Website</label>
            <input
              type="url"
              id="website"
              bind:value={website}
              disabled={loading}
              placeholder="https://your-website.com"
            />
            <p class="field-description">Share your personal website or portfolio</p>
          </div>
        </div>
        
        <div class="form-actions">
          <button type="submit" class="primary" disabled={loading || uploading}>
            {#if loading || uploading}
              <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                  <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                </circle>
              </svg>
              {uploading ? 'Uploading...' : 'Saving...'}
            {:else}
              Save Changes
            {/if}
          </button>
        </div>
      </form>
    </div>

    <!-- Account Settings -->
    <div class="settings-card">
      <h2>Account Settings</h2>
      <div class="setting-item">
        <div class="setting-info">
          <h3>Email Notifications</h3>
          <p>Receive updates about pieces you follow and new projects</p>
        </div>
        <label class="toggle">
          <input type="checkbox" checked />
          <span class="toggle-slider"></span>
        </label>
      </div>

      <div class="setting-item">
        <div class="setting-info">
          <h3>Marketing Communications</h3>
          <p>Receive news about Peace Piece and featured artists</p>
        </div>
        <label class="toggle">
          <input type="checkbox" />
          <span class="toggle-slider"></span>
        </label>
      </div>

      <div class="setting-item">
        <div class="setting-info">
          <h3>Public Profile</h3>
          <p>Make your profile visible to other users</p>
        </div>
        <label class="toggle">
          <input type="checkbox" checked />
          <span class="toggle-slider"></span>
        </label>
      </div>
    </div>

    <!-- Danger Zone -->
    <div class="settings-card danger-zone">
      <h2>Danger Zone</h2>
      <div class="danger-actions">
        <div class="danger-item">
          <div class="danger-info">
            <h3>Delete Account</h3>
            <p>Permanently delete your account and all associated data</p>
          </div>
          <button class="danger-button">Delete Account</button>
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  .settings-container {
    padding: var(--space-6);
    max-width: 1000px;
    margin: 0 auto 0 0;
  }

  .settings-header {
    margin-bottom: var(--space-8);
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
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  :global(.light-mode) .settings-card {
    background: var(--bg-color);
  }

  .artist-profile-card,
  .organizer-profile-card {
    background: var(--bg-color);
    border-color: var(--card-bg);
    border: none;
  }

  :global(.dark-mode) .artist-profile-card,
  :global(.dark-mode) .organizer-profile-card {
    border: solid 1px var(--border-color);
  }

  .artist-profile-header,
  .organizer-profile-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: var(--space-4);
  }

  .artist-profile-header h2,
  .organizer-profile-header h2 {
    color: var(--color-primary-700);
    margin-bottom: var(--space-1);
  }

  .artist-profile-description,
  .organizer-profile-description {
    color: var(--text-muted);
    margin: 0;
    font-size: 0.875rem;
  }

  .artist-profile-button,
  .organizer-profile-button {
    display: inline-flex;
    align-items: center;
    padding: var(--space-2) var(--space-4);
    background: var(--text-color);
    color: var(--bg-color);
    border-radius: 50px;
    text-decoration: none;
    font-weight: 500;
    transition: background-color 0.2s;
    white-space: nowrap;
  }

  .artist-profile-button:hover,
  .organizer-profile-button:hover {
    background-color: var(--text-muted);
  }

  .artist-profile-actions,
  .organizer-profile-actions {
    display: flex;
    justify-content: flex-end;
    align-items: center;
    margin-top: var(--space-2);
    margin-right: calc(var(--space-2) * -1);
    gap: var(--space-4);
  }

  .status-badge {
    display: inline-flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-3);
    background-color: var(--color-success-100);
    color: var(--color-success-700);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
  }

  .status-badge.organizer-badge {
    background-color: var(--color-neutral-100);
    color: var(--color-neutral-700);
  }

  .settings-card h2 {
    font-size: 18px;
    font-weight: 400;
    margin-bottom: var(--space-4);
    margin-top: -5px;
    color: var(--text-color);
  }

  .settings-card.danger-zone h2 {
    margin-top: -5px;
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
    border: solid 3px var(--bg-color);
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
    font-size: 2rem;
    font-weight: 500;
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

  .form-grid {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .form-group label {
    font-weight: 500;
    color: var(--text-color);
  }

  .form-group input {
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  .disabled-input {
    background-color: var(--color-neutral-50);
    color: var(--text-muted);
    cursor: not-allowed;
  }

  .field-description {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
  }

  .form-actions {
    margin-top: var(--space-6);
    padding-top: var(--space-6);
    border-top: 1px solid var(--border-color);
  }

  .form-actions button.primary {
    background: var(--text-color);
    color: var(--bg-color);
    border: none;
    padding: var(--space-2) var(--space-4);
    border-radius: 50px;
  }

  .spinner {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .setting-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--space-4) 0;
    border-bottom: 1px solid var(--border-color);
  }

  .setting-item:last-child {
    border-bottom: none;
  }

  .setting-info h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .setting-info p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
  }

  .toggle {
    position: relative;
    display: inline-block;
    width: 48px;
    height: 24px;
  }

  .toggle input {
    opacity: 0;
    width: 0;
    height: 0;
  }

  .toggle-slider {
    position: absolute;
    cursor: pointer;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: var(--color-neutral-300);
    transition: 0.3s;
    border-radius: 24px;
  }

  .toggle-slider:before {
    position: absolute;
    content: "";
    height: 18px;
    width: 18px;
    left: 3px;
    bottom: 3px;
    background-color: white;
    transition: 0.3s;
    border-radius: 50%;
  }

  .toggle input:checked + .toggle-slider {
    background-color: var(--color-primary-600);
  }

  .toggle input:checked + .toggle-slider:before {
    transform: translateX(24px);
  }

  .settings-card.danger-zone {
    border: solid 1px var(--color-error-600) !important;
  }

  .danger-zone h2 {
    color: var(--color-error-600);
  }

  .danger-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .danger-info h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--color-error-600);
  }

  .danger-info p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
  }

  .danger-button {
    background: var(--color-error-600);
    color: white;
    border: none;
    padding: var(--space-2) var(--space-4);
    border-radius: 50px;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .danger-button:hover {
    background-color: var(--color-error-700);
  }

  @media (max-width: 768px) {
    .settings-container {
      padding: var(--space-4);
    }

    .settings-header h1 {
      font-size: 2rem;
    }

    .avatar-section {
      flex-direction: column;
      text-align: center;
    }

    .setting-item,
    .danger-item {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-3);
    }

    .toggle,
    .danger-button {
      align-self: flex-end;
    }
    
    .artist-profile-header,
    .organizer-profile-header {
      flex-direction: column;
      align-items: flex-start;
    }
    
    .artist-profile-button,
    .organizer-profile-button {
      align-self: stretch;
      justify-content: center;
      margin-top: var(--space-2);
    }
  }
</style>
