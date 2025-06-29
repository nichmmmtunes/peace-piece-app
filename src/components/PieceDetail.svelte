<script lang="ts">
  import { onMount } from 'svelte';
  import { link, location } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import DonateButton from './DonateButton.svelte';
  import DonationModal from './DonationModal.svelte';
  
  export let params = { id: '' };
  
  let piece: any = null;
  let loading = true;
  let error: string | null = null;
  let isFollowing = false;
  let showDonationModal = false;
  let hasDonated = false;
  
  // Check for donation success/cancel in URL
  $: {
    const url = new URL(window.location.href);
    const hashParams = new URLSearchParams(url.hash.split('?')[1] || '');
    if (hashParams.get('donation') === 'success') {
      // Show success message or update UI
      hasDonated = true;
    }
  }
  
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
      
      // Check if user is following
      if ($user) {
        const { data: followData } = await supabase
          .from('piece_followers')
          .select('piece_id')
          .eq('piece_id', params.id)
          .eq('profile_id', $user.id)
          .maybeSingle();
          
        isFollowing = !!followData;
      }
      
      // Check if user has donated to this piece
      if ($user) {
        const { data: customerData } = await supabase
          .from('stripe_customers')
          .select('customer_id')
          .eq('user_id', $user.id)
          .maybeSingle();
          
        if (customerData?.customer_id) {
          const { data: orderData } = await supabase
            .from('stripe_orders')
            .select('id')
            .eq('customer_id', customerData.customer_id)
            .eq('piece_id', params.id)
            .eq('status', 'completed')
            .maybeSingle();
            
          hasDonated = !!orderData;
        }
      }
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
  
  async function toggleFollow() {
    if (!$user) return;
    
    try {
      if (isFollowing) {
        await supabase
          .from('piece_followers')
          .delete()
          .eq('piece_id', params.id)
          .eq('profile_id', $user.id);
      } else {
        await supabase
          .from('piece_followers')
          .insert({
            piece_id: params.id,
            profile_id: $user.id
          });
      }
      
      isFollowing = !isFollowing;
      if (piece) {
        piece.follower_count += isFollowing ? 1 : -1;
      }
    } catch (e: any) {
      console.error('Error toggling follow:', e);
    }
  }
  
  function openDonationModal() {
    showDonationModal = true;
  }
  
  function closeDonationModal() {
    showDonationModal = false;
  }
  
  onMount(() => {
    if (params.id) {
      loadPiece();
    }
  });
  
  $: if (params.id) {
    loadPiece();
  }
</script>

