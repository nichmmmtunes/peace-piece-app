<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { fade, fly } from 'svelte/transition';

  let pieces: any[] = [];
  let loading = true;
  let error: string | null = null;
  let searchQuery = '';
  let sortBy: 'newest' | 'oldest' | 'most_raised' = 'newest';

  async function loadPieces() {
    try {
      loading = true;
      error = null;

      let query = supabase
        .from('piece_details')
        .select('*')
        .eq('approved', true) // Only show approved pieces
        .neq('project_status', 'submitted_for_approval'); // Don't show pieces in review

      // Apply sorting
      switch (sortBy) {
        case 'newest':
          query = query.order('created_at', { ascending: false });
          break;
        case 'oldest':
          query = query.order('created_at', { ascending: true });
          break;
        case 'most_raised':
          query = query.order('amount_raised', { ascending: false });
          break;
      }

      const { data, error: fetchError } = await query;

      if (fetchError) throw fetchError;

      pieces = data || [];
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  $: filteredPieces = pieces.filter(piece => {
    if (!searchQuery) return true;
    return piece.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
           piece.organizer_name.toLowerCase().includes(searchQuery.toLowerCase());
  });

  function formatAmount(amount: number): string {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  }

  function truncateText(text: string, maxLength: number): string {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }

  onMount(() => {
    loadPieces();
  });

  $: if (sortBy) {
    loadPieces();
  }
</script>

<div class="browse-container">
  <div class="browse-header">
    <h1>Browse Peace Pieces</h1>
    <p>Discover amazing artworks from independent artists and support their creative journey</p>
  </div>

  <div class="browse-controls">
    <div class="search-container">
      <input 
        type="text" 
        placeholder="Search pieces or organizers..." 
        bind:value={searchQuery}
        class="search-input"
      />
      {#if searchQuery}
        <button class="clear-search" on:click={() => searchQuery = ''}>
          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>
      {/if}
    </div>

    <div class="sort-container">
      <label for="sort">Sort by:</label>
      <select id="sort" bind:value={sortBy}>
        <option value="newest">Newest</option>
        <option value="oldest">Oldest</option>
        <option value="most_raised">Most Raised</option>
      </select>
    </div>
  </div>

  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading pieces...</p>
    </div>
  {:else if error}
    <div class="error card" transition:fade>
      <p>Error loading pieces: {error}</p>
      <button class="primary" on:click={loadPieces}>Try Again</button>
    </div>
  {:else if filteredPieces.length === 0}
    <div class="empty-state card" transition:fade>
      {#if searchQuery}
        <p>No pieces match your search for "{searchQuery}"</p>
        <button on:click={() => searchQuery = ''}>Clear search</button>
      {:else}
        <p>No pieces found</p>
      {/if}
    </div>
  {:else}
    <div class="pieces-grid">
      {#each filteredPieces as piece, index (piece.id)}
        <div 
          class="piece-card card"
          in:fly={{ y: 20, duration: 300, delay: index * 50 }}
        >
          <a href="/piece/{piece.id}" use:link class="piece-link">
            {#if piece.image_url}
              <div class="piece-image-container">
                <img 
                  src={piece.image_url} 
                  alt={piece.title}
                  class="piece-image"
                  loading="lazy"
                />
                <div class="image-overlay">
                  <span class="view-text">View Details</span>
                </div>
              </div>
            {:else}
              <div class="piece-placeholder">
                <svg viewBox="0 0 24 24" width="48" height="48" stroke="currentColor" stroke-width="1" fill="none">
                  <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                  <circle cx="8.5" cy="8.5" r="1.5"></circle>
                  <polyline points="21,15 16,10 5,21"></polyline>
                </svg>
              </div>
            {/if}

            <div class="piece-content">
              <h3 class="piece-title">{piece.title}</h3>
              
              <div class="piece-meta">
                <span class="organizer">by {piece.organizer_name}</span>
                <span class="amount-raised">{formatAmount(piece.amount_raised)} raised</span>
              </div>

              {#if piece.mission}
                <p class="piece-excerpt">{truncateText(piece.mission, 120)}</p>
              {/if}

              <div class="piece-stats">
                <div class="stat">
                  <span class="stat-value">{piece.contributors?.length || 0}</span>
                  <span class="stat-label">Contributors</span>
                </div>
                <div class="stat">
                  <span class="stat-value">{piece.follower_count || 0}</span>
                  <span class="stat-label">Followers</span>
                </div>
                <div class="stat">
                  <span class="stat-value">{piece.sponsors?.length || 0}</span>
                  <span class="stat-label">Sponsors</span>
                </div>
              </div>
            </div>
          </a>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .browse-container {
    max-width: 1200px;
    margin: 2rem auto;
    padding: var(--space-4);
  }

  .browse-header {
    text-align: center;
    margin-bottom: var(--space-8);
  }

  .browse-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .browse-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
    max-width: 600px;
    margin: 0 auto;
  }

  .browse-controls {
    display: flex;
    gap: var(--space-4);
    margin-bottom: var(--space-6);
    align-items: center;
  }

  .search-container {
    position: relative;
    flex: 1;
    max-width: 400px;
  }

  .search-input {
    width: 100%;
    padding-right: var(--space-8);
  }

  .clear-search {
    position: absolute;
    right: var(--space-2);
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    padding: var(--space-1);
    display: flex;
  }

  .sort-container {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    white-space: nowrap;
  }

  .sort-container label {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .sort-container select {
    width: auto;
    min-width: 120px;
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

  .error, .empty-state {
    text-align: center;
    padding: var(--space-8);
    color: var(--text-muted);
  }

  .pieces-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: var(--space-6);
  }

  .piece-card {
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
  }

  .piece-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 16px var(--shadow-color);
  }

  .piece-link {
    display: block;
    text-decoration: none;
    color: inherit;
  }

  .piece-image-container {
    position: relative;
    width: 100%;
    height: 200px;
    overflow: hidden;
  }

  .piece-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s;
  }

  .piece-card:hover .piece-image {
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
    font-size: 1.1rem;
  }

  .piece-placeholder {
    width: 100%;
    height: 200px;
    background-color: var(--color-neutral-100);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .piece-content {
    padding: var(--space-4);
  }

  .piece-title {
    font-size: 1.25rem;
    font-weight: 600;
    margin-bottom: var(--space-2);
    line-height: 1.3;
  }

  .piece-meta {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-3);
    font-size: 0.875rem;
  }

  .organizer {
    color: var(--text-muted);
  }

  .amount-raised {
    color: var(--color-success-600);
    font-weight: 500;
  }

  .piece-excerpt {
    color: var(--text-muted);
    font-size: 0.875rem;
    line-height: 1.4;
    margin-bottom: var(--space-4);
  }

  .piece-stats {
    display: flex;
    justify-content: space-between;
    padding-top: var(--space-3);
    border-top: 1px solid var(--border-color);
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

  @media (max-width: 768px) {
    .browse-header h1 {
      font-size: 2rem;
    }

    .browse-controls {
      flex-direction: column;
      align-items: stretch;
    }

    .search-container {
      max-width: none;
    }

    .pieces-grid {
      grid-template-columns: 1fr;
      gap: var(--space-4);
    }

    .piece-meta {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-1);
    }
  }
</style>