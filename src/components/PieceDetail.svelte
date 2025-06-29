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
  let donationSuccess = false;
  
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
      
      // Check if user is following this piece
      if ($user) {
        const { data: followData } = await supabase
          .from('piece_followers')
          .select('piece_id')
          .eq('piece_id', params.id)
          .eq('profile_id', $user.id)
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
      
      // Update follower count in the UI
      if (piece) {
        piece.follower_count = isFollowing 
          ? (piece.follower_count || 0) + 1 
          : Math.max(0, (piece.follower_count || 0) - 1);
      }
    } catch (e: any) {
      console.error('Error toggling follow:', e);
    }
  }
  
  function formatAmount(amount: number): string {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  }
  
  function openDonationModal() {
    showDonationModal = true;
  }
  
  function closeDonationModal() {
    showDonationModal = false;
  }
  
  function checkForDonationSuccess() {
    // Check if URL has donation=success parameter
    const url = new URL(window.location.href);
    const hashParams = new URLSearchParams(url.hash.split('#')[1]?.split('?')[1] || '');
    
    if (hashParams.get('donation') === 'success') {
      donationSuccess = true;
      
      // Remove the donation parameter from URL to prevent refreshing on page reload
      const newHash = url.hash.split('?')[0];
      window.history.replaceState(null, '', `${url.pathname}${url.search}${newHash}`);
      
      // Refresh piece data to get updated amount_raised
      loadPiece();
      
      // Clear success message after 5 seconds
      setTimeout(() => {
        donationSuccess = false;
      }, 5000);
    }
  }
  
  onMount(() => {
    if (params.id) {
      loadPiece();
      checkForDonationSuccess();
    }
  });
  
  // Watch for changes in the URL hash to detect donation success
  $: if ($location && $location.includes(params.id)) {
    checkForDonationSuccess();
  }
</script>

