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
      // First get the user's artist profile
      const { data: artistData, error: artistError } = await supabase
        .from('artists')
        .select('id')
        .eq('user_id', $user.id)
        .maybeSingle();

      if (artistError) {
        console.error('Error fetching artist profile:', artistError);
      }

      if (artistData) {
        // First, get all piece IDs where this artist is a contributor
        const { data: pieceArtistData, error: pieceArtistError } = await supabase
          .from('piece_artists')
          .select('piece_id, role')
          .eq('artist_id', artistData.id);

        if (pieceArtistError) {
          console.error('Error fetching piece_artists:', pieceArtistError);
        } else if (pieceArtistData && pieceArtistData.length > 0) {
          const pieceIds = pieceArtistData.map(pa => pa.piece_id);
          
          // Then get the piece details for those pieces
          const { data: contributedData, error: contributedError } = await supabase
            .from('piece_details')
            .select('*')
            .in('id', pieceIds)
            .order('created_at', { ascending: false });

          if (contributedError) {
            console.error('Error fetching contributed pieces:', contributedError);
          } else {
            contributedPieces = contributedData || [];
          }
        }
      } else {
        // If no artist profile, set contributedPieces to empty
        contributedPieces = [];
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
    <section class="pieces-section pieces-organized" in:fly={{ y: 20, duration: 300, delay: 100 }}>
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
                    <svg xmlns="http://www.w3.org/2000/svg" width="148" height="232" viewBox="0 0 148 232" fill="none" class="svelte-11o5eqm"><path d="M89.2237 0C98.8319 1.92319e-07 106.621 7.79512 106.621 17.4109V42.2836C106.621 44.2067 105.063 45.7657 103.142 45.7657H77.879L90.3646 74.4694C92.5978 73.3964 94.9758 72.509 97.4896 71.8349C125.058 64.4423 151.305 87.4121 147.66 115.742L136.273 204.243C135.876 207.329 131.941 208.384 130.055 205.91L93.7795 158.319L79.7825 185.429L101.977 226.873L102.034 226.982C103.167 229.28 101.499 232 98.9106 232H49.284C46.6542 232 44.9749 229.193 46.2172 226.873L68.4119 185.429L54.3362 158.167L17.945 205.91C16.0592 208.384 12.1245 207.329 11.7273 204.243L0.340146 115.742C-3.30494 87.4121 22.9417 64.4422 50.5104 71.8349C53.0106 72.5054 55.3765 73.3869 57.5992 74.4522L70.0776 45.7657H57.9084C48.3002 45.7657 40.5111 37.9706 40.5111 28.3549V3.48218C40.5111 1.55905 42.0689 4.30754e-05 43.9905 0H89.2237Z" fill="#2B469F"></path></svg>
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
                  Details
                </a>
                <a href="/manage/{piece.id}" use:link class="action-button manage">
                  <svg width="15" height="16" viewBox="0 0 15 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M6.57943 16C6.37417 16 6.19582 15.9322 6.04439 15.7967C5.89295 15.661 5.79909 15.4917 5.76282 15.2889L5.52969 13.4291C5.24731 13.3436 4.94193 13.2091 4.61354 13.0256C4.28516 12.8421 4.00588 12.6456 3.7757 12.436L2.08098 13.1676C1.89386 13.2507 1.70386 13.2598 1.51099 13.1949C1.31812 13.1299 1.16955 13.0067 1.0653 12.8256L0.110669 11.1744C0.00641779 10.9933 -0.0241793 10.8041 0.018878 10.6069C0.0619352 10.4097 0.164565 10.2479 0.326767 10.1213L1.80538 9.01022C1.77928 8.84963 1.75776 8.68415 1.7408 8.51378C1.72369 8.34341 1.71514 8.17785 1.71514 8.01711C1.71514 7.86778 1.72369 7.71081 1.7408 7.54622C1.75776 7.38148 1.77928 7.196 1.80538 6.98978L0.326767 5.87867C0.164565 5.75215 0.0647367 5.58748 0.0272828 5.38467C-0.0100237 5.18185 0.0234491 4.98978 0.127701 4.80844L1.0653 3.20844C1.16955 3.03867 1.31812 2.91845 1.51099 2.84778C1.70386 2.77711 1.89386 2.78341 2.08098 2.86667L3.75866 3.58111C4.02291 3.36007 4.30875 3.16067 4.6162 2.98289C4.9235 2.80511 5.22232 2.66778 5.51266 2.57089L5.76282 0.711111C5.79909 0.508296 5.89295 0.339038 6.04439 0.203334C6.19582 0.0677783 6.37417 0 6.57943 0H8.42057C8.62583 0 8.80418 0.0677783 8.95562 0.203334C9.10705 0.339038 9.20091 0.508296 9.23718 0.711111L9.47031 2.588C9.80946 2.7077 10.1092 2.84504 10.3694 3C10.6297 3.15496 10.8977 3.34867 11.1734 3.58111L12.9361 2.86667C13.1232 2.78341 13.3132 2.77711 13.506 2.84778C13.6989 2.91845 13.8475 3.03867 13.9517 3.20844L14.8893 4.82556C14.9936 5.00674 15.0242 5.19593 14.9811 5.39311C14.9381 5.5903 14.8354 5.75215 14.6732 5.87867L13.1265 7.04111C13.1753 7.22452 13.2026 7.39289 13.2083 7.54622C13.2139 7.69941 13.2167 7.85067 13.2167 8C13.2167 8.13793 13.2111 8.28348 13.1997 8.43667C13.1883 8.59 13.1622 8.77548 13.1214 8.99311L14.6171 10.1213C14.7793 10.2479 14.8848 10.4097 14.9336 10.6069C14.9822 10.8041 14.9544 10.9933 14.8502 11.1744L13.9075 12.8084C13.8032 12.9898 13.6518 13.1129 13.4532 13.1778C13.2547 13.2427 13.0619 13.2336 12.8748 13.1504L11.1734 12.4189C10.8977 12.6513 10.6203 12.8507 10.3413 13.0171C10.0623 13.1835 9.77201 13.3151 9.47031 13.412L9.23718 15.2889C9.20091 15.4917 9.10705 15.661 8.95562 15.7967C8.80418 15.9322 8.62583 16 8.42057 16H6.57943ZM6.61526 15.1111H8.34559L8.67228 12.7042C9.11804 12.5857 9.51927 12.423 9.87596 12.2162C10.2328 12.0094 10.5961 11.7259 10.9657 11.3658L13.1725 12.3111L14.0521 10.8L12.1159 9.33845C12.1896 9.08541 12.2384 8.85267 12.2623 8.64022C12.2861 8.42763 12.2979 8.21422 12.2979 8C12.2979 7.77437 12.2861 7.56096 12.2623 7.35978C12.2384 7.15874 12.1896 6.93741 12.1159 6.69578L14.0862 5.2L13.2066 3.68889L10.9487 4.63933C10.6811 4.34422 10.3292 4.06756 9.89299 3.80933C9.45697 3.55126 9.04438 3.38007 8.65525 3.29578L8.38474 0.888889H6.62035L6.34475 3.27867C5.89899 3.37437 5.48921 3.52852 5.11541 3.74111C4.74176 3.95355 4.37002 4.24556 4.0002 4.61711L1.79344 3.68889L0.91379 5.2L2.83301 6.63933C2.75928 6.83874 2.70767 7.05526 2.67818 7.28889C2.64869 7.52252 2.63394 7.76526 2.63394 8.01711C2.63394 8.24274 2.64869 8.46667 2.67818 8.68889C2.70767 8.91111 2.7536 9.12763 2.81598 9.33845L0.91379 10.8L1.79344 12.3111L3.98317 11.3778C4.33028 11.7299 4.69066 12.0123 5.06432 12.2249C5.43812 12.4373 5.85925 12.6028 6.32772 12.7213L6.61526 15.1111ZM7.47611 10.2222C8.09322 10.2222 8.61617 10.0068 9.04497 9.576C9.47363 9.14533 9.68796 8.62 9.68796 8C9.68796 7.38 9.47363 6.85467 9.04497 6.424C8.61617 5.99319 8.09322 5.77778 7.47611 5.77778C6.85576 5.77778 6.332 5.99319 5.90482 6.424C5.47778 6.85467 5.26427 7.38 5.26427 8C5.26427 8.62 5.47778 9.14533 5.90482 9.576C6.332 10.0068 6.85576 10.2222 7.47611 10.2222Z" fill="currentColor"/>
                  </svg>
                  Manage
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
    <section class="pieces-section pieces-contributing" in:fly={{ y: 20, duration: 300, delay: 200 }}>
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
                    <svg xmlns="http://www.w3.org/2000/svg" width="148" height="232" viewBox="0 0 148 232" fill="none" class="svelte-11o5eqm"><path d="M89.2237 0C98.8319 1.92319e-07 106.621 7.79512 106.621 17.4109V42.2836C106.621 44.2067 105.063 45.7657 103.142 45.7657H77.879L90.3646 74.4694C92.5978 73.3964 94.9758 72.509 97.4896 71.8349C125.058 64.4423 151.305 87.4121 147.66 115.742L136.273 204.243C135.876 207.329 131.941 208.384 130.055 205.91L93.7795 158.319L79.7825 185.429L101.977 226.873L102.034 226.982C103.167 229.28 101.499 232 98.9106 232H49.284C46.6542 232 44.9749 229.193 46.2172 226.873L68.4119 185.429L54.3362 158.167L17.945 205.91C16.0592 208.384 12.1245 207.329 11.7273 204.243L0.340146 115.742C-3.30494 87.4121 22.9417 64.4422 50.5104 71.8349C53.0106 72.5054 55.3765 73.3869 57.5992 74.4522L70.0776 45.7657H57.9084C48.3002 45.7657 40.5111 37.9706 40.5111 28.3549V3.48218C40.5111 1.55905 42.0689 4.30754e-05 43.9905 0H89.2237Z" fill="#2B469F"></path></svg>
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
    <section class="pieces-section pieces-supported" in:fly={{ y: 20, duration: 300, delay: 300 }}>
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
                    <svg xmlns="http://www.w3.org/2000/svg" width="148" height="232" viewBox="0 0 148 232" fill="none" class="svelte-11o5eqm"><path d="M89.2237 0C98.8319 1.92319e-07 106.621 7.79512 106.621 17.4109V42.2836C106.621 44.2067 105.063 45.7657 103.142 45.7657H77.879L90.3646 74.4694C92.5978 73.3964 94.9758 72.509 97.4896 71.8349C125.058 64.4423 151.305 87.4121 147.66 115.742L136.273 204.243C135.876 207.329 131.941 208.384 130.055 205.91L93.7795 158.319L79.7825 185.429L101.977 226.873L102.034 226.982C103.167 229.28 101.499 232 98.9106 232H49.284C46.6542 232 44.9749 229.193 46.2172 226.873L68.4119 185.429L54.3362 158.167L17.945 205.91C16.0592 208.384 12.1245 207.329 11.7273 204.243L0.340146 115.742C-3.30494 87.4121 22.9417 64.4422 50.5104 71.8349C53.0106 72.5054 55.3765 73.3869 57.5992 74.4522L70.0776 45.7657H57.9084C48.3002 45.7657 40.5111 37.9706 40.5111 28.3549V3.48218C40.5111 1.55905 42.0689 4.30754e-05 43.9905 0H89.2237Z" fill="#2B469F"></path></svg>
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

  .pieces-section:not(.pieces-organized) {
    padding-top: var(--space-4);
    border-top: solid 1px var(--border-color);
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
    background: var(--color-neutral-100);
  }

  :global(.dark-mode) .browse-button {
    background: var(--card-bg);
  }

  :global(.dark-mode) .browse-button:hover {
    background: #000;
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
    background: linear-gradient(45deg, var(--color-neutral-200), var(--color-primary-00));
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  :global(.dark-mode) .piece-placeholder {
    background: linear-gradient(45deg, #262626, var(--color-neutral-900));
  }

  .piece-placeholder svg {
    width: 42px;
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
    width: fit-content;
  }

  .piece-badge.supporter {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
    width: fit-content;
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
    color: var(--text-color);
    border-right: 1px solid var(--border-color);
  }

  .action-button.manage {
    color: var(--text-color);
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