<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  
  let artistName = '';
  let artistBio = '';
  let avatarUrl: string | null = null;
  let loading = false;
  let message = '';
  let uploading = false;
  let messageTimeout: number;
  let artistExists = false;
  let artistId: string | null = null;
  let selectedMediums: string[] = [];
  
  const artisticMediums = [
    'Visual Art', 'Painting', 'Drawing', 'Sculpture', 'Photography', 
    'Digital Art', 'Mixed Media', 'Installation', 'Performance Art',
    'Poetry', 'Prose', 'Spoken Word', 'Screenwriting',
    'Music', 'Composition', 'Sound Design', 'Singing', 'Instrumental',
    'Dance', 'Choreography', 'Movement',
    'Film', 'Animation', 'Video',
    'Textiles', 'Fashion', 'Fiber Arts',
    'Ceramics', 'Glass', 'Metalwork', 'Woodworking',
    'Printmaking', 'Illustration', 'Graphic Design',
    'Other'
  ];
  
  async function loadArtistProfile() {
    try {
      loading = true;
      
      const { data, error } = await supabase
        .from('artists')
        .select('id, name, bio, avatar_url, artistic_mediums')
        .eq('user_id', $user?.id)
        .maybeSingle();
        
      if (error) throw error;
      
      if (data) {
        artistExists = true;
        artistId = data.id;
        artistName = data.name || '';
        artistBio = data.bio || '';
        avatarUrl = data.avatar_url;
        selectedMediums = data.artistic_mediums || [];
      } else {
        artistExists = false;
        artistId = null;
      }
    } catch (error) {
      console.error('Error loading artist profile:', error);
    } finally {
      loading = false;
    }
  }
  
  async function saveArtistProfile() {
    try {
      loading = true;
      message = '';
      
      if (!artistName.trim()) {
        throw new Error('Artist name is required');
      }
      
      if (artistExists && artistId) {
        // Update existing artist profile
        const { error } = await supabase
          .from('artists')
          .update({
            name: artistName.trim(),
            bio: artistBio.trim(),
            avatar_url: avatarUrl,
            artistic_mediums: selectedMediums,
            updated_at: new Date().toISOString(),
          })
          .eq('id', artistId);
          
        if (error) throw error;
        
        message = 'Artist profile updated successfully!';
      } else {
        // Create new artist profile
        const { data, error } = await supabase
          .from('artists')
          .insert({
            name: artistName.trim(),
            bio: artistBio.trim(),
            avatar_url: avatarUrl,
            artistic_mediums: selectedMediums,
            user_id: $user?.id,
          })
          .select('id')
          .single();
          
        if (error) throw error;
        
        artistId = data.id;
        artistExists = true;
        message = 'Artist profile created successfully!';
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
      // Fix: Change the file path to match the RLS policy
      const filePath = `${$user?.id}/artist_avatar.${fileExt}`;
      
      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(filePath, file, { upsert: true });
        
      if (uploadError) throw uploadError;
      
      const { data: { publicUrl } } = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);
        
      avatarUrl = publicUrl;
      
    } catch (error: any) {
      message = error.message;
    } finally {
      uploading = false;
    }
  }
  
  function toggleMedium(medium: string) {
    if (selectedMediums.includes(medium)) {
      selectedMediums = selectedMediums.filter(m => m !== medium);
    } else {
      selectedMediums = [...selectedMediums, medium];
    }
  }
  
  function deleteArtistProfile() {
    if (!artistId) return;
    
    if (confirm('Are you sure you want to delete your artist profile? This action cannot be undone.')) {
      supabase
        .from('artists')
        .delete()
        .eq('id', artistId)
        .then(({ error }) => {
          if (error) {
            message = `Error deleting profile: ${error.message}`;
          } else {
            message = 'Artist profile deleted successfully';
            artistExists = false;
            artistId = null;
            artistName = '';
            artistBio = '';
            avatarUrl = null;
            selectedMediums = [];
            
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
      loadArtistProfile();
    }
  });
</script>

<div class="artist-profile-settings">
  <div class="settings-header">
    <div class="breadcrumb">
      <a href="/settings" use:link>← Back to Settings</a>
    </div>
    <h1>{artistExists ? 'Update' : 'Create'} Artist Profile</h1>
    <p>Manage your public artist profile and apply for Peace Pieces</p>
  </div>

  <div class="settings-content">
    <div class="settings-card">
      {#if message}
        <div class="message" class:error={message.includes('Error') || message.includes('error')} transition:fade>
          {message}
        </div>
      {/if}
      
      <form on:submit|preventDefault={saveArtistProfile}>
        <div class="avatar-section">
          <div class="avatar-container" on:click={() => document.getElementById('avatar-input')?.click()}>
            {#if avatarUrl}
              <img src={avatarUrl} alt="Artist Avatar" class="avatar" />
            {:else}
              <div class="avatar-placeholder">
                {artistName ? artistName[0].toUpperCase() : $user?.email?.[0].toUpperCase() || 'A'}
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
            <p class="avatar-label">Artist Photo</p>
            <p class="avatar-description">This photo will be displayed on your public artist profile</p>
          </div>
        </div>

        <div class="form-group">
          <label for="artistName">Artist Name *</label>
          <input
            type="text"
            id="artistName"
            bind:value={artistName}
            required
            disabled={loading || uploading}
            placeholder="Your professional name as an artist"
          />
          <p class="field-description">This is how you'll be known in the artistic community</p>
        </div>
        
        <div class="form-group">
          <label for="artistBio">Artist Bio</label>
          <textarea
            id="artistBio"
            bind:value={artistBio}
            rows="5"
            disabled={loading || uploading}
            placeholder="Share your artistic journey, influences, and vision"
          ></textarea>
          <p class="field-description">A compelling bio helps others understand your artistic perspective</p>
        </div>
        
        <div class="form-group">
          <label>Artistic Mediums</label>
          <p class="field-description">Select all mediums that apply to your artistic practice</p>
          
          <div class="mediums-grid">
            {#each artisticMediums as medium}
              <label class="medium-option">
                <input 
                  type="checkbox" 
                  checked={selectedMediums.includes(medium)} 
                  on:change={() => toggleMedium(medium)}
                  disabled={loading || uploading}
                />
                <span>{medium}</span>
              </label>
            {/each}
          </div>
        </div>
        
        <div class="form-actions">
          <button type="submit" class="primary" disabled={loading || uploading || !artistName.trim()}>
            {#if loading || uploading}
              <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                  <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                </circle>
              </svg>
              {uploading ? 'Uploading...' : 'Saving...'}
            {:else}
              {artistExists ? 'Update' : 'Create'} Artist Profile
            {/if}
          </button>
          
          {#if artistExists}
            <button type="button" class="danger" on:click={deleteArtistProfile} disabled={loading || uploading}>
              Delete Artist Profile
            </button>
          {/if}
        </div>
      </form>
    </div>
    
    {#if artistExists}
      <div class="settings-card info-card">
        <h2>What's Next?</h2>
        <p>Now that you have an artist profile, you can:</p>
        <ul>
          <li>Apply to contribute to open Peace Pieces</li>
          <li>Collaborate with other artists on projects</li>
          <li>Receive notifications about opportunities that match your mediums</li>
        </ul>
        <a href="/explore" use:link class="explore-button">
          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          Explore Open Projects
        </a>
      </div>
    {/if}
  </div>
</div>

<style>
  .artist-profile-settings {
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
    color: var(--text-color);
  }

  .info-card ul {
    margin: var(--space-4) 0;
    padding-left: var(--space-6);
  }

  .info-card li {
    margin-bottom: var(--space-2);
    color: var(--text-color);
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

  .mediums-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: var(--space-2);
    margin-top: var(--space-3);
  }

  .medium-option {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: all 0.2s;
  }

  .medium-option:hover {
    background: var(--bg-color);
    border-color: var(--color-primary-300);
  }

  .medium-option input[type="checkbox"] {
    width: auto;
    margin: 0;
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

  .explore-button {
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

  .explore-button:hover {
    background-color: var(--color-primary-700);
  }

  @media (max-width: 768px) {
    .artist-profile-settings {
      padding: var(--space-4);
    }

    .settings-header h1 {
      font-size: 2rem;
    }

    .avatar-section {
      flex-direction: column;
      text-align: center;
    }

    .mediums-grid {
      grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    }

    .form-actions {
      flex-direction: column;
    }

    .danger {
      margin-left: 0;
    }
  }
</style>