<div class="piece-detail">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading piece...</p>
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
    <!-- Donation Success Message -->
    {#if donationSuccess}
      <div class="donation-success" transition:fade>
        <div class="success-content">
          <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
          <span>Thank you for your donation! Your support makes a difference.</span>
        </div>
      </div>
    {/if}
    
    <div class="piece-container">
      <!-- Header Section -->
      <div class="piece-header" in:fade>
        <div class="header-content">
          <h1>{piece.title}</h1>
          <p class="organizer">Organized by {piece.organizer_name}</p>
          
          <div class="header-actions">
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
            
            <button class="donate-button" on:click={openDonationModal}>
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
              </svg>
              Donate
            </button>
          </div>
        </div>
      </div>
      
      <!-- Main Content -->
      <div class="piece-content">
        <!-- Left Column: Media and Description -->
        <div class="piece-media-section">
          {#if piece.image_url}
            <div class="piece-image-container" in:fly={{ y: 20, duration: 300 }}>
              <img src={piece.image_url} alt={piece.title} class="piece-image" />
              
              {#if piece.video_url}
                <a href="/view/{piece.id}" use:link class="view-button">
                  <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
                    <polygon points="5 3 19 12 5 21 5 3"></polygon>
                  </svg>
                  <span>View Full Experience</span>
                </a>
              {/if}
            </div>
          {/if}
          
          {#if piece.audio_url && !piece.video_url}
            <div class="audio-player" in:fly={{ y: 20, duration: 300, delay: 100 }}>
              <audio controls src={piece.audio_url} class="piece-audio"></audio>
            </div>
          {/if}
          
          {#if piece.mission}
            <div class="piece-mission" in:fly={{ y: 20, duration: 300, delay: 200 }}>
              <h2>Mission</h2>
              <div class="mission-content">
                {@html piece.mission}
              </div>
            </div>
          {/if}
          
          {#if piece.piece_description}
            <div class="piece-description" in:fly={{ y: 20, duration: 300, delay: 300 }}>
              <h2>About This Piece</h2>
              <div class="description-content">
                {piece.piece_description}
              </div>
            </div>
          {/if}
        </div>
        
        <!-- Right Column: Stats and Contributors -->
        <div class="piece-sidebar">
          <!-- Funding Stats -->
          <div class="funding-stats" in:fly={{ y: 20, duration: 300 }}>
            <div class="stat-item">
              <h3>{formatAmount(piece.amount_raised || 0)}</h3>
              <p>raised so far</p>
            </div>
            
            {#if piece.funding_goal}
              <div class="funding-progress">
                <div class="progress-bar">
                  <div 
                    class="progress-fill" 
                    style="width: {Math.min(100, ((piece.amount_raised || 0) / piece.funding_goal) * 100)}%"
                  ></div>
                </div>
                <div class="progress-labels">
                  <span class="progress-percent">
                    {Math.round(((piece.amount_raised || 0) / piece.funding_goal) * 100)}%
                  </span>
                  <span class="progress-goal">of {formatAmount(piece.funding_goal)}</span>
                </div>
              </div>
            {/if}
            
            <div class="stat-row">
              <div class="stat-item">
                <h3>{piece.follower_count || 0}</h3>
                <p>followers</p>
              </div>
              
              <div class="stat-item">
                <h3>{piece.contributors?.length || 0}</h3>
                <p>contributors</p>
              </div>
              
              <div class="stat-item">
                <h3>{piece.sponsors?.length || 0}</h3>
                <p>sponsors</p>
              </div>
            </div>
            
            <button class="donate-button-large" on:click={openDonationModal}>
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
              </svg>
              Donate to This Piece
            </button>
          </div>
          
          <!-- Contributors -->
          {#if piece.contributors && piece.contributors.length > 0}
            <div class="contributors-section" in:fly={{ y: 20, duration: 300, delay: 100 }}>
              <h2>Contributors</h2>
              <div class="contributors-list">
                {#each piece.contributors as contributor}
                  <div class="contributor-item">
                    <div class="contributor-avatar">
                      {#if contributor.avatar_url}
                        <img src={contributor.avatar_url} alt={contributor.name} />
                      {:else}
                        <div class="avatar-placeholder">
                          {contributor.name[0].toUpperCase()}
                        </div>
                      {/if}
                    </div>
                    <div class="contributor-info">
                      <h3>{contributor.name}</h3>
                      <p>{contributor.role}</p>
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          {/if}
          
          <!-- Sponsors -->
          {#if piece.sponsors && piece.sponsors.length > 0}
            <div class="sponsors-section" in:fly={{ y: 20, duration: 300, delay: 200 }}>
              <h2>Sponsors</h2>
              <div class="sponsors-list">
                {#each piece.sponsors as sponsor}
                  <div class="sponsor-item">
                    {#if sponsor.logo_url}
                      <img src={sponsor.logo_url} alt={sponsor.name} class="sponsor-logo" />
                    {:else}
                      <div class="sponsor-placeholder">
                        {sponsor.name[0].toUpperCase()}
                      </div>
                    {/if}
                    <div class="sponsor-info">
                      <h3>{sponsor.name}</h3>
                      <p>{formatAmount(sponsor.amount)}</p>
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          {/if}
          
          <!-- Project Status -->
          {#if piece.project_status}
            <div class="project-status-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
              <h2>Project Status</h2>
              <div class="status-badge {piece.project_status}">
                {#if piece.project_status === 'open_to_applications'}
                  Open to Applications
                {:else if piece.project_status === 'seeking_funding'}
                  Seeking Funding
                {:else if piece.project_status === 'published'}
                  Published
                {:else}
                  Under Review
                {/if}
              </div>
              
              {#if piece.project_status === 'open_to_applications' && $user}
                <a href="/apply/{piece.id}" use:link class="apply-button">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="8.5" cy="7" r="4"></circle>
                    <line x1="20" y1="8" x2="20" y2="14"></line>
                    <line x1="23" y1="11" x2="17" y2="11"></line>
                  </svg>
                  Apply as Artist
                </a>
              {/if}
            </div>
          {/if}
          
          <!-- Organizer Info -->
          <div class="organizer-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
            <h2>About the Organizer</h2>
            <div class="organizer-info">
              <div class="organizer-avatar">
                {#if piece.organizer_avatar_url}
                  <img src={piece.organizer_avatar_url} alt={piece.organizer_name} />
                {:else}
                  <div class="avatar-placeholder">
                    {piece.organizer_name[0].toUpperCase()}
                  </div>
                {/if}
              </div>
              <div class="organizer-details">
                <h3>{piece.organizer_name}</h3>
                {#if piece.organizer_description}
                  <p>{piece.organizer_description}</p>
                {/if}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Donation Modal -->
    <DonationModal 
      pieceId={piece.id}
      pieceName={piece.title}
      show={showDonationModal}
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

  .donation-success {
    margin-bottom: var(--space-6);
  }

  .success-content {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    padding: var(--space-4);
    background-color: var(--color-success-100);
    border: 1px solid var(--color-success-300);
    border-radius: var(--radius-lg);
    color: var(--color-success-700);
  }

  .success-content svg {
    color: var(--color-success-600);
    flex-shrink: 0;
  }

  .piece-container {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .piece-header {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  :global(.light-mode) .piece-header {
    background: var(--bg-color);
  }

  .header-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
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
    margin-top: var(--space-2);
  }

  .follow-button,
  .donate-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: 50px;
    font-weight: 500;
    transition: all 0.2s;
  }

  .follow-button {
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
  }

  :global(.light-mode) .follow-button {
    background: var(--card-bg);
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

  .piece-content {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: var(--space-6);
  }

  .piece-media-section {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .piece-image-container {
    position: relative;
    border-radius: var(--radius-lg);
    overflow: hidden;
    background: var(--card-bg);
  }

  :global(.light-mode) .piece-image-container {
    background: var(--bg-color);
  }

  .piece-image {
    width: 100%;
    height: auto;
    display: block;
    border-radius: var(--radius-lg);
  }

  .view-button {
    position: absolute;
    bottom: var(--space-4);
    right: var(--space-4);
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    background-color: rgba(0, 0, 0, 0.7);
    color: white;
    border-radius: 50px;
    text-decoration: none;
    font-weight: 500;
    transition: all 0.2s;
    backdrop-filter: blur(4px);
  }

  .view-button:hover {
    background-color: rgba(0, 0, 0, 0.9);
  }

  .audio-player {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-4);
  }

  :global(.light-mode) .audio-player {
    background: var(--bg-color);
  }

  .piece-audio {
    width: 100%;
  }

  .piece-mission,
  .piece-description {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  :global(.light-mode) .piece-mission,
  :global(.light-mode) .piece-description {
    background: var(--bg-color);
  }

  .piece-mission h2,
  .piece-description h2 {
    font-size: 1.5rem;
    font-weight: 500;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
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

  .mission-content :global(ul),
  .mission-content :global(ol),
  .description-content :global(ul),
  .description-content :global(ol) {
    margin: var(--space-4) 0;
    padding-left: var(--space-6);
  }

  .mission-content :global(li),
  .description-content :global(li) {
    margin-bottom: var(--space-2);
  }

  .mission-content :global(a),
  .description-content :global(a) {
    color: var(--color-primary-600);
    text-decoration: none;
  }

  .mission-content :global(a:hover),
  .description-content :global(a:hover) {
    text-decoration: underline;
  }

  .piece-sidebar {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .funding-stats,
  .contributors-section,
  .sponsors-section,
  .project-status-section,
  .organizer-section {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  :global(.light-mode) .funding-stats,
  :global(.light-mode) .contributors-section,
  :global(.light-mode) .sponsors-section,
  :global(.light-mode) .project-status-section,
  :global(.light-mode) .organizer-section {
    background: var(--bg-color);
  }

  .funding-stats {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .stat-item {
    text-align: center;
  }

  .stat-item h3 {
    font-size: 1.5rem;
    font-weight: 700;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .stat-item p {
    color: var(--text-muted);
    margin: 0;
    font-size: 0.875rem;
  }

  .funding-progress {
    margin: var(--space-4) 0;
  }

  .progress-bar {
    height: 8px;
    background-color: var(--color-neutral-200);
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: var(--space-2);
  }

  .progress-fill {
    height: 100%;
    background-color: var(--color-success-600);
    border-radius: 4px;
  }

  .progress-labels {
    display: flex;
    justify-content: space-between;
    font-size: 0.875rem;
  }

  .progress-percent {
    font-weight: 500;
    color: var(--color-success-600);
  }

  .progress-goal {
    color: var(--text-muted);
  }

  .stat-row {
    display: flex;
    justify-content: space-between;
  }

  .donate-button-large {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3) var(--space-4);
    background-color: var(--color-primary-600);
    color: white;
    border: none;
    border-radius: 50px;
    font-weight: 500;
    margin-top: var(--space-2);
    transition: all 0.2s;
  }

  .donate-button-large:hover {
    background-color: var(--color-primary-700);
    transform: translateY(-1px);
  }

  .contributors-section h2,
  .sponsors-section h2,
  .project-status-section h2,
  .organizer-section h2 {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .contributors-list,
  .sponsors-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .contributor-item,
  .sponsor-item {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .contributor-avatar,
  .organizer-avatar {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
  }

  .contributor-avatar img,
  .organizer-avatar img {
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
    font-weight: 500;
    color: var(--color-neutral-600);
  }

  .contributor-info,
  .sponsor-info,
  .organizer-details {
    flex: 1;
  }

  .contributor-info h3,
  .sponsor-info h3,
  .organizer-details h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .contributor-info p,
  .sponsor-info p,
  .organizer-details p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
    line-height: 1.4;
  }

  .sponsor-logo {
    width: 48px;
    height: 48px;
    object-fit: contain;
    border-radius: var(--radius-sm);
  }

  .sponsor-placeholder {
    width: 48px;
    height: 48px;
    background-color: var(--color-neutral-200);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 500;
    color: var(--color-neutral-600);
    border-radius: var(--radius-sm);
  }

  .status-badge {
    display: inline-block;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
    margin-bottom: var(--space-4);
  }

  .status-badge.open_to_applications {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .status-badge.seeking_funding {
    background-color: var(--color-warning-100);
    color: var(--color-warning-700);
  }

  .status-badge.published {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .apply-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3) var(--space-4);
    background-color: var(--color-primary-600);
    color: white;
    border: none;
    border-radius: 50px;
    font-weight: 500;
    text-decoration: none;
    transition: all 0.2s;
  }

  .apply-button:hover {
    background-color: var(--color-primary-700);
  }

  .organizer-info {
    display: flex;
    gap: var(--space-3);
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

    .stat-row {
      flex-wrap: wrap;
      gap: var(--space-4);
    }

    .stat-row .stat-item {
      flex: 1;
      min-width: 80px;
    }
  }
</style>