<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import { products } from '../stripe-config';
  
  export let params = { id: '' };
  
  let piece: any = null;
  let loading = true;
  let error: string | null = null;
  let isFollowing = false;
  let isOrganizer = false;
  let isContributor = false;
  let hasDonated = false;
  let checkoutLoading = false;
  let checkoutError: string | null = null;
  
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
      
      // Check if current user is the organizer
      if ($user && piece.organizer_user_id === $user.id) {
        isOrganizer = true;
      }
      
      // Check if current user is a contributor
      if ($user && piece.contributors) {
        const isUserContributor = piece.contributors.some(
          (contributor: any) => {
            // Get the user's artist profile
            return supabase
              .from('artists')
              .select('id')
              .eq('user_id', $user.id)
              .eq('id', contributor.id)
              .then(({ data }) => data && data.length > 0);
          }
        );
        
        isContributor = isUserContributor;
      }
      
      // Check if user is following the piece
      if ($user) {
        const { data: followData } = await supabase
          .from('piece_followers')
          .select('piece_id')
          .eq('piece_id', params.id)
          .eq('profile_id', $user.id)
          .maybeSingle();
          
        isFollowing = !!followData;
        
        // Check if user has donated to this piece
        const { data: customerData } = await supabase
          .from('stripe_customers')
          .select('customer_id')
          .eq('user_id', $user.id)
          .maybeSingle();
          
        if (customerData && customerData.customer_id) {
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
    if (!$user) {
      push('/auth');
      return;
    }
    
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
        piece.follower_count += isFollowing ? 1 : -1;
      }
    } catch (e: any) {
      console.error('Error toggling follow:', e);
    }
  }
  
  async function handleDonate() {
    if (!$user) {
      push('/auth');
      return;
    }
    
    try {
      checkoutLoading = true;
      checkoutError = null;
      
      const { priceId, mode } = products.donation;
      
      const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/stripe-checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`
        },
        body: JSON.stringify({
          price_id: priceId,
          success_url: `${window.location.origin}/piece/${params.id}?donation=success`,
          cancel_url: `${window.location.origin}/piece/${params.id}?donation=canceled`,
          mode,
          piece_id: params.id
        })
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to create checkout session');
      }
      
      const { url } = await response.json();
      
      // Redirect to Stripe Checkout
      window.location.href = url;
      
    } catch (e: any) {
      checkoutError = e.message;
    } finally {
      checkoutLoading = false;
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
  
  function calculateProgress(raised: number, goal: number): number {
    if (!goal || goal <= 0) return 0;
    const progress = (raised / goal) * 100;
    return Math.min(progress, 100); // Cap at 100%
  }
  
  // Check if the current user can view this piece
  function canViewPiece(): boolean {
    if (!piece) return false;
    
    // If piece is approved, anyone can view it
    if (piece.approved) return true;
    
    // If piece is in 'submitted_for_approval' status, only organizer and contributors can view
    if (piece.project_status === 'submitted_for_approval') {
      return isOrganizer || isContributor;
    }
    
    // For other statuses, if not approved, only organizer and contributors can view
    return isOrganizer || isContributor;
  }
  
  // Check if the current user can view the full piece content (image, audio, etc.)
  function canViewFullContent(): boolean {
    if (!piece) return false;
    
    // Organizers and contributors can always view full content
    if (isOrganizer || isContributor) return true;
    
    // If the piece is not approved, only organizers and contributors can view
    if (!piece.approved) return false;
    
    // For approved pieces, check if user has donated
    return hasDonated;
  }
  
  onMount(() => {
    if (params.id) {
      loadPiece();
    }
    
    // Check for donation success/cancel query params
    const urlParams = new URLSearchParams(window.location.search);
    const donationStatus = urlParams.get('donation');
    
    if (donationStatus === 'success') {
      // Reload the piece to update donation status
      loadPiece();
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
        <h2>Piece Not Found</h2>
        <p>{error}</p>
        <a href="/explore" use:link class="primary">Explore Pieces</a>
      </div>
    </div>
  {:else if !canViewPiece()}
    <div class="unauthorized-container" transition:fade>
      <div class="unauthorized-card">
        <h2>Access Restricted</h2>
        <p>This piece is currently in review and not publicly available.</p>
        <a href="/explore" use:link class="primary">Explore Public Pieces</a>
      </div>
    </div>
  {:else if piece}
    <div class="piece-container">
      <!-- Draft Banner (if piece is not approved) -->
      {#if !piece.approved}
        <div class="draft-banner" in:fade>
          <div class="draft-content">
            <div class="draft-icon">
              <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </div>
            <div class="draft-message">
              <span class="draft-label">DRAFT</span>
              <span class="draft-text">
                {#if piece.project_status === 'submitted_for_approval'}
                  This piece is currently under review and not publicly visible.
                {:else}
                  This piece is not yet approved and only visible to you and contributors.
                {/if}
              </span>
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Header Section -->
      <div class="piece-header" in:fade>
        <div class="header-content">

          <!-- Project Status -->
          <div class="project-status-container" in:fly={{ y: 20, duration: 300, delay: 150 }}>
            <div class="status-badge {piece.project_status}">
              {#if piece.project_status === 'submitted_for_approval'}
                Submitted for Approval
              {:else if piece.project_status === 'open_to_applications'}
                Open to Applications
              {:else if piece.project_status === 'seeking_funding'}
                Seeking Funding
              {:else if piece.project_status === 'published'}
                Published
              {/if}
            </div>
          </div>
        
          <div class="header-actions">
            {#if isOrganizer}
              <a href="/update/{piece.id}" use:link class="edit-button">
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
                Edit Piece
              </a>
              
              <a href="/edit/{piece.id}" use:link class="edit-button">
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M15 10l4.553-2.276A1 1 0 0 1 21 8.618v6.764a1 1 0 0 1-1.447.894L15 14M5 18h8a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2z"></path>
                </svg>
                Editor
              </a>
            {/if}
          </div>
        </div>
      </div>
      
      <!-- Main Content -->
      <div class="piece-content">
        <!-- Left Column -->
        <div class="content-left">
          <div class="piece-introduction">
            <h1>{piece.title}</h1>
  
            <!-- Description -->
            {#if piece.piece_description}
              <div class="description-section" in:fly={{ y: 20, duration: 300, delay: 50 }}>
                <div class="description-content">
                  {piece.piece_description}
                </div>
              </div>
            {/if}
  
            <!-- Cause Tags -->
            {#if piece.cause_tags && piece.cause_tags.length > 0}
              <div class="tags-section" in:fly={{ y: 20, duration: 300, delay: 150 }}>
                <div class="tags-list">
                  {#each piece.cause_tags as tag}
                    <span class="tag cause-tag">{tag}</span>
                  {/each}
                </div>
              </div>
            {/if}
          </div>

          <!-- Main Image -->
          <div class="piece-image-container" in:fly={{ y: 20, duration: 300 }}>
            {#if piece.image_url}
              <div class="piece-image">
                <img src={piece.image_url} alt={piece.title} />
                
                {#if !canViewFullContent()}
                  <div class="image-overlay">
                    <div class="overlay-content">
                      <div class="lock-icon">
                        <svg viewBox="0 0 24 24" width="32" height="32" stroke="currentColor" stroke-width="2" fill="none">
                          <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                          <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                        </svg>
                      </div>
                      <h3>Support to Unlock</h3>
                      <p>Donate to this piece to access the full content</p>
                      <button class="donate-button" on:click={handleDonate}>
                        Donate Now
                      </button>
                    </div>
                  </div>
                {:else}
                  <a href="/view/{piece.id}" use:link class="view-button">
                    <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                      <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                    View Full Piece
                  </a>
                {/if}
              </div>
            {:else}
              <div class="image-placeholder">
                <svg viewBox="0 0 24 24" width="48" height="48" stroke="currentColor" stroke-width="1" fill="none">
                  <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                  <circle cx="8.5" cy="8.5" r="1.5"></circle>
                  <polyline points="21,15 16,10 5,21"></polyline>
                </svg>
                <p>No image available</p>
              </div>
            {/if}
          </div>

          <div class="piece-meta">
            <div class="organizer">
              <span>Organized by</span>
              <a href="/profile/{piece.organizer_name}" use:link class="organizer-name">
                {piece.organizer_name}
              </a>
            </div>

            <!-- Sponsors -->
            {#if piece.sponsors && piece.sponsors.length > 0}
              <div class="sponsors-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
                <h3>Sponsors</h3>
                <div class="sponsors-list">
                  {#each piece.sponsors as sponsor}
                    <div class="sponsor-card">
                      {#if sponsor.logo_url}
                        <img src={sponsor.logo_url} alt={sponsor.name} class="sponsor-logo" />
                      {:else}
                        <div class="sponsor-placeholder">
                          {sponsor.name?.[0]?.toUpperCase() || 'S'}
                        </div>
                      {/if}
                      <div class="sponsor-info">
                        <h4 class="sponsor-name">{sponsor.name}</h4>
                        <span class="sponsor-amount">{formatAmount(sponsor.amount)}</span>
                      </div>
                    </div>
                  {/each}
                </div>
              </div>
            {/if}
          </div>
          
          <!-- Mission -->
          {#if piece.mission}
            <div class="mission-section" in:fly={{ y: 20, duration: 300 }}>
              <h2>Mission</h2>
              <div class="mission-content">
                {@html piece.mission}
              </div>
            </div>
          {/if}
          
          <!-- Project Details -->
          {#if piece.full_project_overview || piece.collaboration_structure || piece.deliverable_format}
            <div class="details-section" in:fly={{ y: 20, duration: 300, delay: 100 }}>
              <h2>Project Details</h2>
              
              {#if piece.full_project_overview}
                <div class="detail-group">
                  <h3>Project Overview</h3>
                  <p>{piece.full_project_overview}</p>
                </div>
              {/if}
              
              {#if piece.collaboration_structure}
                <div class="detail-group">
                  <h3>Collaboration Structure</h3>
                  <p>{piece.collaboration_structure}</p>
                </div>
              {/if}
              
              {#if piece.deliverable_format}
                <div class="detail-group">
                  <h3>Deliverable Format</h3>
                  <p>{piece.deliverable_format}</p>
                </div>
              {/if}
              
              {#if piece.compensation_details}
                <div class="detail-group">
                  <h3>Compensation Details</h3>
                  <p>{piece.compensation_details}</p>
                </div>
              {/if}
            </div>
          {/if}
          
          
          <!-- Project Timeline -->
          {#if piece.milestones && piece.milestones.length > 0}
            <div class="timeline-section" in:fly={{ y: 20, duration: 300, delay: 250 }}>
              <h2>Project Timeline</h2>
              <div class="timeline">
                {#each piece.milestones as milestone, index}
                  <div class="timeline-item" class:completed={milestone.completed}>
                    {#if milestone.due_date}
                      <div class="timeline-date">
                        <span>
                          {new Date(milestone.due_date).toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric'
                          })}
                        </span>
                      </div>
                    {/if}
                    <div class="timeline-marker">
                      <div class="marker-dot"></div>
                      {#if index < piece.milestones.length - 1}
                        <div class="marker-line"></div>
                      {/if}
                    </div>
                    <div class="timeline-content">
                      <h3 class="timeline-title">{milestone.title}</h3>
                      {#if milestone.description}
                        <p class="timeline-description">{milestone.description}</p>
                      {/if}
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

          <!-- Contributors -->
          {#if piece.contributors && piece.contributors.length > 0}
            <div class="contributors-section" in:fly={{ y: 20, duration: 300, delay: 250 }}>
              <h2>Meet the Team (so far)</h2>
              <div class="contributors-list">
                {#each piece.contributors as contributor}
                  <div class="contributor-card">
                    <div class="contributor-avatar">
                      {#if contributor.avatar_url}
                        <img src={contributor.avatar_url} alt={contributor.name} />
                      {:else}
                        <div class="avatar-placeholder">
                          {contributor.name?.[0]?.toUpperCase() || 'A'}
                        </div>
                      {/if}
                    </div>
                    <div class="contributor-info">
                      <h4 class="contributor-name">{contributor.name}</h4>
                      <span class="contributor-role">{contributor.role}</span>
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

        </div>
        
        <!-- Right Column -->
        <div class="content-right">
          <!-- Funding Progress -->
          {#if piece.funding_goal && piece.funding_goal > 0}
            <div class="funding-progress" in:fly={{ y: 20, duration: 300, delay: 200 }}>
              <div class="funding-header">
                <h3>Funding Progress</h3>
                <div class="funding-amounts">
                  <span class="amount-raised">{formatAmount(piece.amount_raised || 0)}</span>
                  <span class="amount-separator">of</span>
                  <span class="funding-goal">{formatAmount(piece.funding_goal)}</span>
                </div>
              </div>
              
              <div class="progress-bar">
                <div 
                  class="progress-fill" 
                  style="width: {calculateProgress(piece.amount_raised || 0, piece.funding_goal)}%"
                ></div>
              </div>
              
              <div class="funding-actions">
                <button 
                  class="donate-button" 
                  on:click={handleDonate}
                  disabled={checkoutLoading}
                >
                  {#if checkoutLoading}
                    <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                      <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                        <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                      </circle>
                    </svg>
                    Processing...
                  {:else}
                    <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                      <line x1="12" y1="1" x2="12" y2="23"></line>
                      <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
                    </svg>
                    Donate to Support
                  {/if}
                </button>
                
                {#if checkoutError}
                  <div class="checkout-error">
                    {checkoutError}
                  </div>
                {/if}
              </div>
            </div>
          {/if}

          <div class="piece-stats">
            <div class="stat">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
              </svg>
              <span>{piece.follower_count || 0} Followers</span>
            </div>
            
            <div class="stat">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
              </svg>
              <span>{piece.contributors?.length || 0} Contributors</span>
            </div>
            
            <div class="stat">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <line x1="12" y1="1" x2="12" y2="23"></line>
                <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
              </svg>
              <span>{formatAmount(piece.amount_raised || 0)} Raised</span>
            </div>
          </div>

          <!-- Apply Button -->
          {#if piece.project_status === 'open_to_applications' && !isOrganizer && !isContributor && piece.approved}
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

          <!-- Follow Button -->
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
        </div>
      </div>
    </div>
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

  .error-container,
  .unauthorized-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
  }

  .error-card,
  .unauthorized-card {
    background: var(--card-bg);
    border: 1px solid var(--color-error-200);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    max-width: 500px;
  }

  .error-card h2,
  .unauthorized-card h2 {
    color: var(--color-error-600);
    margin-bottom: var(--space-4);
  }

  .piece-container {
    display: flex;
    flex-direction: column;
    gap: 0px;
  }

  /* Draft Banner */
  .draft-banner {
    background-color: var(--color-warning-100);
    border: 1px solid var(--color-warning-300);
    border-radius: var(--radius-lg);
    padding: var(--space-4);
    margin-bottom: var(--space-4);
  }

  .draft-content {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .draft-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    background-color: var(--color-warning-200);
    color: var(--color-warning-700);
    border-radius: 50%;
    flex-shrink: 0;
  }

  .draft-message {
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
  }

  .draft-label {
    font-weight: 700;
    color: var(--color-warning-700);
    font-size: 0.875rem;
  }

  .draft-text {
    color: var(--color-warning-700);
    font-size: 0.875rem;
  }

  /* Header Section */
  .piece-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: var(--space-6);
  }

  .header-content {
    flex: 1;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .piece-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .piece-meta {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: var(--space-4);
  }

  .organizer {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    color: var(--text-muted);
  }

  .organizer-name {
    font-weight: 500;
    color: var(--color-primary-600);
    text-decoration: none;
  }

  .organizer-name:hover {
    text-decoration: underline;
  }

  .piece-stats {
    display: flex;
    gap: var(--space-4);
  }

  .stat {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    color: var(--text-muted);
    font-size: 0.875rem;
  }

  .header-actions {
    display: flex;
    gap: var(--space-3);
  }

  .edit-button,
  .follow-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    font-weight: 500;
    transition: all 0.2s;
  }

  .edit-button {
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    text-decoration: none;
  }

  .edit-button:hover {
    background: var(--color-neutral-100);
    color: var(--color-neutral-900);
  }

  .follow-button {
    background-color: var(--color-primary-600);
    color: white;
    border: none;
    cursor: pointer;
  }

  .follow-button:hover {
    background-color: var(--color-primary-700);
  }

  .follow-button.following {
    background-color: var(--color-success-600);
  }

  .follow-button.following:hover {
    background-color: var(--color-success-700);
  }

  /* Main Content */

  .content-left .piece-introduction {
    display: flex;
    flex-direction: column;
    gap: 5px;
  }

  .description-section {
    margin-bottom: 12px;
  }

  .piece-content {
    display: grid;
    grid-template-columns: 1fr 450px;
    gap: 65px;
  }

  .piece-content h1 {
    margin-bottom: 0px;
  }

  .piece-content h2 {
    margin-bottom: 20px !important;
    font-size: 28px !important;
    font-family: var(--font-instrument-serif);
  }

  .content-left,
  .content-right {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .content-right {
    padding-top: 100px;
  }

  /* Image Section */
  .piece-image-container {
    width: 100%;
  }

  .piece-image {
    position: relative;
    width: 100%;
    border-radius: var(--radius-lg);
    overflow: hidden;
  }

  .piece-image img {
    width: 100%;
    height: auto;
    display: block;
    border-radius: var(--radius-lg);
  }

  .image-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.7);
    display: flex;
    align-items: center;
    justify-content: center;
    backdrop-filter: blur(4px);
  }

  .overlay-content {
    text-align: center;
    padding: var(--space-6);
    max-width: 300px;
  }

  .lock-icon {
    display: flex;
    justify-content: center;
    margin-bottom: var(--space-4);
    color: white;
  }

  .overlay-content h3 {
    color: white;
    margin: 0 0 var(--space-2) 0;
    font-size: 1.5rem;
  }

  .overlay-content p {
    color: rgba(255, 255, 255, 0.8);
    margin: 0 0 var(--space-4) 0;
  }

  .donate-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    background-color: var(--color-success-600);
    color: white;
    border: none;
    padding: var(--space-3) var(--space-6);
    border-radius: var(--radius-md);
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
    width: 100%;
  }

  .donate-button:hover {
    background-color: var(--color-success-700);
  }

  .donate-button:disabled {
    background-color: var(--color-neutral-400);
    cursor: not-allowed;
  }

  .view-button {
    position: absolute;
    bottom: var(--space-4);
    right: var(--space-4);
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background-color: rgba(0, 0, 0, 0.7);
    color: white;
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    transition: background-color 0.2s;
    backdrop-filter: blur(4px);
  }

  .view-button:hover {
    background-color: rgba(0, 0, 0, 0.9);
  }

  .image-placeholder {
    width: 100%;
    height: 300px;
    background-color: var(--color-neutral-100);
    border-radius: var(--radius-lg);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
    gap: var(--space-2);
  }

  /* Audio Section */
  .audio-container {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-4);
  }

  .audio-container h3 {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .audio-player {
    width: 100%;
  }

  /* Project Status */
  .project-status-container {
    padding: 0px;
  }

  .project-status-container h3 {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .status-badge {
    font-size: 0.75rem;
    font-weight: 500;
    position: relative;
    --circle-size: 10px;
    padding-left: calc(var(--circle-size) + 10px);
  }

  .status-badge.submitted_for_approval::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: var(--circle-size);
    height: var(--circle-size);
    background-color: var(--color-neutral-400);
    border-radius: 50%;
  }

  .status-badge.open_to_applications::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: var(--circle-size);
    height: var(--circle-size);
    background-color: var(--color-success-600);
    border-radius: 50%;
  }

  .status-badge.seeking_funding::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: var(--circle-size);
    height: var(--circle-size);
    background-color: var(--color-warning-500);
    border-radius: 50%;
  }

  .status-badge.published::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: var(--circle-size);
    height: var(--circle-size);
    background-color: var(--color-success-500);
    border-radius: 50%;
  }

  .apply-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background-color: var(--color-success-600);
    color: white;
    border: none;
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    transition: background-color 0.2s;
    width: fit-content;
  }

  .apply-button:hover {
    background-color: var(--color-success-700);
  }

  /* Funding Progress */
  .funding-progress {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-4);
  }

  .funding-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-3);
  }

  .funding-header h3 {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0;
    color: var(--text-color);
  }

  .funding-amounts {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    font-size: 0.875rem;
  }

  .amount-raised {
    font-weight: 600;
    color: var(--color-success-600);
  }

  .amount-separator {
    color: var(--text-muted);
  }

  .funding-goal {
    color: var(--text-color);
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

  .funding-actions {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .checkout-error {
    color: var(--color-error-600);
    font-size: 0.875rem;
    text-align: center;
  }

  .mission-section,
  .details-section,
  .contributors-section,
  .timeline-section {
    padding-top: var(--space-6);
    border-top: solid 1px var(--border-color);
  }

  /* Contributors Section */
  .contributors-section h3,
  .sponsors-section h3 {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .contributors-list,
  .sponsors-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .contributor-card,
  .sponsor-card {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    padding: var(--space-3);
    background-color: var(--bg-color);
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
  }

  .contributor-avatar,
  .sponsor-logo,
  .sponsor-placeholder {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
  }

  .contributor-avatar img,
  .sponsor-logo {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder,
  .sponsor-placeholder {
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: var(--color-neutral-200);
    color: var(--color-neutral-600);
    font-weight: 600;
    font-size: 1.25rem;
  }

  .contributor-info,
  .sponsor-info {
    flex: 1;
  }

  .contributor-name,
  .sponsor-name {
    font-size: 1rem;
    font-weight: 600;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .contributor-role {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .sponsor-amount {
    font-size: 0.875rem;
    color: var(--color-success-600);
    font-weight: 500;
  }

  .mission-section h2,
  .description-section h2,
  .details-section h2 {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .mission-content,
  .description-content {
    color: var(--text-color);
    line-height: 1.6;
  }

  .mission-content :global(p),
  .description-content p {
    margin-bottom: var(--space-4);
  }

  .mission-content :global(p:last-child),
  .description-content p:last-child {
    margin-bottom: 0;
  }

  .mission-content :global(ul),
  .mission-content :global(ol),
  .description-content ul,
  .description-content ol {
    margin-bottom: var(--space-4);
    padding-left: var(--space-6);
  }

  .mission-content :global(li),
  .description-content li {
    margin-bottom: var(--space-2);
  }

  .detail-group {
    margin-bottom: var(--space-6);
  }

  .detail-group:last-child {
    margin-bottom: 0;
  }

  .detail-group h3 {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .detail-group p {
    color: var(--text-color);
    line-height: 1.6;
    margin: 0;
  }

  .tags-section h3 {
    font-size: 1.125rem;
    font-weight: 600;
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
    font-size: 0.875rem;
    font-weight: 500;
  }

  .cause-tag {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .medium-tag {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  /* Timeline Section */
  .timeline-section h2 {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .timeline {
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
  }

  .timeline-item {
    display: flex;
    gap: var(--space-3);
  }

  .timeline-marker {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .marker-dot {
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background-color: var(--color-neutral-300);
    border: 2px solid var(--color-neutral-400);
    margin-top: 4px;
  }

  .timeline-item.completed .marker-dot {
    background-color: var(--color-success-500);
    border-color: var(--color-success-600);
  }

  .marker-line {
    width: 2px;
    height: 100%;
    background-color: var(--color-neutral-300);
    margin-top: 4px;
    flex: 1;
  }

  .timeline-item.completed .marker-line {
    background-color: var(--color-success-500);
  }

  .timeline-content {
    flex: 1;
    padding-bottom: var(--space-4);
  }

  .timeline-title {
    font-size: 1rem;
    font-weight: 600;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .timeline-item.completed .timeline-title {
    color: var(--color-success-700);
  }

  .timeline-description {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-2) 0;
    line-height: 1.4;
  }

  .timeline-date {
    display: flex;
    align-items: flex-start;
    gap: var(--space-1);
    font-size: 0.75rem;
    color: var(--text-muted);
    width: 45px;
  }

  .spinner {
    animation: spin 1s linear infinite;
  }

  @media (max-width: 1024px) {
    .piece-content {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 768px) {
    .piece-detail {
      padding: var(--space-4);
    }

    .piece-header {
      flex-direction: column;
      gap: var(--space-4);
    }

    .piece-header h1 {
      font-size: 2rem;
    }

    .piece-meta {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-3);
    }

    .header-actions {
      width: 100%;
      justify-content: space-between;
    }

    .funding-header {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-2);
    }

    .draft-content {
      flex-direction: column;
      align-items: center;
      text-align: center;
    }
  }
</style>