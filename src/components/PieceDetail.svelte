<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import { products } from '../stripe-config';
  import DonateButton from './DonateButton.svelte'; // Import DonateButton
  import DonationModal from './DonationModal.svelte'; // Import DonationModal
  
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
  let organizer: any = null;
  let showDonationModal = false;
  
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

      const { data: orgData, error: orgError } = await supabase
        .from('organizers')
        .select('*')
        .eq('id', piece.organizer_id)
        .single();

      if (orgError) throw orgError;

      organizer = orgData;

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

  // Handle share button click
  function handleShare() {
    if (!piece) return;
    
    const shareData = {
      title: piece.title,
      text: `Check out this piece: ${piece.title}`,
      url: `${window.location.origin}/piece/${piece.id}`
    };
    
    if (navigator.share) {
      navigator.share(shareData)
        .then(() => console.log('Share successful'))
        .catch((error) => console.error('Error sharing:', error));
    } else {
      // Popup for non-supporting browsers

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

  function decimalAdjust(type: any, value: number, exp: number) {
    type = String(type);
    if (!["round", "floor", "ceil"].includes(type)) {
      throw new TypeError(
        "The type of decimal adjustment must be one of 'round', 'floor', or 'ceil'.",
      );
    }
    exp = Number(exp);
    value = Number(value);
    if (exp % 1 !== 0 || Number.isNaN(value)) {
      return NaN;
    } else if (exp === 0) {
      return Math[type](value);
    }
    const [magnitude, exponent = 0] = value.toString().split("e");
    const adjustedValue = Math[type](`${magnitude}e${exponent - exp}`);
    // Shift back
    const [newMagnitude, newExponent = 0] = adjustedValue.toString().split("e");
    return Number(`${newMagnitude}e${Number(newExponent) + exp}`);
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
              <a href="/manage/{piece.id}" use:link class="edit-button">
                <svg width="15" height="16" viewBox="0 0 15 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M6.57943 16C6.37417 16 6.19582 15.9322 6.04439 15.7967C5.89295 15.661 5.79909 15.4917 5.76282 15.2889L5.52969 13.4291C5.24731 13.3436 4.94193 13.2091 4.61354 13.0256C4.28516 12.8421 4.00588 12.6456 3.7757 12.436L2.08098 13.1676C1.89386 13.2507 1.70386 13.2598 1.51099 13.1949C1.31812 13.1299 1.16955 13.0067 1.0653 12.8256L0.110669 11.1744C0.00641779 10.9933 -0.0241793 10.8041 0.018878 10.6069C0.0619352 10.4097 0.164565 10.2479 0.326767 10.1213L1.80538 9.01022C1.77928 8.84963 1.75776 8.68415 1.7408 8.51378C1.72369 8.34341 1.71514 8.17785 1.71514 8.01711C1.71514 7.86778 1.72369 7.71081 1.7408 7.54622C1.75776 7.38148 1.77928 7.196 1.80538 6.98978L0.326767 5.87867C0.164565 5.75215 0.0647367 5.58748 0.0272828 5.38467C-0.0100237 5.18185 0.0234491 4.98978 0.127701 4.80844L1.0653 3.20844C1.16955 3.03867 1.31812 2.91845 1.51099 2.84778C1.70386 2.77711 1.89386 2.78341 2.08098 2.86667L3.75866 3.58111C4.02291 3.36007 4.30875 3.16067 4.6162 2.98289C4.9235 2.80511 5.22232 2.66778 5.51266 2.57089L5.76282 0.711111C5.79909 0.508296 5.89295 0.339038 6.04439 0.203334C6.19582 0.0677783 6.37417 0 6.57943 0H8.42057C8.62583 0 8.80418 0.0677783 8.95562 0.203334C9.10705 0.339038 9.20091 0.508296 9.23718 0.711111L9.47031 2.588C9.80946 2.7077 10.1092 2.84504 10.3694 3C10.6297 3.15496 10.8977 3.34867 11.1734 3.58111L12.9361 2.86667C13.1232 2.78341 13.3132 2.77711 13.506 2.84778C13.6989 2.91845 13.8475 3.03867 13.9517 3.20844L14.8893 4.82556C14.9936 5.00674 15.0242 5.19593 14.9811 5.39311C14.9381 5.5903 14.8354 5.75215 14.6732 5.87867L13.1265 7.04111C13.1753 7.22452 13.2026 7.39289 13.2083 7.54622C13.2139 7.69941 13.2167 7.85067 13.2167 8C13.2167 8.13793 13.2111 8.28348 13.1997 8.43667C13.1883 8.59 13.1622 8.77548 13.1214 8.99311L14.6171 10.1213C14.7793 10.2479 14.8848 10.4097 14.9336 10.6069C14.9822 10.8041 14.9544 10.9933 14.8502 11.1744L13.9075 12.8084C13.8032 12.9898 13.6518 13.1129 13.4532 13.1778C13.2547 13.2427 13.0619 13.2336 12.8748 13.1504L11.1734 12.4189C10.8977 12.6513 10.6203 12.8507 10.3413 13.0171C10.0623 13.1835 9.77201 13.3151 9.47031 13.412L9.23718 15.2889C9.20091 15.4917 9.10705 15.661 8.95562 15.7967C8.80418 15.9322 8.62583 16 8.42057 16H6.57943ZM6.61526 15.1111H8.34559L8.67228 12.7042C9.11804 12.5857 9.51927 12.423 9.87596 12.2162C10.2328 12.0094 10.5961 11.7259 10.9657 11.3658L13.1725 12.3111L14.0521 10.8L12.1159 9.33845C12.1896 9.08541 12.2384 8.85267 12.2623 8.64022C12.2861 8.42763 12.2979 8.21422 12.2979 8C12.2979 7.77437 12.2861 7.56096 12.2623 7.35978C12.2384 7.15874 12.1896 6.93741 12.1159 6.69578L14.0862 5.2L13.2066 3.68889L10.9487 4.63933C10.6811 4.34422 10.3292 4.06756 9.89299 3.80933C9.45697 3.55126 9.04438 3.38007 8.65525 3.29578L8.38474 0.888889H6.62035L6.34475 3.27867C5.89899 3.37437 5.48921 3.52852 5.11541 3.74111C4.74176 3.95355 4.37002 4.24556 4.0002 4.61711L1.79344 3.68889L0.91379 5.2L2.83301 6.63933C2.75928 6.83874 2.70767 7.05526 2.67818 7.28889C2.64869 7.52252 2.63394 7.76526 2.63394 8.01711C2.63394 8.24274 2.64869 8.46667 2.67818 8.68889C2.70767 8.91111 2.7536 9.12763 2.81598 9.33845L0.91379 10.8L1.79344 12.3111L3.98317 11.3778C4.33028 11.7299 4.69066 12.0123 5.06432 12.2249C5.43812 12.4373 5.85925 12.6028 6.32772 12.7213L6.61526 15.1111ZM7.47611 10.2222C8.09322 10.2222 8.61617 10.0068 9.04497 9.576C9.47363 9.14533 9.68796 8.62 9.68796 8C9.68796 7.38 9.47363 6.85467 9.04497 6.424C8.61617 5.99319 8.09322 5.77778 7.47611 5.77778C6.85576 5.77778 6.332 5.99319 5.90482 6.424C5.47778 6.85467 5.26427 7.38 5.26427 8C5.26427 8.62 5.47778 9.14533 5.90482 9.576C6.332 10.0068 6.85576 10.2222 7.47611 10.2222Z" fill="currentColor"/>
                </svg>
                Manage
              </a>
              <a href="/update/{piece.id}" use:link class="edit-button">
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
                Details
              </a>
              
              <a href="/edit/{piece.id}" use:link class="edit-button">
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M15 10l4.553-2.276A1 1 0 0 1 21 8.618v6.764a1 1 0 0 1-1.447.894L15 14M5 18h8a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2z"></path>
                </svg>
                Media
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
            {/if}
          </div>

          <div class="piece-meta">
            <div class="organizer">
              {#if organizer && organizer.avatar_url}
                <div class="organizer-avatar">
                  <img src={organizer.avatar_url} alt={organizer.name} />
                </div>
              {/if}
              <div class="organizer-info" in:fly={{ y: 20, duration: 300, delay: 200 }}>
                <div class="organizer-info-header">
                  <span>Organized by</span>
                  <span class="organizer-name">{organizer.name}</span>
                </div>
                {#if organizer && organizer.description}
                <p class="organizer-desc">{ organizer.description }</p>
                {/if}
              </div>
            </div>

            <!-- Sponsors -->
            <div class="sponsors-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
                <h3>Proudly Supported by</h3>
                <div class="sponsors-list">
                    <div class="sponsor-card">
                      <div class="sponsor-logo">
                        <img src="/logo.svg" alt="Peace Piece" />
                      </div>
                      <div class="sponsor-info">
                        <h4 class="sponsor-name">Peace Piece</h4>
                        <span class="sponsor-amount">Contributing $500</span>
                        <p class="sponsor-description">Proudly sponsoring peace since 2025.</p>
                      </div>
                    </div>
                </div>
              </div>
          </div>
          
          <!-- Mission -->
          {#if piece.mission && piece.mission.trim() !== '' && piece.mission.trim() !== '<p></p>'}
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
                  <p>
                    {#if piece.collaboration_structure == "collaborative"}
                      This piece is open for collaborative contributions from the community.
                    {:else if piece.collaboration_structure == "interwoven"}
                      This piece is interwoven and requires each artist to contribute.
                    {/if}
                  </p>
                </div>
              {/if}
              
              {#if piece.deliverable_format}
                <div class="detail-group">
                  <h3>Deliverable Format</h3>
                  <p>
                    {#if piece.deliverable_format == 'image_with_audio'}
                      This piece will be delivered as an image with accompanying audio.
                    {:else if piece.deliverable_format == 'video'}
                      This piece will be delivered as a video.
                    {:else}
                      The deliverable format for this piece is not yet specified.
                    {/if}
                  </p>
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
                    <div class="timeline-date">
                      {#if milestone.due_date}
                        <span>
                          {new Date(milestone.due_date).toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric'
                          })}
                        </span>
                      {/if}
                    </div>
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
                      <p class="contributor-bio">{contributor.bio}</p>
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          {/if}

        </div>
        
        <!-- Right Column -->
        <div class="content-right">
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
          
          <!-- Funding Progress -->
          <div class="funding-progress" in:fly={{ y: 20, duration: 300, delay: 200 }}>
            <div class="funding-header">
              <h3>Funding Progress</h3>
              <span class="total-raised"><span class="dollar-sign">$</span>{piece.amount_raised || 0}</span>
              <div class="funding-amounts">
                {#if piece.funding_goal}
                <span class="amount-separator">raised of</span>
                <span class="funding-goal">{formatAmount(piece.funding_goal)} goal</span>
                {:else}
                  <span class="amount-separator">raised</span>
                {/if}
              </div>
            </div>            
            
            <div class="progress-bar">
              <div 
                class="artist-goal-fill" 
                style="width: {decimalAdjust("round", piece.artist_fees / piece.funding_goal, -2) * 100}%"
              ></div>
              <div 
                class="progress-fill" 
                style="width: {calculateProgress(piece.amount_raised || 0, piece.funding_goal || 100)}%"
              ></div>
            </div>

            {#if piece.artist_fees}
            <div class="progress-bar-legend">
              <div
                class="artist-goal-legend">
                <span class="legend-label">Artist Fees</span>
              </div>
            </div>
            {/if}

            <div class="countdown">
              {#if piece.publication_target_date}
                <span class="countdown-value">
                  {
                    Math.max(
                      Math.ceil(
                        (new Date(piece.publication_target_date).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24)
                      ),
                      0
                    )
                  }
                </span>
                <span class="countdown-label">days until kickoff</span>
              {:else}
                <span class="countdown-value">Ongoing</span>
              {/if}
            </div>
            
            <div class="funding-actions">
              <!-- <button 
                class="donate-button neumorphic" 
                on:click={() => showDonationModal = true}
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
              </button> -->
              <DonateButton 
                pieceId={piece.id} 
                pieceName={piece.title}
                buttonText="Donate to Support"
              />
              
              {#if checkoutError}
                <div class="checkout-error">
                  {checkoutError}
                </div>
              {/if}
            </div>
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
              <a href="/apply/{piece.id}" use:link class="apply-button neumorphic">
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                  <circle cx="8.5" cy="7" r="4"></circle>
                  <line x1="20" y1="8" x2="20" y2="14"></line>
                  <line x1="23" y1="11" x2="17" y2="11"></line>
                </svg>
                Apply as Artist
              </a>
            {/if}

            <div class="two-column-btns">
              <!-- Follow Button -->
              <button 
                class="follow-button neumorphic" 
                class:following={isFollowing}
                on:click={toggleFollow}
              >
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill={isFollowing ? "currentColor" : "none"}>
                  <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" stroke="currentColor"></path>
                </svg>
                {isFollowing ? 'Saved' : 'Save'}
              </button>
              <!-- Follow Button -->
              <button 
                class="share-button neumorphic" 
                on:click={handleShare}
              >
                <svg width="19" height="14" viewBox="0 0 19 14" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path d="M17.127 5.99976L13.0693 1.94201C12.9141 1.78684 12.8365 1.60867 12.8365 1.40751C12.8365 1.20617 12.9141 1.02792 13.0693 0.872758C13.2244 0.727925 13.4042 0.657091 13.6087 0.660258C13.8131 0.663591 13.9845 0.734425 14.123 0.872758L18.6173 5.36701C18.7109 5.46067 18.7769 5.55942 18.8153 5.66326C18.8538 5.76709 18.873 5.87926 18.873 5.99976C18.873 6.12026 18.8538 6.23242 18.8153 6.33626C18.7769 6.44009 18.7109 6.53884 18.6173 6.63251L14.123 11.1268C13.9678 11.2818 13.7922 11.3568 13.5962 11.3518C13.4001 11.3466 13.2244 11.2716 13.0693 11.1268C12.9141 10.9716 12.8356 10.7943 12.8337 10.595C12.8317 10.3957 12.9051 10.2216 13.0538 10.0728L17.127 5.99976ZM11.8193 6.74976H5C4.1025 6.74976 3.3365 7.06709 2.702 7.70176C2.06733 8.33626 1.75 9.10226 1.75 9.99976V12.7498C1.75 12.9626 1.67817 13.1408 1.5345 13.2843C1.391 13.4279 1.21283 13.4998 1 13.4998C0.787167 13.4998 0.609 13.4279 0.4655 13.2843C0.321833 13.1408 0.25 12.9626 0.25 12.7498V9.99976C0.25 8.68693 0.7135 7.56709 1.6405 6.64026C2.56733 5.71326 3.68717 5.24976 5 5.24976H11.8193L8.5115 1.94201C8.3565 1.78684 8.279 1.60867 8.279 1.40751C8.279 1.20617 8.3565 1.02792 8.5115 0.872758C8.66667 0.727925 8.8465 0.657091 9.051 0.660258C9.2555 0.663591 9.427 0.734425 9.5655 0.872758L14.0595 5.36701C14.1532 5.46067 14.2193 5.55942 14.2578 5.66326C14.2963 5.76709 14.3155 5.87926 14.3155 5.99976C14.3155 6.12026 14.2963 6.23242 14.2578 6.33626C14.2193 6.44009 14.1532 6.53884 14.0595 6.63251L9.5655 11.1268C9.41033 11.2818 9.23467 11.3568 9.0385 11.3518C8.84233 11.3466 8.66667 11.2716 8.5115 11.1268C8.3565 10.9716 8.278 10.7943 8.276 10.595C8.274 10.3957 8.34742 10.2216 8.49625 10.0728L11.8193 6.74976Z" fill="currentColor"/>
                </svg>
                Share
              </button>
            </div>
          </div>
        </div>
      </div>
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

  :global(.dark-mode) .progress-bar {
    background: #1F222F;
    box-shadow: inset 1px 2px 8px rgba(0, 0, 0, 0.8), inset 0 -1px 8px rgba(0, 0, 0, 0.7);
    overflow: hidden;
  }

  :global(.light-mode) .progress-bar {
    background: #F9F9FE;
    box-shadow: inset 0 2px 8px rgba(0, 0, 0, 0.2), inset 0 -1px 8px rgba(0, 0, 0, 0.08);
    overflow: hidden;
  }

  :global(.dark-mode) .cause-tag {
    background: var(--color-primary-600);
    color: var(--text-color);
  }

  :global(.light-mode) .cause-tag {
    background: var(--color-primary-200);
    color: var(--text-color);
  }

  .piece-detail {
    padding: var(--space-6);
    max-width: 1200px;
    margin: 0 auto;
  }

  .piece-detail .timeline-section {
    background: transparent;
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
    gap: 10px;
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
    align-items: center;
    gap: var(--space-6);
    min-height: 43px;
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
    gap: var(--space-4);
    color: var(--text-muted);
  }

  .organizer-avatar {
    width: 35px;
    height: 45px;
    overflow: hidden;
    border-radius: 100px;
    border: solid 2px var(--color-neutral-800);
    filter: drop-shadow(2px 4px 6px rgba(0, 0, 0, .1));
  }

  .organizer-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .organizer-info-header {
    display: flex;
    gap: .3rem;
  }

  .organizer-name {
    font-weight: 500;
    color: var(--text-color);
    text-decoration: none;
  }

  .organizer-desc {
    margin-bottom: 0px;
    font-size: .8rem;
  }

  .organizer-name:hover {
    text-decoration: underline;
  }

  .piece-stats {
    display: flex;
    gap: var(--space-4);
    justify-content: center;
    margin: 1.5rem 0;
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
    justify-content: center;
    height: 43px;
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
    background: var(--card-bg);
    color: var(--text-color);
    border: none;
    cursor: pointer;
    border-radius: 100px 42px 42px 100px !important;
  }

  .follow-button:hover,
  .follow-button:visited,
  .follow-button:focus {
    background: var(--card-bg);
  }

  .follow-button.following {
    background: var(--card-bg);
  }

  .share-button,
  .share-button:hover,
  .share-button:visited,
  .share-button:focus {
    background: var(--card-bg);
    color: var(--text-color);
    border: none;
    border-radius: 42px 100px 100px 42px !important;
  }

  .artist-goal-legend {
    margin-top: .75rem;
    padding-left: 16px;
    position: relative;
  }

  .artist-goal-legend::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 10px;
    height: 10px;
    background-color: var(--color-warning-500);
    border-radius: 50%;
    opacity: .3;
    overflow: hidden;
    box-shadow: inset 0 -2px 3px rgba(0, 0, 0, 0.15);
  }

  :global(.dark-mode) .artist-goal-legend::before {
    background: var(--color-warning-400);
  }

  :global(.light-mode) .artist-goal-legend::before {
    background: var(--color-warning-500);
  }

  .legend-label {
    color: var(--text-muted);
    font-size: 0.875rem;    
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
    font-size: 30px !important;
    font-family: var(--font-instrument-serif);
  }

  .content-left,
  .content-right {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .content-right  .piece-introduction {
    display: none;
  }

  .content-left > * {
    position: relative;
    z-index: 1;
  } 

  .content-right {
    padding-top: 100px;
    isolation: isolate;
  }

  .two-column-btns {
    display: flex;
    gap: 18px;
    margin: 0px auto;
    width: 100%;
    justify-content: center;
  }

  .two-column-btns button.neumorphic {
    flex: 1;
  }

  /* Image Section */
  .piece-image-container {
    width: 100%;
  }

  .piece-image {
    position: relative;
    width: 100%;
    border-radius: var(--radius-creative);
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
    background: var(--text-color);
    color: var(--bg-color);
    border: none;
    padding: var(--space-3) var(--space-6);
    border-radius: var(--radius-md);
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
    width: 100%;
  }

  .donate-button:hover {
    background: var(--text-color);
  }

  .donate-button:disabled {
    background: var(--text-muted);
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
    font-weight: 500;
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
    font-weight: 500;
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
    background: var(--text-color);
    color: var(--bg-color);
    border: none;
    padding: var(--space-2) var(--space-4);
    text-decoration: none;
    font-weight: 500;
    width: 100%;
    margin: .5rem auto 2.5rem;
    text-align: center;
    justify-content: center;
    min-height: 43px;
  }

  /* Funding Progress */
  .funding-progress {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-xl);
    padding: var(--space-8) var(--space-6);
    display: flex;
    flex-direction: column;
    gap: 0px;
    position: relative;
  }

  :global(.light-mode) .funding-progress:before {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: calc(100% + 150px);
    height: calc(100% + 200px);
    background: rgba(255, 255, 255, 1);
    border-radius: var(--radius-xl);
    transform: translate(-50%, -50%);
    z-index: -1;
    filter: blur(80px);
  }

  .funding-header {
    display: flex;
    justify-content: center;
    align-items: center;
    margin-bottom: var(--space-3);
    flex-direction: column;
    line-height: 1;
    margin-bottom: 1rem;
  }

  .funding-header .total-raised {
    font-family: var(--font-instrument-serif);
    font-size: 3.65rem;
    font-weight: 500;
    color: var(--text-color);
    margin-bottom: .5rem;
    display: flex;
  }

  .funding-header .total-raised .dollar-sign {
    font-size: 2.5rem;
    position: relative;
    top: .15rem;
  }

  .funding-header h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0;
    color: var(--text-color);
    display: none;
  }

  .funding-amounts {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    font-size: 0.875rem;
  }

  .amount-raised {
    font-weight: 500;
    color: var(--color-success-600);
  }

  .amount-separator {
    color: var(--text-muted);
  }

  .funding-goal {
    color: var(--text-color);
  }

  .countdown {
    text-align: center;
    font-family: var(--font-instrument-serif);
    font-size: 1.75rem;
    margin: 0 0 1rem;
  }

  .progress-bar {
    height: 18px;
    background: var(--color-neutral-100);
    border-radius: 9px;
    overflow: hidden;
    margin-bottom: 0px;
    position: relative;
  }

  .progress-bar-legend {
    margin-bottom: 1rem;
  }

  .artist-goal-fill {
    height: 100%;
    background-color: var(--color-warning-300);
    border-radius: 2px;
    transition: width 0.3s ease;
    min-width: 1%;
    z-index: 0;
    position: absolute;
    top: 0;
    left: 0;
    opacity: .3;
  }

  :global(.light-mode) .artist-goal-fill {
    background-color: var(--color-warning-500);
  } 

  :global(.dark-mode) .artist-goal-fill {
    background-color: var(--color-warning-400);
  }

  .progress-fill {
    height: 100%;
    background-color: var(--color-success-600);
    border-radius: 4px;
    transition: width 0.3s ease;
    min-width: 1%;
    position: absolute;
    z-index: 1;
    top: 0;
    left: 0;
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
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .contributors-section p.contributor-bio {
    font-size: 0.875rem;
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
    align-items: flex-start;
    gap: var(--space-3);
    padding: 20px 0 0;
    background-color: transparent;
    border-radius: 0px;
    border-top: 1px solid var(--border-color);
  }

  .contributor-avatar,
  .sponsor-logo,
  .sponsor-placeholder {
    width: 35px;
    height: 45px;
    border-radius: 100px;
    overflow: hidden;
    flex-shrink: 0;
  }

  .sponsor-logo {
    width: 35px;
    height: 35px;
    flex-shrink: 0;
  }

  .contributor-avatar img,
  .sponsor-logo img {
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
    font-weight: 500;
    font-size: 1.25rem;
  }

  .contributor-info,
  .sponsor-info {
    flex: 1;
  }

  .contributor-name,
  .sponsor-name {
    font-size: 1rem;
    font-weight: 500;
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
    font-weight: 500;
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
    border-radius: var(--radius-sm);
    font-size: 0.875rem;
    font-weight: 500;
  }

  .medium-tag {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  /* Timeline Section */
  .timeline-section h2 {
    font-size: 1.5rem;
    font-weight: 500;
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
    background: var(--color-primary-500);
    margin-top: 4px;
    overflow: hidden;
    box-shadow: inset 0 -3px 4px rgba(0, 0, 0, 0.15);
  }

  :global(.dark-mode) .marker-dot {
    background: var(--color-primary-400);
  }

  :global(.light-mode) .marker-dot {
    background: var(--color-primary-500);
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
    background: transparent;
  }

  .timeline-title {
    font-size: 1rem;
    font-weight: 500;
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

  .timeline-date span {
    position: relative;
    top: 2px;
  }

  .spinner {
    animation: spin 1s linear infinite;
  }

  @media (max-width: 1024px) {
    .piece-detail .piece-content {
      display: flex;
      flex-direction: column;
      gap: 2rem;
    }

    .piece-detail .content-left {
      order: 2;
    }

    .piece-detail .content-right {
      order: 1;
      padding-top: 10px;
    }

    .content-right  .piece-introduction {
      display: block;
    }

    .content-left  .piece-introduction {
      display: none;
    }
  }

  @media (max-width: 768px) {
    .piece-detail {
      padding: var(--space-4);
      overflow: hidden;
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

    .header-content {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-2);
      width: 100%;
      z-index: 1;
    }

    .header-actions {
      width: 100%;
      justify-content: flex-start;
    }

    .funding-header {
      flex-direction: column;
      align-items: center;
      gap: var(--space-2);
    }

    .draft-content {
      flex-direction: column;
      align-items: center;
      text-align: center;
    }
  }
</style>