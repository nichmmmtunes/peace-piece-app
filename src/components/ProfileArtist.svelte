<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  
  export let params = { username: '' };
  
  let profile: any = null;
  let artistProfile: any = null;
  let loading = true;
  let error: string | null = null;
  let isOwnProfile = false;

  async function loadProfile() {
    try {
      loading = true;
      error = null;

      // Load profile by username
      const { data: profileData, error: profileError } = await supabase
        .from('artists')
        .select('*')
        .eq('artist_username', params.username)
        .single();

      if (profileError) throw profileError;
      
      profile = profileData;
      isOwnProfile = $user?.id === profile.user_id;

      

    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

    if (diffInHours < 24) {
      const hours = Math.floor(diffInHours);
      return hours <= 1 ? 'Just now' : `${hours} hours ago`;
    } else {
      const diffInDays = Math.floor(diffInHours / 24);
      if (diffInDays < 30) {
        return `${diffInDays} day${diffInDays > 1 ? 's' : ''} ago`;
      } else {
        return date.toLocaleDateString('en-US', { 
          month: 'short', 
          day: 'numeric',
          year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
        });
      }
    }
  }

  onMount(() => {
    if (params.username) {
      loadProfile();
    }
  });

  $: if (params.username) {
    loadProfile();
  }
</script>

<div class="profile-container">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading profile...</p>
    </div>
    {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Profile Not Found</h2>
        <p>{error}</p>
        <a href="/explore" use:link class="primary">Explore Profiles</a>
      </div>
    </div>
    {:else if profile}
    <div class="profile-content">
      <!-- Profile Header -->
      <header class="profile-header" in:fly={{ y: 20, duration: 300 }}>
        <div class="profile-info">
          <div class="profile-avatar">
            {#if profile.avatar_url}
              <img src={profile.avatar_url} alt={profile.username} class="avatar-image" />
            {:else}
              <div class="avatar-placeholder">
                {profile.username?.[0]?.toUpperCase() || '?'}
              </div>
            {/if}
          </div>

          <div class="profile-details">
            <h1 class="profile-name">{profile.username || 'Anonymous User'}</h1>
            <div class="profile-meta">
              <span class="location">Location</span>
              {#if profile.website}
                <a href={profile.website} target="_blank" rel="noopener noreferrer" class="website-link">
                  Website
                </a>
              {/if}
            </div>
          </div>
        </div>

        {#if isOwnProfile}
          <div class="profile-actions">
            <a href="/settings/artist-profile" use:link class="edit-profile-btn">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
              Edit Profile
            </a>
          </div>
        {/if}
      </header>

      <!-- Bio Section -->
      {#if profile.bio}
        <section class="bio-section" in:fly={{ y: 20, duration: 300, delay: 100 }}>
          {#if profile.bio}
            <div class="bio-block">
              <h3>About</h3>
              <p class="bio-text">{profile.bio}</p>
            </div>
          {/if}
        </section>
      {/if}

      <!-- Profile Stats -->
      <section class="profile-stats" in:fly={{ y: 20, duration: 300, delay: 200 }}>
        <div class="stats-grid">
          {#if artistProfile && artistProfile.artistic_mediums && artistProfile.artistic_mediums.length > 0}
            <div class="stat-item">
              <h3>Artistic Mediums</h3>
              <div class="stat-tags">
                {#each artistProfile.artistic_mediums as medium}
                  <span class="tag medium">{medium}</span>
                {/each}
              </div>
            </div>
          {/if}
          
          <div class="stat-item">
            <h3>Role</h3>
            <div class="stat-tags">
              <span class="tag artist">Artist</span>
              <span class="tag supporter">Supporter</span>
            </div>
          </div>

          <div class="stat-item">
            <h3>Causes</h3>
            <div class="stat-tags">
              <span class="tag cause">Poverty</span>
              <span class="tag cause">Mental Health</span>
            </div>
          </div>

          <div class="stat-item">
            <h3>Skills</h3>
            <div class="stat-tags">
              <span class="tag skill">Painting</span>
              <span class="tag skill">Drawing</span>
              <span class="tag skill">Writing</span>
            </div>
          </div>
        </div>
      </section>

    </div>
  {/if}
</div>

<style>
  .profile-container {
    padding: var(--space-8) var(--space-6) var(--space-6);
    max-width: 1000px;
    margin: 0 auto 0 0;
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

  .error-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
  }

  .error-card {
    background: var(--card-bg);
    border: 1px solid var(--color-error-200);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    max-width: 400px;
  }

  .error-card h2 {
    color: var(--color-error-600);
    margin-bottom: var(--space-4);
  }

  .profile-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-8);
  }

  .profile-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: var(--space-6);
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  :global(.light-mode) .profile-header {
    background: var(--bg-color);
  }

  .profile-info {
    display: flex;
    gap: var(--space-4);
    flex: 1;
  }

  .profile-avatar {
    width: 80px;
    height: 97px;
    border-radius: 100px;
    overflow: hidden;
    flex-shrink: 0;
  }

  .avatar-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder {
    width: 100%;
    height: 100%;
    background-color: var(--color-neutral-200);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    color: var(--color-neutral-600);
    font-size: 2rem;
  }

  .profile-details {
    flex: 1;
  }

  .profile-name {
    font-size: 2rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .profile-meta {
    display: flex;
    gap: var(--space-4);
    color: var(--text-muted);
    font-size: 0.875rem;
    align-items: center;
    flex-wrap: wrap;
  }

  .website-link {
    color: var(--text-color);
    text-decoration: none;
  }

  .website-link:hover {
    text-decoration: underline;
  }
  
  .artist-badge {
    display: inline-flex;
    align-items: center;
    padding: var(--space-1) var(--space-2);
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
    border-radius: var(--radius-md);
    font-weight: 500;
    font-size: 0.75rem;
  }

  .profile-actions {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
    flex-shrink: 0;
  }

  .edit-profile-btn,
  .edit-artist-btn,
  .create-artist-btn,
  .follow-btn,
  .add-to-list-btn,
  .invite-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    font-weight: 500;
    text-decoration: none;
    transition: all 0.2s;
    white-space: nowrap;
  }

  .edit-profile-btn,
  .edit-profile-btn:hover {
    background: var(--bg-color);
    color: var(--text-color);
    border: none;
  }

  :global(.light-mode) .edit-profile-btn,
  :global(.light-mode) .edit-profile-btn:hover {
    background: var(--card-bg);
  } 
  
  .edit-artist-btn,
  .edit-artist-btn:hover {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
    border: none;
  }
  
  .create-artist-btn,
  .create-artist-btn:hover {
    background-color: var(--color-accent-600);
    color: white;
    border: none;
  }

  .follow-btn {
    background-color: var(--color-primary-600);
    color: white;
    border: none;
    cursor: pointer;
  }

  .follow-btn:hover {
    background-color: var(--color-primary-700);
  }

  .follow-btn.following {
    background-color: var(--color-success-600);
  }

  .follow-btn.following:hover {
    background-color: var(--color-success-700);
  }

  .add-to-list-btn,
  .invite-btn {
    background: var(--card-bg);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    cursor: pointer;
  }

  .add-to-list-btn:hover,
  .invite-btn:hover {
    background-color: var(--color-neutral-100);
  }

  .bio-section {
    background: transparent;
    border: none;
    border-radius: var(--radius-lg);
    padding: 0px;
  }
  
  .bio-block {
    margin-bottom: var(--space-4);
  }

  .bio-block h2 {
    font-size: 1.7rem;
    font-family: var(--font-instrument-serif);
  }
  
  .bio-block:last-child {
    margin-bottom: 0;
  }
  
  .bio-block h3 {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .bio-text {
    color: var(--text-color);
    line-height: 1.6;
    margin: 0;
  }

  .profile-stats {
    background: transparent;
    border-radius: var(--radius-lg);
    padding: var(--space-6) 0 0;
    border-top: solid 1px var(--border-color);
  }

  .stats-grid {
    display: grid;
    gap: var(--space-6);
    grid-template-columns: repeat(2, 1fr);
  }

  .stat-item {
    width: fit-content;
  }

  .stat-item h3 {
    font-size: 1rem;
    font-weight: 600;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .stat-tags {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }

  .tag {
    font-size: 0.75rem;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-sm);
    font-weight: 500;
    user-select: none;
  }

  .tag.artist {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .tag.supporter {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
  }

  .tag.cause {
    background-color: var(--color-warning-100);
    color: var(--color-warning-700);
  }

  .tag.medium {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .tag.skill {
    background-color: var(--color-neutral-100);
    color: var(--color-neutral-700);
  }

  :global(.light-mode) .tag.skill {
    background: var(--bg-color)
  }

  .tag.social-cause {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .tag.artistic-medium {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
  }

  .portfolio-section,
  .contributions-section,
  .history-section {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  :global(.light-mode) .portfolio-section,
  :global(.light-mode) .contributions-section,
  :global(.light-mode) .history-section {
    background: var(--bg-color);
  }

  .portfolio-section h2,
  .contributions-section h2,
  .history-section h2 {
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
    font-size: 1.7rem;
    font-family: var(--font-instrument-serif);
  }

  .portfolio-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: var(--space-4);
  }

  .portfolio-item {
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
  }

  .portfolio-item:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px var(--shadow-color);
  }

  .portfolio-link {
    display: block;
    text-decoration: none;
    color: inherit;
  }

  .portfolio-image {
    position: relative;
    width: 100%;
    height: 160px;
    overflow: hidden;
  }

  .portfolio-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s;
  }

  .portfolio-item:hover .portfolio-image img {
    transform: scale(1.05);
  }

  .portfolio-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    opacity: 0;
    transition: opacity 0.3s;
  }

  .portfolio-item:hover .portfolio-overlay {
    opacity: 1;
  }

  .view-text {
    color: white;
    font-weight: 500;
  }

  .portfolio-placeholder {
    width: 100%;
    height: 160px;
    background-color: var(--color-neutral-100);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .portfolio-info {
    padding: var(--space-4);
  }

  .portfolio-title {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-2) 0;
    line-height: 1.3;
  }

  .portfolio-tags {
    display: flex;
    gap: var(--space-2);
    flex-wrap: wrap;
  }

  .contributions-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: var(--space-4);
  }

  .contribution-item {
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
    height: 320px;
  }

  .contribution-item:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px var(--shadow-color);
  }

  .contribution-link {
    display: block;
    text-decoration: none;
    color: inherit;
    height: 100%;
    display: flex;
    flex-direction: column;
  }

  .contribution-image {
    width: 100%;
    height: 60%;
    overflow: hidden;
  }

  .contribution-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .contribution-placeholder {
    width: 100%;
    height: 60%;
    background-color: var(--color-neutral-100);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .contribution-info {
    padding: var(--space-4);
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  .contribution-status {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: var(--space-2);
  }

  .contribution-title {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-2) 0;
    line-height: 1.3;
  }

  .contribution-organizer,
  .contribution-sponsor {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-1) 0;
  }

  .contribution-tags {
    display: flex;
    gap: var(--space-2);
    margin-top: auto;
    flex-wrap: wrap;
  }

  .empty-portfolio,
  .empty-contributions {
    text-align: center;
    padding: var(--space-8);
    color: var(--text-muted);
  }

  .activity-timeline {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .activity-item {
    display: flex;
    gap: var(--space-4);
    padding: var(--space-4);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    border: none;
  }

  :global(.light-mode) .activity-item {
    background: var(--card-bg);
  }

  .activity-date {
    display: flex;
    flex-direction: column;
    align-items: center;
    min-width: 60px;
    text-align: center;
  }

  .date-month {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .date-day {
    font-size: 1.125rem;
    font-weight: 600;
    color: var(--text-color);
  }

  .activity-content {
    display: flex;
    gap: var(--space-3);
    flex: 1;
  }

  .activity-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    background-color: var(--color-primary-100);
    color: var(--color-primary-600);
    border-radius: 50%;
    flex-shrink: 0;
  }

  .activity-details {
    flex: 1;
  }

  .activity-title {
    font-size: 1rem;
    font-weight: 600;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .activity-description {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
    line-height: 1.4;
  }

  @media (max-width: 768px) {
    .profile-container {
      padding: var(--space-4);
    }

    .profile-header {
      flex-direction: column;
      align-items: stretch;
    }

    .profile-actions {
      flex-direction: row;
      justify-content: stretch;
    }

    .profile-actions > * {
      flex: 1;
    }

    .stats-grid {
      grid-template-columns: 1fr;
    }

    .portfolio-grid,
    .contributions-grid {
      grid-template-columns: 1fr;
    }

    .activity-item {
      flex-direction: column;
      text-align: center;
    }

    .activity-content {
      justify-content: center;
    }
  }
</style>