<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';

  let organizedPieces: any[] = [];
  let contributedPieces: any[] = [];
  let supportedPieces: any[] = [];
  let loading = true;
  let error: string | null = null;

  async function loadPieces() {
    if (!$user) return;

    try {
      loading = true;
      error = null;

      // Load pieces where user is the organizer
      const { data: organizerData } = await supabase
        .from('organizers')
        .select('id')
        .eq('user_id', $user.id);

      if (organizerData && organizerData.length > 0) {
        const organizerIds = organizerData.map(org => org.id);
        
        const { data: organizedData, error: organizedError } = await supabase
          .from('piece_details')
          .select('*')
          .in('organizer_id', organizerIds)
          .order('created_at', { ascending: false });

        if (organizedError) throw organizedError;
        organizedPieces = organizedData || [];
      }

      // Load pieces where user is a contributor (artist)
      // First get the user's profile
      const { data: profileData } = await supabase
        .from('profiles')
        .select('id')
        .eq('id', $user.id)
        .single();

      if (profileData) {
        // Check if user is in piece_artists table
        const { data: contributedData } = await supabase
          .from('piece_details')
          .select(`
            *,
            piece_artists!inner(role)
          `)
          .eq('piece_artists.artist_id', profileData.id)
          .order('created_at', { ascending: false });

        contributedPieces = contributedData || [];
      }

      // Load pieces the user has supported (donated to)
      const { data: customerData } = await supabase
        .from('stripe_customers')
        .select('customer_id')
        .eq('user_id', $user.id)
        .maybeSingle();

      if (customerData && customerData.customer_id) {
        // Get orders for this customer
        const { data: orderData } = await supabase
          .from('stripe_orders')
          .select('piece_id')
          .eq('customer_id', customerData.customer_id)
          .eq('status', 'completed')
          .is('deleted_at', null);

        if (orderData && orderData.length > 0) {
          const pieceIds = orderData.map(order => order.piece_id).filter(Boolean);
          
          if (pieceIds.length > 0) {
            const { data: supportedData } = await supabase
              .from('piece_details')
              .select('*')
              .in('id', pieceIds)
              .order('created_at', { ascending: false });

            supportedPieces = supportedData || [];
          }
        }
      }

    } catch (e: any) {
      console.error('Error loading pieces:', e);
      error = e.message;
    } finally {
      loading = false;
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

  onMount(() => {
    if ($user) {
      loadPieces();
    }
  });

  $: if ($user) {
    loadPieces();
  }
</script>

<div class="my-pieces-container">
  <div class="my-pieces-header">
    <h1>My Pieces</h1>
    <p>Manage and track your involvement in Peace Pieces</p>
  </div>

  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading your pieces...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Error Loading Pieces</h2>
        <p>{error}</p>
        <button class="primary" on:click={loadPieces}>Try Again</button>
      </div>
    </div>
  {:else}
    <!-- Organized Pieces Section -->
    <section class="pieces-section" in:fly={{ y: 20, duration: 300, delay: 100 }}>
      <div class="section-header">
        <h2>Pieces You Organize</h2>
        <a href="/create-peace" use:link class="create-button">
          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
          Create New Peace Piece
        </a>
      </div>

      {#if organizedPieces.length > 0}
        <div class="pieces-grid">
          {#each organizedPieces as piece (piece.id)}
            <div class="piece-card" in:fly={{ y: 20, duration: 300 }}>
              <a href="/piece/{piece.id}" use:link class="piece-link">
                {#if piece.image_url}
                  <div class="piece-image">
                    <img src={piece.image_url} alt={piece.title} loading="lazy" />
                    <div class="image-overlay">
                      <span class="view-text">View Details</span>
                    </div>
                  </div>
                {:else}
                  <div class="piece-placeholder">
                    <svg viewBox="0 0 24 24" width="32" height="32" stroke="currentColor" stroke-width="1" fill="none">
                      <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                      <circle cx="8.5" cy="8.5" r="1.5"></circle>
                      <polyline points="21,15 16,10 5,21"></polyline>
                    </svg>
                  </div>
                {/if}

                <div class="piece-content">
                  <div class="piece-badge organizer">Organizer</div>
                  <h3 class="piece-title">{piece.title}</h3>
                  <p class="piece-meta">Created {formatDate(piece.created_at)}</p>
                  
                  <div class="piece-stats">
                    <div class="stat">
                      <span class="stat-value">{formatAmount(piece.amount_raised)}</span>
                      <span class="stat-label">Raised</span>
                    </div>
                    <div class="stat">
                      <span class="stat-value">{piece.follower_count || 0}</span>
                      <span class="stat-label">Followers</span>
                    </div>
                  </div>
                </div>
              </a>
              
              <div class="piece-actions">
                <a href="/update/{piece.id}" use:link class="action-button edit">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                  </svg>
                  Edit
                </a>
                <a href="/edit/{piece.id}" use:link class="action-button view">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <path d="M15 10l4.553-2.276A1 1 0 0 1 21 8.618v6.764a1 1 0 0 1-1.447.894L15 14M5 18h8a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2z"></path>
                  </svg>
                  Editor
                </a>
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <div class="empty-state">
          <p>You haven't organized any pieces yet.</p>
          <a href="/create-peace" use:link class="primary">Create Your First Peace Piece</a>
        </div>
      {/if}
    </section>

    <!-- Contributed Pieces Section -->
    <section class="pieces-section" in:fly={{ y: 20, duration: 300, delay: 200 }}>
      <div class="section-header">
        <h2>Pieces You Contribute To</h2>
        <a href="/explore" use:link class="browse-button">
          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          Browse More
        </a>
      </div>

      {#if contributedPieces.length > 0}
        <div class="pieces-grid">
          {#each contributedPieces as piece (piece.id)}
            <div class="piece-card" in:fly={{ y: 20, duration: 300 }}>
              <a href="/piece/{piece.id}" use:link class="piece-link">
                {#if piece.image_url}
                  <div class="piece-image">
                    <img src={piece.image_url} alt={piece.title} loading="lazy" />
                    <div class="image-overlay">
                      <span class="view-text">View Details</span>
                    </div>
                  </div>
                {:else}
                  <div class="piece-placeholder">
                    <svg viewBox="0 0 24 24" width="32" height="32" stroke="currentColor" stroke-width="1" fill="none">
                      <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                      <circle cx="8.5" cy="8.5" r="1.5"></circle>
                      <polyline points="21,15 16,10 5,21"></polyline>
                    </svg>
                  </div>
                {/if}

                <div class="piece-content">
                  <div class="piece-badge contributor">Contributor</div>
                  <h3 class="piece-title">{piece.title}</h3>
                  <p class="piece-meta">By {piece.organizer_name}</p>
                  
                  <div class="piece-stats">
                    <div class="stat">
                      <span class="stat-value">{formatAmount(piece.amount_raised)}</span>
                      <span class="stat-label">Raised</span>
                    </div>
                    <div class="stat">
                      <span class="stat-value">{piece.follower_count || 0}</span>
                      <span class="stat-label">Followers</span>
                    </div>
                  </div>
                </div>
              </a>
            </div>
          {/each}
        </div>
      {:else}
        <div class="empty-state">
          <p>You're not contributing to any pieces yet.</p>
          <a href="/explore" use:link class="primary">Explore Pieces to Contribute</a>
        </div>
      {/if}
    </section>

    <!-- Supported Pieces Section -->
    <section class="pieces-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
      <div class="section-header">
        <h2>Pieces You've Supported</h2>
        <a href="/explore" use:link class="browse-button">
          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          Discover More
        </a>
      </div>

      {#if supportedPieces.length > 0}
        <div class="pieces-grid">
          {#each supportedPieces as piece (piece.id)}
            <div class="piece-card" in:fly={{ y: 20, duration: 300 }}>
              <a href="/piece/{piece.id}" use:link class="piece-link">
                {#if piece.image_url}
                  <div class="piece-image">
                    <img src={piece.image_url} alt={piece.title} loading="lazy" />
                    <div class="image-overlay">
                      <span class="view-text">View Details</span>
                    </div>
                  </div>
                {:else}
                  <div class="piece-placeholder">
                    <svg viewBox="0 0 24 24" width="32" height="32" stroke="currentColor" stroke-width="1" fill="none">
                      <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                      <circle cx="8.5" cy="8.5" r="1.5"></circle>
                      <polyline points="21,15 16,10 5,21"></polyline>
                    </svg>
                  </div>
                {/if}

                <div class="piece-content">
                  <div class="piece-badge supporter">Supporter</div>
                  <h3 class="piece-title">{piece.title}</h3>
                  <p class="piece-meta">By {piece.organizer_name}</p>
                  
                  <div class="piece-stats">
                    <div class="stat">
                      <span class="stat-value">{formatAmount(piece.amount_raised)}</span>
                      <span class="stat-label">Raised</span>
                    </div>
                    <div class="stat">
                      <span class="stat-value">{piece.follower_count || 0}</span>
                      <span class="stat-label">Followers</span>
                    </div>
                  </div>
                </div>
              </a>
            </div>
          {/each}
        </div>
      {:else}
        <div class="empty-state">
          <p>You haven't supported any pieces yet.</p>
          <a href="/explore" use:link class="primary">Discover Pieces to Support</a>
        </div>
      {/if}
    </section>
  {/if}
</div>

<style>
  .my-pieces-container {
    padding: var(--space-6);
    max-width: 1200px;
    margin: 0 auto 0 0;
  }

  .my-pieces-header {
    margin-bottom: var(--space-8);
  }

  .my-pieces-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .my-pieces-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
  }

  .loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 300px;
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
    min-height: 300px;
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

  .pieces-section {
    margin-bottom: var(--space-10);
  }

  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-6);
  }

  .section-header h2 {
    margin: 0;
    color: var(--text-color);
    font-family: var(--font-instrument-serif);
  }

  .create-button,
  .browse-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: 50px;
    font-weight: 500;
    text-decoration: none;
    transition: all 0.2s;
    border-color: transparent !important;
  }

  .create-button {
    background-color: var(--text-color);
    color: var(--bg-color);
    border-radius: 50px;
  }

  .create-button:hover {
    background-color: var(--text-muted);
    border-color: var(--border-color) !important;
  }

  .browse-button {
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
  }

  .browse-button:hover {
    background-color: var(--color-neutral-100);
    border-color: var(--border-color) !important;
  }

  .pieces-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: var(--space-6);
  }

  .piece-card {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
    display: flex;
    flex-direction: column;
    border-radius: var(--radius-creative);
  }

  :global(.light-mode) .piece-card {
    background: var(--bg-color);
  } 

  .piece-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px var(--shadow-color);
  }

  .piece-link {
    display: block;
    text-decoration: none;
    color: inherit;
    flex: 1;
  }

  .piece-image {
    position: relative;
    width: 100%;
    height: 180px;
    overflow: hidden;
  }

  .piece-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s;
  }

  .piece-card:hover .piece-image img {
    transform: scale(1.05);
  }

  .image-overlay {
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

  .piece-card:hover .image-overlay {
    opacity: 1;
  }

  .view-text {
    color: white;
    font-weight: 500;
  }

  .piece-placeholder {
    width: 100%;
    height: 180px;
    background-color: var(--color-neutral-100);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .piece-content {
    padding: var(--space-4);
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  .piece-badge {
    display: inline-block;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-sm);
    font-size: 0.75rem;
    font-weight: 500;
    margin-bottom: var(--space-2);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .piece-badge.organizer {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
    width: fit-content;
  }

  .piece-badge.contributor {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
  }

  .piece-badge.supporter {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .piece-title {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    line-height: 1.3;
  }

  .piece-meta {
    color: var(--text-muted);
    font-size: 0.875rem;
    margin: 0 0 var(--space-3) 0;
  }

  .piece-stats {
    display: flex;
    justify-content: space-between;
    margin-top: auto;
    padding-top: var(--space-3);
    border-top: 1px solid var(--border-color);
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

  .piece-actions {
    display: flex;
    border-top: 1px solid var(--border-color);
  }

  .action-button {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3);
    text-decoration: none;
    font-weight: 500;
    transition: background-color 0.2s;
  }

  .action-button.edit {
    color: var(--color-primary-500);
    border-right: 1px solid var(--border-color);
  }

  .action-button.view {
    color: var(--color-accent-600);
  }

  .action-button:hover {
    background: var(--bg-color);
  }

  .empty-state {
    text-align: center;
    padding: var(--space-8);
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
  }

  :global(.light-mode) .empty-state {
    background: var(--bg-color);
  }

  .empty-state p {
    color: var(--text-muted);
    margin-bottom: var(--space-4);
  }

  @media (max-width: 768px) {
    .my-pieces-container {
      padding: var(--space-4);
    }

    .my-pieces-header h1 {
      font-size: 2rem;
    }

    .section-header {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-3);
    }

    .pieces-grid {
      grid-template-columns: 1fr;
    }
  }
</style>