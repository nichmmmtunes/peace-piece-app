<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import DonateButton from './DonateButton.svelte'; // Import DonateButton
  import DonationModal from './DonationModal.svelte'; // Import DonationModal
  
  export let params = { id: '' };
  
  let piece: any = null;
  let loading = true;
  let error: string | null = null;
  let isFollowing = false;
  let showDonationModal = false; // Control modal visibility
  
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
  
  onMount(() => {
    if (params.id) {
      loadPiece();
    }
  });
</script>

<div class="piece-detail-container">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading piece details...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Artwork Not Found</h2>
        <p>{error}</p>
        <a href="/explore" use:link class="primary">Explore Artworks</a>
      </div>
    </div>
  {:else if piece}
    <div class="piece-content">
      <!-- Header Section -->
      <div class="piece-header" in:fade>
        <div class="breadcrumb">
          <a href="/explore" use:link>← Back to Explore</a>
        </div>
        <h1>{piece.title}</h1>
        <p class="organizer-info">
          Organized by 
          {#if piece.organizer_name}
            <a href="/organizer/{piece.organizer_username}" use:link class="organizer-link">
              {piece.organizer_name}
            </a>
          {:else}
            Unknown Organizer
          {/if}
        </p>
        <div class="piece-meta">
          <span class="status-badge {piece.project_status}">
            {piece.project_status.replace(/_/g, ' ')}
          </span>
          <span class="raised-amount">
            ${piece.amount_raised} raised of ${piece.funding_goal || 'N/A'} goal
          </span>
          <span class="followers">
            {piece.follower_count || 0} followers
          </span>
        </div>
      </div>

      <!-- Main Media Section -->
      <div class="main-media-section" in:fly={{ y: 20, duration: 300 }}>
        {#if piece.video_url}
          <video controls src={piece.video_url} class="main-video" poster={piece.image_url}>
            Your browser does not support the video tag.
          </video>
        {:else if piece.image_url}
          <img src={piece.image_url} alt={piece.title} class="main-image" />
        {:else}
          <div class="media-placeholder">
            <svg viewBox="0 0 24 24" width="48" height="48" stroke="currentColor" stroke-width="1" fill="none">
              <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
              <circle cx="8.5" cy="8.5" r="1.5"></circle>
              <polyline points="21,15 16,10 5,21"></polyline>
            </svg>
          </div>
        {/if}
        
        {#if piece.audio_url}
          <audio controls src={piece.audio_url} class="main-audio">
            Your browser does not support the audio element.
          </audio>
        {/if}
      </div>

      <!-- Action Buttons -->
      <div class="action-buttons" in:fly={{ y: 20, duration: 300, delay: 100 }}>
        <button class="secondary" on:click={toggleFollow}>
          {#if isFollowing}
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="currentColor">
              <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
            </svg>
            Following
          {:else}
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
            </svg>
            Follow
          {/if}
        </button>
        
        <a href="/view/{piece.id}" use:link class="primary view-piece-btn">
          <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
            <circle cx="12" cy="12" r="3"></circle>
          </svg>
          View Piece
        </a>

        <!-- Donate Button Integration -->
        <button class="primary" on:click={() => showDonationModal = true}>
          <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
          </svg>
          Donate
        </button>
      </div>

      <!-- Project Overview -->
      <section class="project-overview" in:fly={{ y: 20, duration: 300, delay: 200 }}>
        <h2>Project Overview</h2>
        {#if piece.full_project_overview}
          <p>{piece.full_project_overview}</p>
        {:else}
          <p>No detailed project overview provided yet.</p>
        {/if}
      </section>

      <!-- Key Details -->
      <section class="key-details" in:fly={{ y: 20, duration: 300, delay: 300 }}>
        <h2>Key Details</h2>
        <div class="details-grid">
          <div class="detail-item">
            <h3>Collaboration Structure</h3>
            <p>{piece.collaboration_structure || 'Not specified'}</p>
          </div>
          <div class="detail-item">
            <h3>Deliverable Format</h3>
            <p>{piece.deliverable_format || 'Not specified'}</p>
          </div>
          <div class="detail-item">
            <h3>Artists Needed</h3>
            <p>{piece.artists_needed || 'Not specified'}</p>
          </div>
          <div class="detail-item">
            <h3>Compensation</h3>
            <p>{piece.compensation_details || 'Not specified'}</p>
          </div>
        </div>
      </section>

      <!-- Milestones -->
      <section class="milestones-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
        <h2>Milestones</h2>
        {#if piece.milestones && piece.milestones.length > 0}
          <div class="milestones-list">
            {#each piece.milestones as milestone}
              <div class="milestone-item">
                <div class="milestone-status">
                  {#if milestone.completed}
                    <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none" class="completed-icon">
                      <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                  {:else}
                    <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none" class="pending-icon">
                      <circle cx="12" cy="12" r="10"></circle>
                      <line x1="12" y1="8" x2="12" y2="12"></line>
                      <line x1="12" y1="16" x2="12.01" y2="16"></line>
                    </svg>
                  {/if}
                </div>
                <div class="milestone-details">
                  <h3>{milestone.title}</h3>
                  <p>{milestone.description}</p>
                  {#if milestone.due_date}
                    <span class="due-date">Due: {new Date(milestone.due_date).toLocaleDateString()}</span>
                  {/if}
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <p>No milestones defined for this project yet.</p>
        {/if}
      </section>

      <!-- Contributors -->
      <section class="contributors-section" in:fly={{ y: 20, duration: 300, delay: 500 }}>
        <h2>Contributors</h2>
        {#if piece.contributors && piece.contributors.length > 0}
          <div class="contributors-grid">
            {#each piece.contributors as contributor}
              <div class="contributor-card">
                <a href="/artist/{contributor.artist_username}" use:link class="contributor-link">
                  {#if contributor.avatar_url}
                    <img src={contributor.avatar_url} alt={contributor.name} class="contributor-avatar" />
                  {:else}
                    <div class="contributor-avatar-placeholder">
                      {contributor.name?.[0]?.toUpperCase()}
                    </div>
                  {/if}
                  <div class="contributor-info">
                    <h3>{contributor.name}</h3>
                    <p class="contributor-role">{contributor.role}</p>
                  </div>
                </a>
              </div>
            {/each}
          </div>
        {:else}
          <p>No contributors listed yet.</p>
        {/if}
      </section>

      <!-- Sponsors -->
      <section class="sponsors-section" in:fly={{ y: 20, duration: 300, delay: 600 }}>
        <h2>Sponsors</h2>
        {#if piece.sponsors && piece.sponsors.length > 0}
          <div class="sponsors-grid">
            {#each piece.sponsors as sponsor}
              <div class="sponsor-card">
                {#if sponsor.logo_url}
                  <img src={sponsor.logo_url} alt={sponsor.name} class="sponsor-logo" />
                {/if}
                <div class="sponsor-info">
                  <h3>{sponsor.name}</h3>
                  <p class="sponsor-amount">Donated: ${sponsor.amount}</p>
                  {#if sponsor.website}
                    <a href={sponsor.website} target="_blank" rel="noopener noreferrer" class="sponsor-website">
                      Visit Website
                    </a>
                  {/if}
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <p>No sponsors listed yet.</p>
        {/if}
      </section>

      <!-- Comments Section -->
      <section class="comments-section" in:fly={{ y: 20, duration: 300, delay: 700 }}>
        <h2>Comments</h2>
        <p>Comments coming soon!</p>
      </section>
    </div>
  {/if}
</div>

<!-- Donation Modal -->
{#if showDonationModal}
  <DonationModal 
    pieceId={piece.id} 
    pieceName={piece.title} 
    on:close={() => showDonationModal = false} 
  />
{/if}

<style>
  .piece-detail-container {
    padding: var(--space-6);
    max-width: 900px;
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

  .piece-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .piece-header {
    text-align: center;
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

  .piece-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .organizer-info {
    font-size: 1rem;
    color: var(--text-muted);
    margin-bottom: var(--space-3);
  }

  .organizer-link {
    color: var(--text-color);
    text-decoration: none;
    font-weight: 500;
  }

  .organizer-link:hover {
    text-decoration: underline;
  }

  .piece-meta {
    display: flex;
    justify-content: center;
    flex-wrap: wrap;
    gap: var(--space-3);
    font-size: 0.875rem;
  }

  .status-badge {
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-md);
    font-weight: 500;
    text-transform: capitalize;
  }

  .status-badge.open_to_applications {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .status-badge.seeking_funding {
    background-color: var(--color-warning-100);
    color: var(--color-warning-700);
  }

  .status-badge.published {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .raised-amount,
  .followers {
    color: var(--text-muted);
  }

  .main-media-section {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-4);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  .main-image,
  .main-video {
    max-width: 100%;
    height: auto;
    border-radius: var(--radius-md);
    margin-bottom: var(--space-4);
  }

  .main-audio {
    width: 100%;
  }

  .media-placeholder {
    width: 100%;
    height: 300px;
    background-color: var(--color-neutral-100);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
    border-radius: var(--radius-md);
    margin-bottom: var(--space-4);
  }

  .action-buttons {
    display: flex;
    gap: var(--space-3);
    justify-content: center;
    flex-wrap: wrap;
  }

  .action-buttons button,
  .action-buttons a {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: 50px;
    font-weight: 500;
    text-decoration: none;
    transition: all 0.2s;
  }

  .action-buttons .secondary {
    background: var(--card-bg);
    color: var(--text-color);
    border: 1px solid var(--border-color);
  }

  .action-buttons .secondary:hover {
    background-color: var(--color-neutral-100);
  }

  .action-buttons .primary {
    background: var(--text-color);
    color: var(--bg-color);
    border: none;
  }

  .action-buttons .primary:hover {
    background-color: var(--text-muted);
  }

  .view-piece-btn {
    background-color: var(--color-primary-600);
    color: white;
  }

  .view-piece-btn:hover {
    background-color: var(--color-primary-700);
  }

  .project-overview,
  .key-details,
  .milestones-section,
  .contributors-section,
  .sponsors-section,
  .comments-section {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .project-overview h2,
  .key-details h2,
  .milestones-section h2,
  .contributors-section h2,
  .sponsors-section h2,
  .comments-section h2 {
    font-size: 1.5rem;
    font-weight: 700;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .project-overview p {
    color: var(--text-color);
    line-height: 1.6;
  }

  .details-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: var(--space-4);
  }

  .detail-item {
    background-color: var(--bg-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    padding: var(--space-4);
  }

  .detail-item h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .detail-item p {
    font-size: 0.9rem;
    color: var(--text-muted);
    margin: 0;
  }

  .milestones-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .milestone-item {
    display: flex;
    gap: var(--space-3);
    align-items: flex-start;
  }

  .milestone-status {
    flex-shrink: 0;
  }

  .completed-icon {
    color: var(--color-success-600);
  }

  .pending-icon {
    color: var(--color-warning-600);
  }

  .milestone-details h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .milestone-details p {
    font-size: 0.9rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-2) 0;
  }

  .due-date {
    font-size: 0.8rem;
    color: var(--text-muted);
    font-style: italic;
  }

  .contributors-grid,
  .sponsors-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: var(--space-4);
  }

  .contributor-card,
  .sponsor-card {
    background-color: var(--bg-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .contributor-link {
    text-decoration: none;
    color: inherit;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .contributor-avatar {
    width: 60px;
    height: 60px;
    border-radius: 50%;
    object-fit: cover;
    margin-bottom: var(--space-2);
  }

  .contributor-avatar-placeholder {
    width: 60px;
    height: 60px;
    border-radius: 50%;
    background-color: var(--color-neutral-200);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5rem;
    font-weight: 500;
    color: var(--color-neutral-600);
    margin-bottom: var(--space-2);
  }

  .contributor-info h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .contributor-role {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .sponsor-logo {
    max-width: 80px;
    max-height: 60px;
    object-fit: contain;
    margin-bottom: var(--space-2);
  }

  .sponsor-info h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .sponsor-amount {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-bottom: var(--space-2);
  }

  .sponsor-website {
    font-size: 0.875rem;
    color: var(--color-primary-600);
    text-decoration: none;
  }

  .sponsor-website:hover {
    text-decoration: underline;
  }

  @media (max-width: 768px) {
    .piece-detail-container {
      padding: var(--space-4);
    }

    .piece-header h1 {
      font-size: 2rem;
    }

    .piece-meta {
      flex-direction: column;
      gap: var(--space-2);
    }

    .action-buttons {
      flex-direction: column;
    }

    .details-grid,
    .contributors-grid,
    .sponsors-grid {
      grid-template-columns: 1fr;
    }
  }
</style>