<div class="piece-detail">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading piece details...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Error Loading Piece</h2>
        <p>{error}</p>
        <a href="/explore" use:link class="primary">Explore Pieces</a>
      </div>
    </div>
  {:else if piece}
    <div class="piece-container">
      <!-- Header Section -->
      <div class="piece-header" in:fade>
        <div class="breadcrumb">
          <a href="/explore" use:link>← Back to Explore</a>
        </div>
        
        <div class="header-content">
          <h1>{piece.title}</h1>
          <p class="organizer">By {piece.organizer_name}</p>
          
          <div class="header-actions">
            {#if $user}
              <button 
                class="follow-button" 
                class:following={isFollowing}
                on:click={toggleFollow}
              >
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill={isFollowing ? "currentColor" : "none"}>
                  <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                </svg>
                {isFollowing ? 'Following' : 'Follow'}
              </button>
            {/if}
            
            <button class="donate-button" on:click={openDonationModal}>
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
              </svg>
              Donate
            </button>
            
            <a href="/view/{piece.id}" use:link class="view-button">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
              View
            </a>
          </div>
        </div>
      </div>
      
      <!-- Main Content -->
      <div class="piece-content" in:fly={{ y: 20, duration: 300 }}>
        <!-- Left Column: Media and Description -->
        <div class="piece-media-column">
          {#if piece.image_url}
            <div class="piece-image-container">
              <img src={piece.image_url} alt={piece.title} class="piece-image" />
            </div>
          {/if}
          
          {#if piece.audio_url}
            <div class="piece-audio">
              <h3>Audio Experience</h3>
              <audio controls src={piece.audio_url} class="audio-player"></audio>
            </div>
          {/if}
          
          {#if piece.video_url}
            <div class="piece-video">
              <h3>Video Experience</h3>
              <video controls src={piece.video_url} class="video-player"></video>
            </div>
          {/if}
          
          {#if piece.mission}
            <div class="piece-mission">
              <h3>Mission</h3>
              <div class="mission-content">
                {@html piece.mission}
              </div>
            </div>
          {/if}
          
          {#if piece.piece_description}
            <div class="piece-description">
              <h3>About This Piece</h3>
              <div class="description-content">
                {piece.piece_description}
              </div>
            </div>
          {/if}
        </div>
        
        <!-- Right Column: Info and Stats -->
        <div class="piece-info-column">
          <!-- Funding Progress -->
          {#if piece.funding_goal}
            <div class="funding-card">
              <div class="funding-header">
                <h3>Funding Progress</h3>
                <span class="funding-percent">{Math.min(100, Math.round((piece.amount_raised / piece.funding_goal) * 100))}%</span>
              </div>
              
              <div class="progress-container">
                <div 
                  class="progress-bar" 
                  style="width: {Math.min(100, Math.round((piece.amount_raised / piece.funding_goal) * 100))}%"
                ></div>
              </div>
              
              <div class="funding-stats">
                <div class="stat">
                  <span class="stat-value">${piece.amount_raised.toLocaleString()}</span>
                  <span class="stat-label">raised</span>
                </div>
                <div class="stat">
                  <span class="stat-value">${piece.funding_goal.toLocaleString()}</span>
                  <span class="stat-label">goal</span>
                </div>
              </div>
              
              <button class="donate-now-button" on:click={openDonationModal}>
                Donate Now
              </button>
              
              {#if hasDonated}
                <div class="donation-badge">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                  </svg>
                  You've supported this piece
                </div>
              {/if}
            </div>
          {/if}
          
          <!-- Project Status -->
          <div class="status-card">
            <h3>Project Status</h3>
            <div class="status-badge">
              {#if piece.project_status === 'open_to_applications'}
                <span class="status open-applications">Open to Applications</span>
              {:else if piece.project_status === 'seeking_funding'}
                <span class="status seeking-funding">Seeking Funding</span>
              {:else if piece.project_status === 'published'}
                <span class="status published">Published</span>
              {:else}
                <span class="status draft">Draft</span>
              {/if}
            </div>
            
            {#if piece.project_status === 'open_to_applications' && $user && piece.applicant_profile_id !== $user.id}
              <a href="/apply/{piece.id}" use:link class="apply-button">
                Apply as Artist
              </a>
            {/if}
          </div>
          
          <!-- Organizer Info -->
          <div class="organizer-card">
            <h3>Organizer</h3>
            <div class="organizer-info">
              <div class="organizer-avatar">
                {#if piece.organizer_avatar_url}
                  <img src={piece.organizer_avatar_url} alt={piece.organizer_name} />
                {:else}
                  <div class="avatar-placeholder">
                    {piece.organizer_name?.[0]?.toUpperCase() || 'O'}
                  </div>
                {/if}
              </div>
              <div class="organizer-details">
                <h4>{piece.organizer_name}</h4>
                {#if piece.organizer_description}
                  <p>{piece.organizer_description}</p>
                {/if}
              </div>
            </div>
          </div>
          
          <!-- Contributors -->
          {#if piece.contributors && piece.contributors.length > 0}
            <div class="contributors-card">
              <h3>Contributors</h3>
              <div class="contributors-list">
                {#each piece.contributors as contributor}
                  <div class="contributor-item">
                    <div class="contributor-avatar">
                      {#if contributor.avatar_url}
                        <img src={contributor.avatar_url} alt={contributor.name} />
                      {:else}
                        <div class="avatar-placeholder">
                          {contributor.name?.[0]?.toUpperCase() || 'C'}
                        </div>
                      {/if}
                    </div>
                    <div class="contributor-details">
                      <h4>{contributor.name}</h4>
                      <span class="contributor-role">{contributor.role}</span>
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          {/if}
          
          <!-- Sponsors -->
          {#if piece.sponsors && piece.sponsors.length > 0}
            <div class="sponsors-card">
              <h3>Sponsors</h3>
              <div class="sponsors-list">
                {#each piece.sponsors as sponsor}
                  <div class="sponsor-item">
                    <div class="sponsor-logo">
                      {#if sponsor.logo_url}
                        <img src={sponsor.logo_url} alt={sponsor.name} />
                      {:else}
                        <div class="logo-placeholder">
                          {sponsor.name?.[0]?.toUpperCase() || 'S'}
                        </div>
                      {/if}
                    </div>
                    <div class="sponsor-details">
                      <h4>{sponsor.name}</h4>
                      <span class="sponsor-amount">${sponsor.amount.toLocaleString()}</span>
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          {/if}
          
          <!-- Stats -->
          <div class="stats-card">
            <div class="stat-item">
              <span class="stat-value">{piece.follower_count || 0}</span>
              <span class="stat-label">Followers</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">{piece.contributors?.length || 0}</span>
              <span class="stat-label">Contributors</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">{piece.sponsors?.length || 0}</span>
              <span class="stat-label">Sponsors</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Donation Modal -->
    <DonationModal 
      pieceId={piece.id} 
      pieceName={piece.title} 
      bind:show={showDonationModal} 
      on:close={closeDonationModal} 
    />
  {/if}
</div>

<style>
  .piece-detail {
    padding: var(--space-6);
    max-width: 1200px;
    margin: 0 auto;
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
    max-width: 500px;
  }

  .error-card h2 {
    color: var(--color-error-600);
    margin-bottom: var(--space-4);
  }

  .piece-container {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
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

  .piece-header {
    margin-bottom: var(--space-6);
  }

  .header-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .piece-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0;
    color: var(--text-color);
  }

  .organizer {
    color: var(--text-muted);
    font-size: 1.125rem;
    margin: 0;
  }

  .header-actions {
    display: flex;
    gap: var(--space-3);
    margin-top: var(--space-4);
  }

  .follow-button,
  .donate-button,
  .view-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .follow-button {
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
  }

  .follow-button:hover {
    background-color: var(--color-neutral-100);
  }

  .follow-button.following {
    background-color: var(--color-success-600);
    color: white;
    border-color: var(--color-success-600);
  }

  .follow-button.following:hover {
    background-color: var(--color-success-700);
  }

  .donate-button {
    background-color: var(--color-primary-600);
    color: white;
    border: none;
  }

  .donate-button:hover {
    background-color: var(--color-primary-700);
  }

  .view-button {
    background-color: var(--color-neutral-800);
    color: white;
    border: none;
    text-decoration: none;
  }

  .view-button:hover {
    background-color: var(--color-neutral-900);
  }

  .piece-content {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: var(--space-6);
  }

  .piece-media-column {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .piece-image-container {
    width: 100%;
    border-radius: var(--radius-lg);
    overflow: hidden;
    box-shadow: 0 4px 12px var(--shadow-color);
  }

  .piece-image {
    width: 100%;
    height: auto;
    display: block;
  }

  .piece-audio,
  .piece-video,
  .piece-mission,
  .piece-description {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .piece-audio h3,
  .piece-video h3,
  .piece-mission h3,
  .piece-description h3 {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .audio-player,
  .video-player {
    width: 100%;
  }

  .mission-content,
  .description-content {
    color: var(--text-color);
    line-height: 1.6;
  }

  .mission-content :global(p),
  .description-content :global(p) {
    margin-bottom: var(--space-4);
  }

  .mission-content :global(p:last-child),
  .description-content :global(p:last-child) {
    margin-bottom: 0;
  }

  .piece-info-column {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .funding-card,
  .status-card,
  .organizer-card,
  .contributors-card,
  .sponsors-card,
  .stats-card {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .funding-card h3,
  .status-card h3,
  .organizer-card h3,
  .contributors-card h3,
  .sponsors-card h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .funding-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-3);
  }

  .funding-percent {
    font-weight: 500;
    color: var(--color-success-600);
  }

  .progress-container {
    height: 8px;
    background-color: var(--color-neutral-200);
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: var(--space-3);
  }

  .progress-bar {
    height: 100%;
    background-color: var(--color-success-600);
    border-radius: 4px;
  }

  .funding-stats {
    display: flex;
    justify-content: space-between;
    margin-bottom: var(--space-4);
  }

  .stat {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .stat-value {
    font-weight: 500;
    color: var(--text-color);
  }

  .stat-label {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .donate-now-button {
    width: 100%;
    padding: var(--space-3);
    background-color: var(--color-success-600);
    color: white;
    border: none;
    border-radius: var(--radius-md);
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .donate-now-button:hover {
    background-color: var(--color-success-700);
  }

  .donation-badge {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    margin-top: var(--space-3);
    padding: var(--space-2);
    background-color: var(--color-success-100);
    color: var(--color-success-700);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
  }

  .status-badge {
    margin-bottom: var(--space-4);
  }

  .status {
    display: inline-block;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
  }

  .status.open-applications {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .status.seeking-funding {
    background-color: var(--color-warning-100);
    color: var(--color-warning-700);
  }

  .status.published {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .status.draft {
    background-color: var(--color-neutral-100);
    color: var(--color-neutral-700);
  }

  .apply-button {
    display: inline-block;
    padding: var(--space-2) var(--space-4);
    background-color: var(--color-primary-600);
    color: white;
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    transition: background-color 0.2s;
  }

  .apply-button:hover {
    background-color: var(--color-primary-700);
  }

  .organizer-info,
  .contributor-item,
  .sponsor-item {
    display: flex;
    gap: var(--space-3);
    align-items: center;
  }

  .organizer-avatar,
  .contributor-avatar,
  .sponsor-logo {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
  }

  .organizer-avatar img,
  .contributor-avatar img,
  .sponsor-logo img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder,
  .logo-placeholder {
    width: 100%;
    height: 100%;
    background-color: var(--color-neutral-200);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 500;
    color: var(--color-neutral-600);
  }

  .organizer-details,
  .contributor-details,
  .sponsor-details {
    flex: 1;
  }

  .organizer-details h4,
  .contributor-details h4,
  .sponsor-details h4 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .organizer-details p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
    line-height: 1.4;
  }

  .contributor-role,
  .sponsor-amount {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .contributors-list,
  .sponsors-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .stats-card {
    display: flex;
    justify-content: space-around;
    text-align: center;
  }

  .stat-item {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  @media (max-width: 768px) {
    .piece-detail {
      padding: var(--space-4);
    }

    .piece-header h1 {
      font-size: 2rem;
    }

    .piece-content {
      grid-template-columns: 1fr;
    }

    .header-actions {
      flex-wrap: wrap;
    }

    .follow-button,
    .donate-button,
    .view-button {
      flex: 1;
      justify-content: center;
    }
  }
</style>