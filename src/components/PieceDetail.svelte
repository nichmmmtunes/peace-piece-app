<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
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
  let followersCount = 0;
  let showDonationModal = false;
  
  // Check for donation success or cancel in URL
  let donationStatus: string | null = null;
  
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
      followersCount = piece.follower_count || 0;
      
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
      followersCount += isFollowing ? 1 : -1;
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
  
  function getProgressPercentage(): number {
    if (!piece || !piece.funding_goal || piece.funding_goal <= 0) return 0;
    const percentage = (piece.amount_raised / piece.funding_goal) * 100;
    return Math.min(percentage, 100);
  }
  
  function openDonationModal() {
    showDonationModal = true;
  }
  
  function closeDonationModal() {
    showDonationModal = false;
  }
  
  function checkDonationStatus() {
    const urlParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
    donationStatus = urlParams.get('donation');
    
    // Clean up URL after checking
    if (donationStatus) {
      const cleanUrl = window.location.href.split('?')[0];
      window.history.replaceState({}, document.title, cleanUrl);
    }
  }
  
  onMount(() => {
    if (params.id) {
      loadPiece();
      checkDonationStatus();
    }
  });
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
    <!-- Donation Status Messages -->
    {#if donationStatus === 'success'}
      <div class="donation-status success" transition:fade>
        <div class="status-icon">✓</div>
        <div class="status-message">
          <h3>Thank You for Your Donation!</h3>
          <p>Your support helps bring this piece to life and makes a real difference.</p>
        </div>
      </div>
    {:else if donationStatus === 'canceled'}
      <div class="donation-status canceled" transition:fade>
        <div class="status-icon">ℹ</div>
        <div class="status-message">
          <h3>Donation Canceled</h3>
          <p>Your donation was not completed. You can try again whenever you're ready.</p>
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
            {#if $user}
              <button 
                class="follow-btn" 
                class:following={isFollowing} 
                on:click={toggleFollow}
                title={isFollowing ? 'Unfollow' : 'Follow'}
              >
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill={isFollowing ? "currentColor" : "none"}>
                  <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                </svg>
                {isFollowing ? 'Following' : 'Follow'}
              </button>
              
              <button 
                class="donate-btn primary" 
                on:click={openDonationModal}
              >
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
                </svg>
                Donate
              </button>
            {:else}
              <a href="/auth" use:link class="auth-link">
                Sign in to follow or donate
              </a>
            {/if}
          </div>
        </div>
      </div>
      
      <!-- Main Content -->
      <div class="piece-content">
        <!-- Left Column: Media and Description -->
        <div class="piece-main" in:fly={{ x: -20, duration: 300 }}>
          <!-- Media Section -->
          <div class="media-section">
            {#if piece.video_url}
              <div class="video-container">
                <video 
                  src={piece.video_url} 
                  controls 
                  poster={piece.image_url}
                  class="piece-video"
                ></video>
              </div>
            {:else if piece.image_url}
              <div class="image-container">
                <img 
                  src={piece.image_url} 
                  alt={piece.title} 
                  class="piece-image"
                />
                {#if piece.audio_url}
                  <div class="audio-container">
                    <audio controls src={piece.audio_url} class="piece-audio"></audio>
                  </div>
                {/if}
              </div>
            {/if}
          </div>
          
          <!-- Description Section -->
          <div class="description-section">
            {#if piece.mission}
              <div class="mission-content">
                {@html piece.mission}
              </div>
            {/if}
            
            {#if piece.piece_description}
              <div class="description-content">
                <h2>About this Peace Piece</h2>
                <div class="markdown-content">
                  {piece.piece_description}
                </div>
              </div>
            {/if}
            
            {#if piece.full_project_overview}
              <div class="overview-content">
                <h2>Project Overview</h2>
                <p>{piece.full_project_overview}</p>
              </div>
            {/if}
          </div>
        </div>
        
        <!-- Right Column: Sidebar -->
        <div class="piece-sidebar" in:fly={{ x: 20, duration: 300 }}>
          <!-- Funding Progress -->
          {#if piece.funding_goal && piece.funding_goal > 0}
            <div class="funding-card">
              <h3>Funding Progress</h3>
              <div class="funding-amount">
                <span class="raised">{formatAmount(piece.amount_raised || 0)}</span>
                <span class="goal">of {formatAmount(piece.funding_goal)} goal</span>
              </div>
              
              <div class="progress-bar">
                <div 
                  class="progress-fill" 
                  style="width: {getProgressPercentage()}%"
                ></div>
              </div>
              
              <div class="funding-stats">
                <div class="stat">
                  <span class="stat-value">{followersCount}</span>
                  <span class="stat-label">Followers</span>
                </div>
                <div class="stat">
                  <span class="stat-value">{piece.contributors?.length || 0}</span>
                  <span class="stat-label">Contributors</span>
                </div>
                <div class="stat">
                  <span class="stat-value">{piece.sponsors?.length || 0}</span>
                  <span class="stat-label">Sponsors</span>
                </div>
              </div>
              
              {#if $user}
                <button 
                  class="donate-btn-large primary" 
                  on:click={openDonationModal}
                >
                  Donate to this Project
                </button>
              {:else}
                <a href="/auth" use:link class="auth-btn primary">
                  Sign in to Donate
                </a>
              {/if}
            </div>
          {/if}
          
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
                      <p class="contributor-role">{contributor.role}</p>
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          {/if}
          
          <!-- Project Status -->
          {#if piece.project_status}
            <div class="status-card">
              <h3>Project Status</h3>
              <div class="status-badge">
                {#if piece.project_status === 'open_to_applications'}
                  <span class="status open">Open to Applications</span>
                  {#if $user}
                    <a href="/apply/{piece.id}" use:link class="apply-btn">
                      Apply as Artist
                    </a>
                  {/if}
                {:else if piece.project_status === 'seeking_funding'}
                  <span class="status seeking">Seeking Funding</span>
                {:else if piece.project_status === 'published'}
                  <span class="status published">Published</span>
                {:else}
                  <span class="status draft">Draft</span>
                {/if}
              </div>
              
              {#if piece.milestones && piece.milestones.length > 0}
                <div class="milestones">
                  <h4>Project Milestones</h4>
                  <ul class="milestone-list">
                    {#each piece.milestones as milestone}
                      <li class="milestone-item" class:completed={milestone.completed}>
                        <div class="milestone-checkbox">
                          <div class="checkbox" class:checked={milestone.completed}></div>
                        </div>
                        <div class="milestone-content">
                          <h5>{milestone.title}</h5>
                          {#if milestone.description}
                            <p>{milestone.description}</p>
                          {/if}
                          {#if milestone.due_date}
                            <span class="due-date">Due: {new Date(milestone.due_date).toLocaleDateString()}</span>
                          {/if}
                        </div>
                      </li>
                    {/each}
                  </ul>
                </div>
              {/if}
            </div>
          {/if}
          
          <!-- Tags -->
          {#if (piece.cause_tags && piece.cause_tags.length > 0) || (piece.accepted_mediums && piece.accepted_mediums.length > 0)}
            <div class="tags-card">
              {#if piece.cause_tags && piece.cause_tags.length > 0}
                <div class="tags-section">
                  <h3>Causes</h3>
                  <div class="tags-list">
                    {#each piece.cause_tags as tag}
                      <span class="tag cause-tag">{tag}</span>
                    {/each}
                  </div>
                </div>
              {/if}
              
              {#if piece.accepted_mediums && piece.accepted_mediums.length > 0}
                <div class="tags-section">
                  <h3>Artistic Mediums</h3>
                  <div class="tags-list">
                    {#each piece.accepted_mediums as medium}
                      <span class="tag medium-tag">{medium}</span>
                    {/each}
                  </div>
                </div>
              {/if}
            </div>
          {/if}
          
          <!-- View Button -->
          {#if piece.video_url || piece.image_url}
            <div class="view-card">
              <a href="/view/{piece.id}" use:link class="view-btn">
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                  <circle cx="12" cy="12" r="3"></circle>
                </svg>
                View in Fullscreen
              </a>
            </div>
          {/if}
        </div>
      </div>
    </div>
    
    <!-- Donation Modal -->
    <DonationModal 
      show={showDonationModal} 
      pieceId={piece.id} 
      pieceName={piece.title} 
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

  .header-content h1 {
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

  .follow-btn,
  .donate-btn {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: 50px;
    font-weight: 500;
    transition: all 0.2s;
  }

  .follow-btn {
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
  }

  .follow-btn:hover {
    background-color: var(--color-neutral-100);
  }

  .follow-btn.following {
    background-color: var(--color-success-600);
    color: white;
    border-color: var(--color-success-600);
  }

  .follow-btn.following:hover {
    background-color: var(--color-success-700);
  }

  .donate-btn {
    background-color: var(--color-primary-600);
    color: white;
    border: none;
  }

  .donate-btn:hover {
    background-color: var(--color-primary-700);
  }

  .auth-link {
    color: var(--text-color);
    text-decoration: none;
    font-weight: 500;
  }

  .auth-link:hover {
    text-decoration: underline;
  }

  .piece-content {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: var(--space-6);
  }

  .piece-main {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .media-section {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    overflow: hidden;
  }

  :global(.light-mode) .media-section {
    background: var(--bg-color);
  }

  .video-container,
  .image-container {
    width: 100%;
  }

  .piece-video,
  .piece-image {
    width: 100%;
    display: block;
  }

  .audio-container {
    padding: var(--space-4);
    border-top: 1px solid var(--border-color);
  }

  .piece-audio {
    width: 100%;
  }

  .description-section {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  :global(.light-mode) .description-section {
    background: var(--bg-color);
  }

  .mission-content,
  .description-content,
  .overview-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .mission-content :global(p),
  .description-content p,
  .overview-content p {
    color: var(--text-color);
    line-height: 1.6;
    margin: 0;
  }

  .mission-content :global(ul),
  .mission-content :global(ol),
  .description-content ul,
  .description-content ol,
  .overview-content ul,
  .overview-content ol {
    margin: var(--space-3) 0;
    padding-left: var(--space-6);
  }

  .mission-content :global(li),
  .description-content li,
  .overview-content li {
    margin-bottom: var(--space-2);
  }

  .description-content h2,
  .overview-content h2 {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .piece-sidebar {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .funding-card,
  .organizer-card,
  .contributors-card,
  .status-card,
  .tags-card,
  .view-card {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  :global(.light-mode) .funding-card,
  :global(.light-mode) .organizer-card,
  :global(.light-mode) .contributors-card,
  :global(.light-mode) .status-card,
  :global(.light-mode) .tags-card,
  :global(.light-mode) .view-card {
    background: var(--bg-color);
  }

  .funding-card h3,
  .organizer-card h3,
  .contributors-card h3,
  .status-card h3,
  .tags-card h3 {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .funding-amount {
    display: flex;
    align-items: baseline;
    gap: var(--space-2);
    margin-bottom: var(--space-3);
  }

  .raised {
    font-size: 1.5rem;
    font-weight: 600;
    color: var(--text-color);
  }

  .goal {
    color: var(--text-muted);
    font-size: 0.875rem;
  }

  .progress-bar {
    height: 8px;
    background-color: var(--color-neutral-100);
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: var(--space-4);
  }

  .progress-fill {
    height: 100%;
    background-color: var(--color-success-600);
    border-radius: 4px;
    transition: width 0.3s ease;
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
    gap: var(--space-1);
  }

  .stat-value {
    font-weight: 600;
    color: var(--text-color);
  }

  .stat-label {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .donate-btn-large {
    width: 100%;
    padding: var(--space-3);
    border-radius: 50px;
    font-weight: 500;
    text-align: center;
    background-color: var(--color-success-600);
    color: white;
    border: none;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .donate-btn-large:hover {
    background-color: var(--color-success-700);
  }

  .auth-btn {
    display: block;
    width: 100%;
    padding: var(--space-3);
    border-radius: 50px;
    font-weight: 500;
    text-align: center;
    text-decoration: none;
  }

  .organizer-info {
    display: flex;
    gap: var(--space-3);
  }

  .organizer-avatar {
    width: 60px;
    height: 60px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
  }

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
    font-size: 1.5rem;
  }

  .organizer-details {
    flex: 1;
  }

  .organizer-details h4 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .organizer-details p {
    color: var(--text-muted);
    font-size: 0.875rem;
    margin: 0;
    line-height: 1.4;
  }

  .contributors-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .contributor-item {
    display: flex;
    gap: var(--space-3);
  }

  .contributor-avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
  }

  .contributor-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .contributor-details {
    flex: 1;
  }

  .contributor-details h4 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .contributor-role {
    color: var(--text-muted);
    font-size: 0.875rem;
    margin: 0;
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

  .status.open {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .status.seeking {
    background-color: var(--color-warning-100);
    color: var(--color-warning-700);
  }

  .status.published {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .status.draft {
    background-color: var(--color-neutral-100);
    color: var(--color-neutral-700);
  }

  .apply-btn {
    display: inline-block;
    margin-top: var(--space-2);
    padding: var(--space-2) var(--space-3);
    background-color: var(--color-success-600);
    color: white;
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    font-size: 0.875rem;
  }

  .apply-btn:hover {
    background-color: var(--color-success-700);
  }

  .milestones {
    margin-top: var(--space-4);
  }

  .milestones h4 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .milestone-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .milestone-item {
    display: flex;
    gap: var(--space-3);
  }

  .milestone-checkbox {
    padding-top: 2px;
  }

  .checkbox {
    width: 18px;
    height: 18px;
    border: 2px solid var(--border-color);
    border-radius: 4px;
    position: relative;
  }

  .checkbox.checked {
    background-color: var(--color-success-600);
    border-color: var(--color-success-600);
  }

  .checkbox.checked::after {
    content: '';
    position: absolute;
    left: 5px;
    top: 2px;
    width: 5px;
    height: 10px;
    border: solid white;
    border-width: 0 2px 2px 0;
    transform: rotate(45deg);
  }

  .milestone-content {
    flex: 1;
  }

  .milestone-content h5 {
    font-size: 0.9375rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .milestone-content p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-1) 0;
    line-height: 1.4;
  }

  .due-date {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .milestone-item.completed .milestone-content h5 {
    text-decoration: line-through;
    color: var(--text-muted);
  }

  .tags-section {
    margin-bottom: var(--space-4);
  }

  .tags-section:last-child {
    margin-bottom: 0;
  }

  .tags-section h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .tags-list {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }

  .tag {
    display: inline-block;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-md);
    font-size: 0.75rem;
    font-weight: 500;
  }

  .cause-tag {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .medium-tag {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
  }

  .view-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3);
    background-color: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    transition: all 0.2s;
  }

  .view-btn:hover {
    background-color: var(--color-neutral-100);
  }

  /* Donation Status Messages */
  .donation-status {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    padding: var(--space-4) var(--space-6);
    border-radius: var(--radius-lg);
    margin-bottom: var(--space-6);
  }

  .donation-status.success {
    background-color: var(--color-success-50);
    border: 1px solid var(--color-success-200);
  }

  .donation-status.canceled {
    background-color: var(--color-neutral-50);
    border: 1px solid var(--color-neutral-200);
  }

  .status-icon {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5rem;
    flex-shrink: 0;
  }

  .donation-status.success .status-icon {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .donation-status.canceled .status-icon {
    background-color: var(--color-neutral-100);
    color: var(--color-neutral-700);
  }

  .status-message {
    flex: 1;
  }

  .status-message h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
  }

  .donation-status.success .status-message h3 {
    color: var(--color-success-700);
  }

  .donation-status.canceled .status-message h3 {
    color: var(--color-neutral-700);
  }

  .status-message p {
    margin: 0;
    font-size: 0.875rem;
  }

  .donation-status.success .status-message p {
    color: var(--color-success-600);
  }

  .donation-status.canceled .status-message p {
    color: var(--color-neutral-600);
  }

  @media (max-width: 768px) {
    .piece-detail {
      padding: var(--space-4);
    }

    .header-content h1 {
      font-size: 2rem;
    }

    .piece-content {
      grid-template-columns: 1fr;
    }

    .header-actions {
      flex-wrap: wrap;
    }

    .funding-stats {
      flex-wrap: wrap;
      gap: var(--space-3);
    }

    .stat {
      flex: 1;
      min-width: 80px;
    }
  }
</style>