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
                  Edit
                </a>
                <a href="/manage/{piece.id}" use:link class="action-button manage">
                  <svg width="22" height="24" viewBox="0 0 22 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M9.69808 23.0371C9.40808 23.0371 9.1561 22.9418 8.94214 22.7512C8.72818 22.5603 8.59558 22.3223 8.54433 22.0371L8.21495 19.4218C7.816 19.3016 7.38454 19.1124 6.92058 18.8543C6.45662 18.5964 6.06204 18.32 5.73683 18.0252L3.34245 19.054C3.07808 19.1709 2.80964 19.1837 2.53714 19.0924C2.26464 19.001 2.05474 18.8278 1.90745 18.573L0.558703 16.2512C0.411411 15.9964 0.368182 15.7303 0.429015 15.453C0.489849 15.1758 0.634849 14.9482 0.864015 14.7702L2.95308 13.2077C2.9162 12.9819 2.88579 12.7492 2.86183 12.5096C2.83766 12.27 2.82558 12.0372 2.82558 11.8112C2.82558 11.6012 2.83766 11.3804 2.86183 11.149C2.88579 10.9173 2.9162 10.6565 2.95308 10.3665L0.864015 8.80398C0.634849 8.62607 0.493807 8.39451 0.44089 8.1093C0.388182 7.82409 0.435474 7.55398 0.582765 7.29898L1.90745 5.04898C2.05474 4.81023 2.26464 4.64117 2.53714 4.5418C2.80964 4.44242 3.07808 4.45128 3.34245 4.56836L5.71277 5.57305C6.0861 5.26221 6.48995 4.9818 6.92433 4.7318C7.3585 4.4818 7.78068 4.28867 8.19089 4.15242L8.54433 1.53711C8.59558 1.2519 8.72818 1.01388 8.94214 0.823048C9.1561 0.632423 9.40808 0.537109 9.69808 0.537109H12.2993C12.5893 0.537109 12.8413 0.632423 13.0553 0.823048C13.2692 1.01388 13.4018 1.2519 13.4531 1.53711L13.7825 4.17649C14.2616 4.34482 14.6851 4.53794 15.0528 4.75586C15.4205 4.97378 15.7991 5.24617 16.1887 5.57305L18.679 4.56836C18.9434 4.45128 19.2118 4.44242 19.4843 4.5418C19.7568 4.64117 19.9667 4.81023 20.114 5.04898L21.4387 7.32305C21.586 7.57784 21.6292 7.84388 21.5684 8.12117C21.5076 8.39846 21.3626 8.62607 21.1334 8.80398L18.9481 10.4387C19.017 10.6966 19.0556 10.9334 19.0637 11.149C19.0716 11.3644 19.0756 11.5771 19.0756 11.7871C19.0756 11.9811 19.0676 12.1858 19.0515 12.4012C19.0355 12.6168 18.9986 12.8776 18.9409 13.1837L21.054 14.7702C21.2832 14.9482 21.4322 15.1758 21.5012 15.453C21.57 15.7303 21.5307 15.9964 21.3834 16.2512L20.0515 18.549C19.9042 18.804 19.6903 18.9771 19.4096 19.0684C19.1292 19.1596 18.8568 19.1468 18.5925 19.0299L16.1887 18.0012C15.7991 18.328 15.4072 18.6085 15.0131 18.8424C14.6189 19.0764 14.2087 19.2615 13.7825 19.3977L13.4531 22.0371C13.4018 22.3223 13.2692 22.5603 13.0553 22.7512C12.8413 22.9418 12.5893 23.0371 12.2993 23.0371H9.69808ZM9.7487 21.7871H12.1934L12.655 18.4024C13.2847 18.2358 13.8516 18.007 14.3556 17.7162C14.8597 17.4253 15.373 17.0267 15.8953 16.5202L19.0131 17.8496L20.2559 15.7246L17.5203 13.6693C17.6244 13.3135 17.6934 12.9862 17.7271 12.6874C17.7607 12.3885 17.7775 12.0884 17.7775 11.7871C17.7775 11.4698 17.7607 11.1697 17.7271 10.8868C17.6934 10.6041 17.6244 10.2928 17.5203 9.95305L20.304 7.84961L19.0612 5.72461L15.8712 7.06117C15.4931 6.64617 14.9959 6.25711 14.3796 5.89398C13.7636 5.53107 13.1807 5.29034 12.6309 5.1718L12.2487 1.78711H9.75589L9.36652 5.14773C8.73672 5.28232 8.15777 5.49909 7.62964 5.79805C7.10172 6.0968 6.57652 6.50742 6.05402 7.02992L2.9362 5.72461L1.69339 7.84961L4.40495 9.87367C4.30079 10.1541 4.22787 10.4586 4.1862 10.7871C4.14454 11.1157 4.1237 11.457 4.1237 11.8112C4.1237 12.1285 4.14454 12.4434 4.1862 12.7559C4.22787 13.0684 4.29277 13.3728 4.38089 13.6693L1.69339 15.7246L2.9362 17.8496L6.02995 16.5371C6.52037 17.0323 7.02954 17.4294 7.55745 17.7284C8.08558 18.0271 8.68058 18.2598 9.34245 18.4265L9.7487 21.7871ZM10.965 14.9121C11.8368 14.9121 12.5757 14.6092 13.1815 14.0034C13.7871 13.3977 14.09 12.659 14.09 11.7871C14.09 10.9152 13.7871 10.1765 13.1815 9.57086C12.5757 8.96503 11.8368 8.66211 10.965 8.66211C10.0885 8.66211 9.3485 8.96503 8.74495 9.57086C8.14162 10.1765 7.83995 10.9152 7.83995 11.7871C7.83995 12.659 8.14162 13.3977 8.74495 14.0034C9.3485 14.6092 10.0885 14.9121 10.965 14.9121Z" fill="currentColor"/>
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
    color: var(--color-primary-500);
    border-right: 1px solid var(--border-color);
  }

  .action-button.manage {
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