<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  
  export let params = { username: '' };
  
  let profile: any = null;
  let artistProfile: any = null;
  let organizerProfile: any = null;
  let pieces: any[] = [];
  let contributions: any[] = [];
  let activities: any[] = [];
  let loading = true;
  let error: string | null = null;
  let isOwnProfile = false;
  let isFollowing = false;
  let followersCount = 0;

  async function loadProfile() {
    try {
      loading = true;
      error = null;

      // Load profile by username
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('*, followers_count')
        .eq('username', params.username)
        .single();

      if (profileError) throw profileError;
      
      profile = profileData;
      isOwnProfile = $user?.id === profile.id;
      followersCount = profile.followers_count || 0;

      // Check if user has an artist profile
      const { data: artistData, error: artistError } = await supabase
        .from('artists')
        .select('*')
        .eq('user_id', profile.id)
        .maybeSingle();
        
      if (!artistError && artistData) {
        artistProfile = artistData;
      }

      // Check if user has an organizer profile
      const { data: organizerData, error: organizerError } = await supabase
        .from('organizers')
        .select('*')
        .eq('user_id', profile.id)
        .maybeSingle();

      if (!organizerError && organizerData) {
        organizerProfile = organizerData;
      }

      // Load user's pieces (portfolio)
      const { data: piecesData } = await supabase
        .from('piece_details')
        .select('*')
        .eq('organizer_id', profile.id)
        .order('created_at', { ascending: false })
        .limit(6);

      pieces = piecesData || [];

      // Load contributions (pieces where user is a contributor)
      if (artistProfile) {
        const { data: contributionsData } = await supabase
          .from('piece_details')
          .select(`
            *,
            piece_artists!inner(role)
          `)
          .eq('piece_artists.artist_id', artistProfile.id)
          .order('created_at', { ascending: false })
          .limit(6);

        contributions = contributionsData || [];
      }

      // Load activity history (simplified for now)
      activities = [
        {
          id: 1,
          type: 'joined',
          title: 'Joined Peace Piece',
          description: 'Welcome to our community of artists and supporters',
          date: profile.created_at,
          icon: 'user-plus'
        },
        // Add more activities based on user actions
      ];

      // Check if current user is following this profile
      if ($user && !isOwnProfile) {
        const { data: followData } = await supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', $user.id)
          .eq('following_id', profile.id)
          .maybeSingle();

        isFollowing = !!followData;
      }

    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  async function toggleFollow() {
    if (!$user || isOwnProfile) return;

    try {
      if (isFollowing) {
        await supabase
          .from('user_follows')
          .delete()
          .eq('follower_id', $user.id)
          .eq('following_id', profile.id);
      } else {
        await supabase
          .from('user_follows')
          .insert({
            follower_id: $user.id,
            following_id: profile.id
          });
      }

      isFollowing = !isFollowing;
      followersCount += isFollowing ? 1 : -1;
    } catch (e: any) {
      console.error('Error toggling follow:', e);
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

  function getActivityIcon(type: string): string {
    const icons = {
      'joined': `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
        <circle cx="8.5" cy="7" r="4"></circle>
        <line x1="20" y1="8" x2="20" y2="14"></line>
        <line x1="23" y1="11" x2="17" y2="11"></line>
      </svg>`,
      'created': `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"></path>
      </svg>`,
      'collaborated': `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
        <circle cx="9" cy="7" r="4"></circle>
        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
      </svg>`
    };
    return icons[type] || icons['joined'];
  }

  // Function to get initials from a name
  function getInitials(fullName: string | null): string {
    if (!fullName) return "?";
    
    const nameParts = fullName.split(" ");
    if (nameParts.length > 1) {
      // Get first letter of first and last name
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
    } else {
      // If only one name, get first letter
      return fullName[0].toUpperCase();
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
              <div class="avatar-placeholder-initials">
                {getInitials(profile.username)}
              </div>
            {/if}
          </div>

          <div class="profile-details">
            <h1 class="profile-name">{profile.username || 'Anonymous User'}</h1>
            <div class="profile-meta">
              {#if profile.location}
                <span class="location">{profile.location}</span>
              {/if}
              {#if profile.website}
                <a href={profile.website} target="_blank" rel="noopener noreferrer" class="website-link">
                  Website
                </a>
              {/if}
              <span class="followers-count">{followersCount} {followersCount === 1 ? 'follower' : 'followers'}</span>
            </div>
            {#if profile.bio}
              <p class="profile-bio">{profile.bio}</p>
            {/if}
          </div>
        </div>

        <div class="profile-actions">
          {#if isOwnProfile}
            <a href="/settings" use:link class="edit-profile-btn">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
              Edit Profile
            </a>
            
            {#if artistProfile}
              <a href="/artist/{artistProfile.artist_username}" use:link class="view-artist-btn">
                View Artist Profile
              </a>
            {:else}
              <a href="/settings/artist-profile" use:link class="create-artist-btn">
                Create Artist Profile
              </a>
            {/if}
            {#if organizerProfile}
              <a href="/organizer/{organizerProfile.organizer_username}" use:link class="view-organizer-btn">
                View Organizer Profile
              </a>
            {:else}
              <a href="/settings/organizer-profile" use:link class="create-organizer-btn">
                Create Organizer Profile
              </a>
            {/if}
          {:else if $user}
            <button class="follow-btn" class:following={isFollowing} on:click={toggleFollow}>
              {isFollowing ? 'Following' : 'Follow'}
            </button>
            <button class="invite-btn">Invite to Project</button>
          {/if}
        </div>
      </header>

      <!-- Portfolio Section -->
      <section class="portfolio-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
        <h2>Portfolio</h2>
        {#if pieces.length > 0}
          <div class="portfolio-grid">
            {#each pieces as piece (piece.id)}
              <div class="portfolio-item">
                <a href="/piece/{piece.id}" use:link class="portfolio-link">
                  {#if piece.image_url}
                    <div class="portfolio-image">
                      <img src={piece.image_url} alt={piece.title} />
                      <div class="portfolio-overlay">
                        <span class="view-text">View Project</span>
                      </div>
                    </div>
                  {:else}
                    <div class="portfolio-placeholder">
                      <svg viewBox="0 0 24 24" width="32" height="32" stroke="currentColor" stroke-width="1" fill="none">
                        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                        <circle cx="8.5" cy="8.5" r="1.5"></circle>
                        <polyline points="21,15 16,10 5,21"></polyline>
                      </svg>
                    </div>
                  {/if}
                  <div class="portfolio-info">
                    <h3 class="portfolio-title">{piece.title}</h3>
                    <div class="portfolio-tags">
                      <span class="tag social-cause">Social Cause</span>
                      <span class="tag artistic-medium">Artistic Medium</span>
                    </div>
                  </div>
                </a>
              </div>
            {/each}
          </div>
        {:else}
          <div class="empty-portfolio">
            <p>No portfolio pieces yet</p>
          </div>
        {/if}
      </section>

      <!-- Contributions Section -->
      <section class="contributions-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
        <h2>Contributions</h2>
        {#if contributions.length > 0}
          <div class="contributions-grid">
            {#each contributions as contribution (contribution.id)}
              <div class="contribution-item">
                <a href="/piece/{contribution.id}" use:link class="contribution-link">
                  {#if contribution.image_url}
                    <div class="contribution-image">
                      <img src={contribution.image_url} alt={contribution.title} />
                    </div>
                  {:else}
                    <div class="contribution-placeholder">
                      <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="1" fill="none">
                        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                        <circle cx="8.5" cy="8.5" r="1.5"></circle>
                        <polyline points="21,15 16,10 5,21"></polyline>
                      </svg>
                    </div>
                  {/if}
                  <div class="contribution-info">
                    <div class="contribution-status">Project Status</div>
                    <h3 class="contribution-title">{contribution.title}</h3>
                    <p class="contribution-organizer">Organized by {contribution.organizer_name}</p>
                    <p class="contribution-sponsor">Sponsored by Community</p>
                    <div class="contribution-tags">
                      <span class="tag social-cause">Social Cause</span>
                      <span class="tag artistic-medium">Artistic Medium</span>
                    </div>
                  </div>
                </a>
              </div>
            {/each}
          </div>
        {:else}
          <div class="empty-contributions">
            <p>No contributions yet</p>
          </div>
        {/if}
      </section>

      <!-- Activity History -->
      <section class="history-section" in:fly={{ y: 20, duration: 300, delay: 500 }}>
        <h2>History</h2>
        <div class="activity-timeline">
          {#each activities as activity (activity.id)}
            <div class="activity-item">
              <div class="activity-date">
                <div class="date-month">{formatDate(activity.date).split(' ')[0]}</div>
                <div class="date-day">{formatDate(activity.date).split(' ')[1]}</div>
              </div>
              <div class="activity-content">
                <div class="activity-icon">
                  {@html getActivityIcon(activity.type)}
                </div>
                <div class="activity-details">
                  <h4 class="activity-title">{activity.title}</h4>
                  <p class="activity-description">{activity.description}</p>
                </div>
              </div>
            </div>
          {/each}
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

  .avatar-placeholder-initials {
    width: 100%;
    height: 100%;
    background-color: var(--color-neutral-400);
    color: var(--color-neutral-800);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2rem;
    font-weight: 600;
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
    margin-bottom: var(--space-2);
  }

  .website-link {
    color: var(--text-color);
    text-decoration: none;
  }

  .website-link:hover {
    text-decoration: underline;
  }
  
  .profile-bio {
    color: var(--text-color);
    margin: var(--space-2) 0 0;
    line-height: 1.5;
    font-size: 0.95rem;
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
  .view-artist-btn,
  .create-artist-btn,
  .view-organizer-btn,
  .create-organizer-btn,
  .follow-btn,
  .add-to-list-btn,
  .invite-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: 50px;
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
  
  .view-artist-btn,
  .view-artist-btn:hover {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
    border: none;
  }
  
  .view-organizer-btn,
  .view-organizer-btn:hover {
    background-color: var(--color-warning-100);
    color: var(--color-warning-700);
    border: none;
  }
  
  .create-artist-btn,
  .create-artist-btn:hover {
    background-color: var(--color-accent-600);
    color: white;
    border: none;
  }

  .create-organizer-btn,
  .create-organizer-btn:hover {
    background-color: var(--color-warning-600);
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
    font-weight: 500;
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
    border: none;
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
    background: var(--bg-color);
  }

  :global(.light-mode) .contribution-info {
    background: var(--card-bg);
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
    font-weight: 500;
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
    font-weight: 500;
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
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .activity-description {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
    line-height: 1.4;
  }

  .tag {
    font-size: 0.75rem;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-sm);
    font-weight: 500;
    user-select: none;
  }

  .tag.social-cause {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .tag.artistic-medium {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
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