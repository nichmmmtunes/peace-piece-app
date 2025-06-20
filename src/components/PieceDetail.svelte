<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import { products } from '../stripe-config';
  
  export let params = { id: '' };
  
  let piece: any = null;
  let loading = true;
  let error: string | null = null;
  let isFollowing = false;
  let canEdit = false;
  let isOrganizer = false;
  let isArtist = false;
  let hasApplied = false;
  let comments: any[] = [];
  let newComment = '';
  let submittingComment = false;
  let hasDonated = false;
  let checkingDonation = false;
  let donating = false;
  let donationError = '';
  
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
      
      // Check if current user is the organizer of this piece
      if ($user && piece.organizer_id) {
        // Get the organizer data to check if current user owns this organizer
        const { data: organizerData } = await supabase
          .from('organizers')
          .select('user_id')
          .eq('id', piece.organizer_id)
          .single();
        
        if (organizerData && organizerData.user_id === $user.id) {
          isOrganizer = true;
          canEdit = true;
          hasDonated = true; // Organizers can always view their own content
        }
      }
      
      // Check if user has donated to this specific piece (only for non-organizers)
      if ($user && !isOrganizer) {
        await checkDonationStatus();
        
        const { data: followData } = await supabase
          .from('piece_followers')
          .select('piece_id')
          .eq('piece_id', params.id)
          .eq('profile_id', $user.id)
          .maybeSingle();
          
        isFollowing = !!followData;
        
        // Check if user has an artist profile
        const { data: artistData } = await supabase
          .from('artists')
          .select('id')
          .eq('user_id', $user.id)
          .maybeSingle();
          
        isArtist = !!artistData;
        
        // Check if user has already applied to this piece
        if (isArtist) {
          const { data: applicationData } = await supabase
            .from('applications')
            .select('id')
            .eq('piece_id', params.id)
            .eq('applicant_profile_id', $user.id)
            .maybeSingle();
            
          hasApplied = !!applicationData;
        }
      }

      // Load comments
      await loadComments();
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  async function checkDonationStatus() {
    if (!$user || isOrganizer) {
      hasDonated = true; // Organizers can always view
      return;
    }

    try {
      checkingDonation = true;
      
      // Check if user has made any successful payments/donations specifically to this piece
      const { data: customerData } = await supabase
        .from('stripe_customers')
        .select('customer_id')
        .eq('user_id', $user.id)
        .maybeSingle();

      if (customerData) {
        // Check for completed orders for this specific piece
        const { data: orderData } = await supabase
          .from('stripe_orders')
          .select('id')
          .eq('customer_id', customerData.customer_id)
          .eq('piece_id', params.id) // Check for this specific piece
          .eq('status', 'completed')
          .limit(1);

        hasDonated = orderData && orderData.length > 0;
      } else {
        hasDonated = false;
      }
    } catch (e: any) {
      console.error('Error checking donation status:', e);
      hasDonated = false; // Default to false on error
    } finally {
      checkingDonation = false;
    }
  }

  async function handleDonate() {
    if (!$user) {
      // Redirect to auth if not logged in
      window.location.hash = '/auth';
      return;
    }

    try {
      donating = true;
      donationError = '';

      // Get the user's session token
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();

      if (sessionError || !session?.access_token) {
        throw new Error('Failed to get user session. Please log in again.');
      }

      const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/stripe-checkout`;
      
      const headers = {
        'Authorization': `Bearer ${session.access_token}`, // Use the user's session token here
        'Content-Type': 'application/json',
      };

      const body = {
        price_id: products.donation.priceId,
        mode: products.donation.mode,
        piece_id: params.id, // Include the piece ID
        success_url: `${window.location.origin}/piece/${params.id}?donation=success`,
        cancel_url: `${window.location.origin}/piece/${params.id}?donation=cancelled`,
      };

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to create checkout session');
      }

      const { url } = await response.json();
      
      if (url) {
        // Redirect to Stripe Checkout
        window.location.href = url;
      } else {
        throw new Error('No checkout URL received');
      }

    } catch (e: any) {
      console.error('Donation error:', e);
      donationError = e.message || 'Failed to process donation. Please try again.';
    } finally {
      donating = false;
    }
  }

  async function loadComments() {
    try {
      const { data, error } = await supabase
        .from('comments')
        .select(`
          *,
          profiles:profile_id (
            username,
            avatar_url
          )
        `)
        .eq('piece_id', params.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      comments = data || [];
    } catch (e: any) {
      console.error('Error loading comments:', e);
    }
  }

  async function submitComment() {
    if (!$user || !newComment.trim() || !hasDonated) return;

    try {
      submittingComment = true;
      
      const { error } = await supabase
        .from('comments')
        .insert({
          piece_id: params.id,
          profile_id: $user.id,
          content: newComment.trim()
        });

      if (error) throw error;

      newComment = '';
      await loadComments();
    } catch (e: any) {
      console.error('Error submitting comment:', e);
    } finally {
      submittingComment = false;
    }
  }
  
  async function toggleFollow() {
    if (!$user || isOrganizer) return;
    
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
      piece.follower_count += isFollowing ? 1 : -1;
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

  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  }
  
  // Function to get status badge color
  function getStatusColor(status: string): string {
    switch (status) {
      case 'open_to_applications':
        return 'var(--color-primary-600)';
      case 'seeking_funding':
        return 'var(--color-warning-600)';
      case 'published':
        return 'var(--color-success-600)';
      default:
        return 'var(--color-neutral-600)';
    }
  }
  
  // Function to get status badge background color
  function getStatusBgColor(status: string): string {
    switch (status) {
      case 'open_to_applications':
        return 'var(--color-primary-100)';
      case 'seeking_funding':
        return 'var(--color-warning-100)';
      case 'published':
        return 'var(--color-success-100)';
      default:
        return 'var(--color-neutral-100)';
    }
  }
  
  // Function to get formatted status label
  function getStatusLabel(status: string): string {
    switch (status) {
      case 'open_to_applications':
        return 'Open to Applications';
      case 'seeking_funding':
        return 'Seeking Funding';
      case 'published':
        return 'Published';
      default:
        return 'Unknown Status';
    }
  }

  // Function to render markdown-like content (basic implementation)
  function renderMarkdown(text: string): string {
    if (!text) return '';
    
    return text
      // Bold text
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      // Italic text
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
      // Line breaks
      .replace(/\n/g, '<br>')
      // Links
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
  }
  
  // Function to calculate days until kickoff
  function getDaysUntilKickoff(): number | null {
    if (!piece?.kickoff_date) return null;
    
    const kickoffDate = new Date(piece.kickoff_date);
    const today = new Date();
    
    // Reset time part for accurate day calculation
    kickoffDate.setHours(0, 0, 0, 0);
    today.setHours(0, 0, 0, 0);
    
    const diffTime = kickoffDate.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    return diffDays > 0 ? diffDays : 0;
  }
  
  // Function to calculate funding progress percentage
  function getFundingProgress(): number {
    if (!piece?.funding_goal || piece.funding_goal <= 0) return 0;
    
    const progress = (piece.amount_raised / piece.funding_goal) * 100;
    return Math.min(100, Math.max(0, progress)); // Clamp between 0-100
  }

  // Check for donation success/cancel in URL params
  onMount(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const donationStatus = urlParams.get('donation');
    
    if (donationStatus === 'success') {
      // Refresh donation status after successful payment
      setTimeout(() => {
        checkDonationStatus();
      }, 1000);
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
      <p>Loading piece...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Oops! Something went wrong</h2>
        <p>{error}</p>
        <button class="primary" on:click={loadPiece}>Try Again</button>
      </div>
    </div>
  {:else if piece}
    <div class="piece-container">
      <!-- Status Badge -->
      {#if piece.project_status}
        <div class="status-badge-container" in:fade>
          <div 
            class="status-badge" 
            style="background-color: {getStatusBgColor(piece.project_status)}; color: {getStatusColor(piece.project_status)};"
          >
            <span class="status-indicator" style="background-color: {getStatusColor(piece.project_status)};"></span>
            {getStatusLabel(piece.project_status)}
          </div>
        </div>
      {/if}

      <!-- Main Content Layout -->
      <div class="piece-layout">
        <!-- Left Column: Main Content -->
        <div class="piece-main-content">
          <!-- Title and Description -->
          <div class="piece-header" in:fly={{ y: 20, duration: 300 }}>
            <h1 class="piece-title">{piece.title}</h1>
            <p class="piece-subtitle">{piece.piece_description || 'A collaborative art piece exploring themes of peace and community.'}</p>
            
            <!-- Cause Tags -->
            {#if piece.cause_tags && piece.cause_tags.length > 0}
              <div class="cause-tags">
                {#each piece.cause_tags as tag}
                  <span class="tag cause-tag">{tag}</span>
                {/each}
              </div>
            {:else}
              <div class="cause-tags">
                <span class="tag cause-tag">Immigration Rights</span>
                <span class="tag cause-tag">Illustration</span>
                <span class="tag cause-tag">Poetry</span>
                <span class="tag cause-tag">Sound Design</span>
              </div>
            {/if}
          </div>

          <!-- Featured Image -->
          {#if piece.image_url}
            <div class="featured-image-container" in:fly={{ y: 20, duration: 300, delay: 100 }}>
              <img src={piece.image_url} alt={piece.title} class="featured-image" />
            </div>
          {/if}

          <!-- Organizer Info -->
          <div class="organizer-section" in:fly={{ y: 20, duration: 300, delay: 200 }}>
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
                <div class="organizer-label">Organized by</div>
                <h3 class="organizer-name">{piece.organizer_name}</h3>
                <p class="organizer-bio">{piece.organizer_description || 'Community organizer and facilitator.'}</p>
              </div>
            </div>
          </div>

          <!-- Sponsor Info -->
          {#if piece.sponsors && piece.sponsors.length > 0}
            <div class="sponsor-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
              <div class="sponsor-label">Sponsored by</div>
              {#each piece.sponsors as sponsor}
                <div class="sponsor-info">
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
                    <h3 class="sponsor-name">{sponsor.name}</h3>
                    <p class="sponsor-bio">{sponsor.bio || 'Supporting arts and community initiatives.'}</p>
                    
                    {#if sponsor.website}
                      <a href={sponsor.website} target="_blank" rel="noopener noreferrer" class="sponsor-link">Website</a>
                    {/if}
                    
                    {#if sponsor.additional_links && sponsor.additional_links.length > 0}
                      <div class="sponsor-additional-links">
                        {#each sponsor.additional_links as link}
                          {#if link.name && link.url}
                            <a href={link.url} target="_blank" rel="noopener noreferrer" class="sponsor-link">{link.name}</a>
                          {/if}
                        {/each}
                      </div>
                    {/if}
                  </div>
                </div>
              {/each}
            </div>
          {/if}

          <!-- About the Project -->
          <section class="about-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
            <h2 class="section-title">About the Project</h2>
            
            {#if piece.full_project_overview}
              <div class="project-overview">
                {@html renderMarkdown(piece.full_project_overview)}
              </div>
            {:else if piece.piece_description}
              <div class="project-overview">
                {@html renderMarkdown(piece.piece_description)}
              </div>
            {/if}
            
            {#if piece.accepted_mediums && piece.accepted_mediums.length > 0}
              <div class="seeking-section">
                <h3>Organizers are specifically seeking:</h3>
                <ul class="seeking-list">
                  {#each piece.accepted_mediums as medium}
                    <li>Artists skilled in {medium}</li>
                  {/each}
                </ul>
              </div>
            {/if}
            
            {#if piece.collaboration_structure}
              <div class="collaboration-section">
                <h3>Collaboration Structure</h3>
                <p>{piece.collaboration_structure}</p>
              </div>
            {/if}
            
            {#if piece.deliverable_format}
              <div class="deliverable-section">
                <h3>Final Deliverable</h3>
                <p>{piece.deliverable_format}</p>
              </div>
            {/if}
            
            {#if piece.compensation_details}
              <div class="compensation-section">
                <h3>Artist Compensation</h3>
                <p>{piece.compensation_details}</p>
              </div>
            {/if}
          </section>

          <!-- Timeline Section -->
          {#if piece.milestones && piece.milestones.length > 0}
            <section class="timeline-section" in:fly={{ y: 20, duration: 300, delay: 500 }}>
              <h2 class="section-title">Timeline</h2>
              
              <div class="timeline">
                {#each piece.milestones as milestone, index}
                  <div class="timeline-item" class:completed={milestone.completed}>
                    <div class="timeline-date">
                      {#if milestone.due_date}
                        <div class="date-month">{formatDate(milestone.due_date).split(' ')[0]}</div>
                        <div class="date-day">{formatDate(milestone.due_date).split(' ')[1].replace(',', '')}</div>
                      {:else}
                        <div class="date-month">TBD</div>
                      {/if}
                    </div>
                    
                    <div class="timeline-content">
                      <div class="timeline-marker" class:completed={milestone.completed}>
                        <div class="marker-dot"></div>
                        {#if index < piece.milestones.length - 1}
                          <div class="marker-line"></div>
                        {/if}
                      </div>
                      
                      <div class="timeline-details">
                        <h3 class="timeline-title">
                          {#if milestone.completed}
                            <span class="completed-icon">✓</span>
                          {/if}
                          {milestone.title}
                        </h3>
                        <p class="timeline-description">{milestone.description}</p>
                      </div>
                    </div>
                  </div>
                {/each}
              </div>
            </section>
          {/if}

          <!-- Meet the Team Section -->
          {#if piece.contributors && piece.contributors.length > 0}
            <section class="team-section" in:fly={{ y: 20, duration: 300, delay: 600 }}>
              <h2 class="section-title">Meet the Team (so far)</h2>
              
              <div class="team-grid">
                {#each piece.contributors as contributor}
                  <div class="team-member">
                    <div class="member-avatar">
                      {#if contributor.avatar_url}
                        <img src={contributor.avatar_url} alt={contributor.name} />
                      {:else}
                        <div class="avatar-placeholder">
                          {contributor.name?.[0]?.toUpperCase() || 'A'}
                        </div>
                      {/if}
                    </div>
                    
                    <div class="member-details">
                      <h3 class="member-name">{contributor.name}</h3>
                      <div class="member-role">{contributor.role}</div>
                      {#if contributor.bio}
                        <p class="member-bio">{contributor.bio}</p>
                      {/if}
                    </div>
                  </div>
                {/each}
              </div>
            </section>
          {/if}

          <!-- Comments Section -->
          <section class="comments-section" in:fly={{ y: 20, duration: 300, delay: 700 }}>
            <h2 class="section-title">Comments ({comments.length})</h2>
            
            {#if $user}
              {#if hasDonated}
                <form class="comment-form" on:submit|preventDefault={submitComment}>
                  <textarea
                    bind:value={newComment}
                    placeholder="Share your thoughts about this piece..."
                    rows="3"
                    disabled={submittingComment}
                  ></textarea>
                  <button 
                    type="submit" 
                    class="primary"
                    disabled={!newComment.trim() || submittingComment}
                  >
                    {submittingComment ? 'Posting...' : 'Post Comment'}
                  </button>
                </form>
              {:else if !checkingDonation}
                <div class="donation-required-prompt">
                  <div class="prompt-icon">
                    <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
                      <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                      <circle cx="12" cy="16" r="1"></circle>
                      <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                    </svg>
                  </div>
                  <div class="prompt-content">
                    <h3>Support this Peace Piece to join the conversation</h3>
                    <p>Donate to unlock the ability to comment and engage with this artistic community.</p>
                    <button 
                      class="primary donate-button"
                      on:click={handleDonate}
                      disabled={donating}
                    >
                      {#if donating}
                        <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                            <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                          </circle>
                        </svg>
                        Processing...
                      {:else}
                        <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                          <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                        </svg>
                        Donate Now
                      {/if}
                    </button>
                    
                    {#if donationError}
                      <div class="donation-error">
                        <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                          <circle cx="12" cy="12" r="10"></circle>
                          <line x1="15" y1="9" x2="9" y2="15"></line>
                          <line x1="9" y1="9" x2="15" y2="15"></line>
                        </svg>
                        {donationError}
                      </div>
                    {/if}
                  </div>
                </div>
              {:else}
                <div class="checking-donation">
                  <div class="loading-spinner small"></div>
                  <p>Checking donation status...</p>
                </div>
              {/if}
            {:else}
              <div class="auth-prompt">
                <p><a href="/auth" use:link>Sign in</a> to leave a comment</p>
              </div>
            {/if}

            <div class="comments-list">
              {#each comments as comment (comment.id)}
                <div class="comment" in:fly={{ y: 20, duration: 300 }}>
                  <div class="comment-header">
                    <div class="comment-author">
                      {#if comment.profiles?.avatar_url}
                        <img src={comment.profiles.avatar_url} alt="Avatar" class="comment-avatar" />
                      {:else}
                        <div class="comment-avatar-placeholder">
                          {comment.profiles?.username?.[0]?.toUpperCase() || '?'}
                        </div>
                      {/if}
                      <span class="comment-username">{comment.profiles?.username || 'Anonymous'}</span>
                    </div>
                    <span class="comment-date">{formatDate(comment.created_at)}</span>
                  </div>
                  <div class="comment-content">
                    <p>{comment.content}</p>
                  </div>
                </div>
              {/each}

              {#if comments.length === 0}
                <div class="empty-comments">
                  <p>No comments yet. Be the first to share your thoughts!</p>
                </div>
              {/if}
            </div>
          </section>
        </div>

        <!-- Right Column: Info Panel -->
        <div class="piece-info-panel">
          <div class="info-card" in:fly={{ y: 20, duration: 300 }}>
            <!-- Funding Information -->
            <div class="funding-info">
              <div class="funding-amount">{formatAmount(piece.amount_raised || 0)}</div>
              <div class="funding-goal">raised of {formatAmount(piece.funding_goal || 5000)} goal</div>
              
              <!-- Progress Bar -->
              <div class="progress-container">
                <div class="progress-bar" style="width: {getFundingProgress()}%"></div>
              </div>
              
              <!-- Countdown -->
              {#if getDaysUntilKickoff() !== null}
                <div class="countdown">
                  <span class="countdown-number">{getDaysUntilKickoff()}</span> days until kick-off
                </div>
              {/if}
            </div>
            
            <!-- Action Buttons -->
            <div class="action-buttons">
              <button class="action-button primary" on:click={handleDonate}>
                Support the Artists
              </button>
              
              {#if piece.project_status === 'published' && $user}
                <a 
                  href="/view/{piece.id}" 
                  use:link 
                  class="action-button secondary view-artwork-button"
                  class:disabled={!hasDonated}
                  title={!hasDonated ? "Donate to view the artwork" : "View the artwork"}
                >
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                    <circle cx="12" cy="12" r="3"></circle>
                  </svg>
                  View Artwork
                </a>
              {/if}
              
              {#if $user && isArtist && !isOrganizer && !hasApplied && piece.project_status === 'open_to_applications'}
                <a href="/apply/{piece.id}" use:link class="action-button secondary">
                  Apply as an Artist
                </a>
              {:else if $user && isArtist && !isOrganizer && hasApplied}
                <button class="action-button secondary" disabled>
                  Application Submitted
                </button>
              {:else if $user && !isArtist && !isOrganizer}
                <a href="/settings/artist-profile" use:link class="action-button secondary">
                  Create Artist Profile
                </a>
              {:else if !$user}
                <a href="/auth" use:link class="action-button secondary">
                  Sign in to Apply
                </a>
              {/if}
              
              <div class="minor-actions">
                <button 
                  class="minor-action-button" 
                  class:active={isFollowing}
                  on:click={toggleFollow}
                  title={isFollowing ? "Unfollow" : "Save"}
                >
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill={isFollowing ? "currentColor" : "none"}>
                    <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"></path>
                  </svg>
                  Save
                </button>
                
                <button class="minor-action-button" title="Share">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <circle cx="18" cy="5" r="3"></circle>
                    <circle cx="6" cy="12" r="3"></circle>
                    <circle cx="18" cy="19" r="3"></circle>
                    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49"></line>
                    <line x1="15.41" y1="6.51" x2="8.59" y2="10.49"></line>
                  </svg>
                  Share
                </button>
              </div>
            </div>
            
            <!-- Donation Summary -->
            {#if piece.cause_tags && piece.cause_tags.length > 0}
              <div class="donation-summary">
                <div class="donation-amount">{formatAmount(580)}</div>
                <div class="donation-cause">
                  Donated to {piece.cause_tags[0]}
                </div>
                <button class="cause-button">
                  Support the Cause
                </button>
              </div>
            {:else}
              <div class="donation-summary">
                <div class="donation-amount">{formatAmount(580)}</div>
                <div class="donation-cause">
                  Donated to Immigrant Rights
                </div>
                <button class="cause-button">
                  Support the Cause
                </button>
              </div>
            {/if}
          </div>
          
          <!-- Edit Button for Organizers -->
          {#if canEdit}
            <div class="edit-card" in:fly={{ y: 20, duration: 300, delay: 100 }}>
              <a href="/update/{piece.id}" use:link class="edit-button">
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
                Edit Peace Piece
              </a>
              
              <a href="/edit/{piece.id}" use:link class="edit-button">
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M15 10l4.553-2.276A1 1 0 0 1 21 8.618v6.764a1 1 0 0 1-1.447.894L15 14M5 18h8a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2z"></path>
                </svg>
                Edit Media
              </a>
            </div>
          {/if}
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .piece-detail {
    max-width: 1200px;
    margin: 0 auto;
    padding: 32px var(--space-4) var(--space-5);
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

  .loading-spinner.small {
    width: 20px;
    height: 20px;
    border-width: 2px;
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

  /* Main Layout */
  .piece-container {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .piece-layout {
    display: grid;
    grid-template-columns: 1fr 350px;
    gap: var(--space-6);
  }

  /* Status Badge */
  .status-badge-container {
    display: flex;
    margin-bottom: var(--space-2);
  }

  .status-badge {
    display: inline-flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-1) var(--space-3);
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .status-indicator {
    width: 8px;
    height: 8px;
    border-radius: 50%;
  }

  /* Main Content */
  .piece-main-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .piece-header {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .piece-title {
    font-size: 2.5rem;
    font-weight: 700;
    line-height: 1.2;
    margin: 0;
    color: var(--text-color);
  }

  .piece-subtitle {
    font-size: 1.125rem;
    color: var(--text-muted);
    margin: 0;
    line-height: 1.5;
  }

  .cause-tags {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
    margin-top: var(--space-3);
  }

  .tag {
    font-size: 0.75rem;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-sm);
    font-weight: 500;
  }

  .cause-tag {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .featured-image-container {
    width: 100%;
    border-radius: var(--radius-lg);
    overflow: hidden;
  }

  .featured-image {
    width: 100%;
    height: auto;
    display: block;
    object-fit: cover;
  }

  /* Organizer Section */
  .organizer-section, .sponsor-section {
    padding: var(--space-4);
    background: var(--bg-color);
    border-radius: 0px;
    border: none;
  }

  .organizer-label, .sponsor-label {
    font-size: 14px;
    color: var(--text-muted);
    margin-bottom: var(--space-2);
  }

  .organizer-info, .sponsor-info {
    display: flex;
    gap: var(--space-4);
    align-items: flex-start;
  }

  .organizer-avatar, .sponsor-logo, .member-avatar {
    width: 64px;
    height: 64px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
  }

  .organizer-avatar img, .sponsor-logo img, .member-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder, .logo-placeholder {
    width: 100%;
    height: 100%;
    background-color: var(--color-neutral-200);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    color: var(--color-neutral-600);
    font-size: 1.5rem;
  }

  .organizer-details, .sponsor-details, .member-details {
    flex: 1;
  }

  .organizer-name, .sponsor-name, .member-name {
    font-size: 1.25rem;
    font-weight: 600;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .organizer-bio, .sponsor-bio, .member-bio {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
    line-height: 1.5;
  }

  .sponsor-link {
    display: inline-block;
    margin-top: var(--space-2);
    margin-right: var(--space-2);
    color: var(--color-primary-600);
    text-decoration: none;
    font-size: 0.875rem;
    font-weight: 500;
  }

  .sponsor-link:hover {
    text-decoration: underline;
  }

  .sponsor-additional-links {
    margin-top: var(--space-2);
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }

  /* Section Styling */
  .section-title {
    font-size: 28px;
    font-weight: 700;
    margin: 0 0 35px 0;
    color: var(--text-color);
    position: relative;
    padding-bottom: var(--space-2);
    font-family: var(--font-instrument-serif);
  }


  .about-section, .timeline-section, .team-section, .comments-section {
    padding: var(--space-6) 0;
    background: transparent;
    border-radius: 0px;
    border-top: 1px solid var(--border-color);
  }

  .project-overview {
    font-size: 1rem;
    line-height: 1.7;
    color: var(--text-color);
    margin-bottom: var(--space-6);
  }

  .seeking-section h3, .collaboration-section h3, .deliverable-section h3, .compensation-section h3 {
    font-size: 1.25rem;
    font-weight: 600;
    margin: var(--space-4) 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .seeking-list {
    list-style-type: none;
    padding: 0;
    margin: 0;
  }

  .seeking-list li {
    position: relative;
    padding-left: var(--space-4);
    margin-bottom: var(--space-2);
    line-height: 1.5;
  }

  .seeking-list li::before {
    content: '•';
    position: absolute;
    left: 0;
    color: var(--color-primary-600);
    font-weight: bold;
  }

  /* Timeline Styling */
  .timeline {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .timeline-item {
    display: flex;
    gap: var(--space-4);
  }

  .timeline-date {
    min-width: 60px;
    text-align: center;
  }

  .date-month {
    font-size: 0.75rem;
    text-transform: uppercase;
    color: var(--text-muted);
    font-weight: 500;
  }

  .date-day {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--text-color);
  }

  .timeline-content {
    display: flex;
    gap: var(--space-3);
    flex: 1;
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
    border: 3px solid var(--bg-color);
    z-index: 1;
  }

  .timeline-item.completed .marker-dot {
    background-color: var(--color-success-600);
  }

  .marker-line {
    width: 2px;
    height: 100%;
    background-color: var(--color-neutral-300);
    margin-top: -2px;
    flex: 1;
  }

  .timeline-item.completed .marker-line {
    background-color: var(--color-success-600);
  }

  .timeline-details {
    flex: 1;
    padding-bottom: var(--space-4);
  }

  .timeline-title {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
    display: flex;
    align-items: center;
    gap: var(--space-2);
  }

  .completed-icon {
    color: var(--color-success-600);
  }

  .timeline-description {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
    line-height: 1.5;
  }

  /* Team Section */
  .team-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: var(--space-6);
  }

  .team-member {
    display: flex;
    gap: var(--space-4);
    align-items: flex-start;
  }

  .member-role {
    font-size: 0.875rem;
    color: var(--color-primary-600);
    font-weight: 500;
    margin-bottom: var(--space-2);
  }

  /* Comments Section */
  .comment-form {
    margin-bottom: var(--space-6);
    padding-bottom: var(--space-6);
    border-bottom: 1px solid var(--border-color);
  }

  .comment-form textarea {
    width: 100%;
    margin-bottom: var(--space-3);
    resize: vertical;
    min-height: 80px;
  }

  .donation-required-prompt {
    display: flex;
    align-items: flex-start;
    gap: var(--space-4);
    background-color: var(--color-warning-50);
    border: 1px solid var(--color-warning-200);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    margin-bottom: var(--space-6);
  }

  .prompt-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 48px;
    height: 48px;
    background-color: var(--color-warning-100);
    color: var(--color-warning-600);
    border-radius: var(--radius-lg);
    flex-shrink: 0;
  }

  .prompt-content {
    flex: 1;
  }

  .prompt-content h3 {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-2) 0;
    color: var(--color-warning-800);
  }

  .prompt-content p {
    color: var(--color-warning-700);
    margin: 0 0 var(--space-4) 0;
    line-height: 1.5;
  }

  .checking-donation {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    padding: var(--space-4);
    background-color: var(--color-neutral-50);
    border-radius: var(--radius-md);
    margin-bottom: var(--space-6);
  }

  .checking-donation p {
    color: var(--text-muted);
    margin: 0;
  }

  .auth-prompt {
    text-align: center;
    padding: var(--space-6);
    background-color: var(--color-neutral-50);
    border-radius: var(--radius-md);
    margin-bottom: var(--space-6);
  }

  .auth-prompt a {
    color: var(--color-primary-600);
    text-decoration: none;
  }

  .auth-prompt a:hover {
    text-decoration: underline;
  }

  .comments-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .comment {
    border-bottom: 1px solid var(--border-color);
    padding-bottom: var(--space-4);
  }

  .comment:last-child {
    border-bottom: none;
    padding-bottom: 0;
  }

  .comment-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-2);
  }

  .comment-author {
    display: flex;
    align-items: center;
    gap: var(--space-2);
  }

  .comment-avatar {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    object-fit: cover;
  }

  .comment-avatar-placeholder {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background-color: var(--color-neutral-200);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    color: var(--color-neutral-600);
  }

  .comment-username {
    font-weight: 500;
  }

  .comment-date {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .comment-content p {
    margin: 0;
    line-height: 1.5;
  }

  .empty-comments {
    text-align: center;
    padding: var(--space-8);
    color: var(--text-muted);
  }

  /* Info Panel */
  .piece-info-panel {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .info-card, .edit-card {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    border: 1px solid var(--border-color);
    overflow: hidden;
  }

  .funding-info {
    padding: var(--space-6);
    text-align: center;
    border-bottom: 1px solid var(--border-color);
  }

  .funding-amount {
    font-size: 2.5rem;
    font-weight: 700;
    color: var(--text-color);
    margin-bottom: var(--space-1);
    font-family: var(--font-instrument-serif);
  }

  .funding-goal {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-bottom: var(--space-4);
  }

  .progress-container {
    height: 8px;
    background-color: var(--color-neutral-100);
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: var(--space-4);
  }

  .progress-bar {
    height: 100%;
    background-color: var(--color-success-600);
    border-radius: 4px;
    transition: width 0.3s ease;
  }

  .countdown {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .countdown-number {
    font-weight: 600;
    color: var(--text-color);
  }

  .action-buttons {
    padding: var(--space-4);
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .action-button {
    width: 100%;
    padding: var(--space-3);
    border-radius: var(--radius-md);
    font-weight: 500;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s;
  }

  .action-button.primary {
    background: var(--color-primary-600);
    color: white;
    border: none;
  }

  .action-button.primary:hover {
    background: var(--color-success-600);
  }

  .action-button.secondary {
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    text-decoration: none;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
  }

  .action-button.secondary:hover {
    background-color: var(--bg-color);
  }

  .action-button.secondary:disabled,
  .action-button.secondary.disabled {
    cursor: not-allowed;
    opacity: 0.7;
  }

  .view-artwork-button {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
    border-color: var(--color-success-200);
  }

  .view-artwork-button:hover:not(.disabled) {
    background-color: var(--color-success-200);
    color: var(--color-success-800);
  }

  .view-artwork-button.disabled {
    background-color: var(--color-neutral-100);
    color: var(--color-neutral-500);
    border-color: var(--color-neutral-200);
    pointer-events: none;
  }

  .minor-actions {
    display: flex;
    gap: var(--space-2);
  }

  .minor-action-button {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-2);
    background: var(--bg-color);
    color: var(--text-muted);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .minor-action-button:hover {
    background: var(--bg-color);
    color: var(--text-color);
  }

  .minor-action-button.active {
    color: var(--color-primary-600);
    border-color: var(--color-primary-300);
    background: var(--bg-color);
  }

  .donation-summary {
    padding: var(--space-4);
    border-top: 1px solid var(--border-color);
    text-align: center;
  }

  .donation-amount {
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--text-color);
    margin-bottom: var(--space-1);
    font-family: var(--font-instrument-serif);
  }

  .donation-cause {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-bottom: var(--space-3);
  }

  .cause-button {
    width: 100%;
    padding: var(--space-2);
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .cause-button:hover {
    background: var(--bg-color);
  }

  .edit-card {
    padding: var(--space-4);
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .edit-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3);
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    text-decoration: none;
    font-weight: 500;
    transition: all 0.2s;
  }

  .edit-button:hover {
    background: var(--bg-color);
  }

  /* Responsive Adjustments */
  @media (max-width: 1024px) {
    .piece-layout {
      grid-template-columns: 1fr 300px;
    }
  }

  @media (max-width: 768px) {
    .piece-layout {
      grid-template-columns: 1fr;
    }

    .team-grid {
      grid-template-columns: 1fr;
    }

    .team-member {
      flex-direction: column;
      align-items: center;
      text-align: center;
    }

    .member-avatar {
      margin-bottom: var(--space-3);
    }
  }

  @media (max-width: 480px) {
    .piece-title {
      font-size: 1.75rem;
    }

    .section-title {
      font-size: 1.5rem;
    }

    .funding-amount {
      font-size: 2rem;
    }

    .minor-actions {
      flex-direction: column;
    }
  }
</style>