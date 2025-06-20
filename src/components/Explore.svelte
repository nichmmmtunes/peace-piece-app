<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { fade, fly } from 'svelte/transition';

  let pieces: any[] = [];
  let loading = true;
  let error: string | null = null;
  let searchQuery = '';
  let selectedCategory = '';

  // Categories for filtering
  const categories = [
    'Social Cause',
    'Artistic Medium',
    'Poetry',
    'Music',
    'Visual Art',
    'Performance'
  ];

  async function loadPieces() {
    try {
      loading = true;
      error = null;

      let query = supabase
        .from('piece_details')
        .select('*')
        .order('created_at', { ascending: false });

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
    const matchesSearch = !searchQuery || 
      piece.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      piece.organizer_name.toLowerCase().includes(searchQuery.toLowerCase());
    
    return matchesSearch;
  });

  // Group pieces by sections for the wireframe layout
  $: featuredPieces = filteredPieces.slice(0, 5);
  $: categorizedPieces = {
    'Social Cause': filteredPieces.filter((_, i) => i >= 5 && i < 9),
    'Artistic Medium': filteredPieces.filter((_, i) => i >= 9 && i < 13),
    'Community Projects': filteredPieces.filter((_, i) => i >= 13)
  };

  function formatAmount(amount: number): string {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  }

  function truncateText(text: string, maxLength: number): string {
    if (!text || text.length <= maxLength) return text || '';
    return text.substring(0, maxLength) + '...';
  }

  onMount(() => {
    loadPieces();
  });
</script>

<div class="explore-container">
  <div class="explore-header">
    <div class="header-content">
      <h1>Featured Projects</h1>
      <div class="header-controls">
        <div class="search-container">
          <input 
            type="text" 
            placeholder="Search" 
            bind:value={searchQuery}
            class="search-input"
          />
          <svg class="search-icon" viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
            <circle cx="11" cy="11" r="8"></circle>
            <path d="M21 21l-4.35-4.35"></path>
          </svg>
        </div>
        
        <div class="category-filter">
          <select bind:value={selectedCategory}>
            <option value="">Causes</option>
            {#each categories as category}
              <option value={category}>{category}</option>
            {/each}
          </select>
          <svg class="dropdown-icon" viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
            <polyline points="6 9 12 15 18 9"></polyline>
          </svg>
        </div>
      </div>
    </div>
  </div>

  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading projects...</p>
    </div>
  {:else if error}
    <div class="error card" transition:fade>
      <p>Error loading projects: {error}</p>
      <button class="primary" on:click={loadPieces}>Try Again</button>
    </div>
  {:else}
    <!-- Featured Projects Section -->
    {#if featuredPieces.length > 0}
      <section class="featured-section">
        <div class="featured-grid">
          {#each featuredPieces as piece, index (piece.id)}
            <div 
              class="featured-card"
              class:large={index === 0}
              class:medium={index === 1}
              class:small={index > 1}
              in:fly={{ y: 20, duration: 300, delay: index * 100 }}
            >
              <a href="/piece/{piece.id}" use:link class="card-link">
                {#if piece.image_url}
                  <div class="card-image">
                    <img 
                      src={piece.image_url} 
                      alt={piece.title}
                      loading="lazy"
                    />
                    <div class="image-overlay">
                      <span class="view-text">View Project</span>
                    </div>
                  </div>
                {:else}
                  <div class="card-placeholder">
                    <svg xmlns="http://www.w3.org/2000/svg" width="148" height="232" viewBox="0 0 148 232" fill="none">
                    <path d="M89.2237 0C98.8319 1.92319e-07 106.621 7.79512 106.621 17.4109V42.2836C106.621 44.2067 105.063 45.7657 103.142 45.7657H77.879L90.3646 74.4694C92.5978 73.3964 94.9758 72.509 97.4896 71.8349C125.058 64.4423 151.305 87.4121 147.66 115.742L136.273 204.243C135.876 207.329 131.941 208.384 130.055 205.91L93.7795 158.319L79.7825 185.429L101.977 226.873L102.034 226.982C103.167 229.28 101.499 232 98.9106 232H49.284C46.6542 232 44.9749 229.193 46.2172 226.873L68.4119 185.429L54.3362 158.167L17.945 205.91C16.0592 208.384 12.1245 207.329 11.7273 204.243L0.340146 115.742C-3.30494 87.4121 22.9417 64.4422 50.5104 71.8349C53.0106 72.5054 55.3765 73.3869 57.5992 74.4522L70.0776 45.7657H57.9084C48.3002 45.7657 40.5111 37.9706 40.5111 28.3549V3.48218C40.5111 1.55905 42.0689 4.30754e-05 43.9905 0H89.2237Z" fill="#2B469F"/>
                    </svg>
                  </div>
                {/if}

                <div class="card-content">
                  <div class="project-status">Project Status</div>
                  <h3 class="project-title">{piece.title}</h3>
                  <p class="project-organizer">Organized by {piece.organizer_name}</p>
                  <p class="project-sponsor">Sponsored by Community</p>
                  
                  <div class="project-tags">
                    <span class="tag social-cause">Social Cause</span>
                    <span class="tag artistic-medium">Artistic Medium</span>
                  </div>
                </div>
              </a>
            </div>
          {/each}
        </div>
      </section>
    {/if}

    <!-- Categorized Sections -->
    {#each Object.entries(categorizedPieces) as [categoryName, categoryPieces]}
      {#if categoryPieces.length > 0}
        <section class="category-section">
          <h2 class="section-title">{categoryName}</h2>
          <div class="category-grid">
            {#each categoryPieces as piece, index (piece.id)}
              <div 
                class="project-card"
                in:fly={{ y: 20, duration: 300, delay: index * 50 }}
              >
                <a href="/piece/{piece.id}" use:link class="card-link">
                  {#if piece.image_url}
                    <div class="card-image">
                      <img 
                        src={piece.image_url} 
                        alt={piece.title}
                        loading="lazy"
                      />
                      <div class="image-overlay">
                        <span class="view-text">View Project</span>
                      </div>
                    </div>
                  {:else}
                    <div class="card-placeholder">
                      <svg viewBox="0 0 24 24" width="32" height="32" stroke="currentColor" stroke-width="1" fill="none">
                        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                        <circle cx="8.5" cy="8.5" r="1.5"></circle>
                        <polyline points="21,15 16,10 5,21"></polyline>
                      </svg>
                    </div>
                  {/if}

                  <div class="card-content">
                    <div class="project-status">Project Status</div>
                    <h3 class="project-title">{piece.title}</h3>
                    <p class="project-organizer">Organized by {piece.organizer_name}</p>
                    <p class="project-sponsor">Sponsored by Community</p>
                    
                    <div class="project-tags">
                      <span class="tag social-cause">Social Cause</span>
                      <span class="tag artistic-medium">Artistic Medium</span>
                    </div>
                  </div>
                </a>
              </div>
            {/each}
          </div>
        </section>
      {/if}
    {/each}

    {#if filteredPieces.length === 0}
      <div class="empty-state" transition:fade>
        {#if searchQuery}
          <p>No projects match your search for "{searchQuery}"</p>
          <button on:click={() => searchQuery = ''}>Clear search</button>
        {:else}
          <p>No projects found</p>
        {/if}
      </div>
    {/if}
  {/if}
</div>

<style>
  .explore-container {
    padding: var(--space-6);
    max-width: 1400px;
    margin: 0 auto;
  }

  .explore-header {
    margin-bottom: var(--space-8);
  }

  .header-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: var(--space-6);
  }

  .header-content h1 {
    font-weight: 600;
    margin: 0;
    color: var(--text-color);
  }

  .header-controls {
    display: flex;
    gap: var(--space-4);
    align-items: center;
  }

  .search-container {
    position: relative;
    width: 300px;
  }

  .search-input {
    width: 100%;
    padding: var(--space-3) var(--space-4);
    padding-right: var(--space-10);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    background: var(--card-bg);
    font-size: 0.875rem;
  }

  .search-icon {
    position: absolute;
    right: var(--space-3);
    top: 50%;
    transform: translateY(-50%);
    color: var(--text-muted);
  }

  .category-filter {
    position: relative;
  }

  .category-filter select {
    appearance: none;
    padding: var(--space-3) var(--space-8) var(--space-3) var(--space-4);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    background: var(--card-bg);
    font-size: 0.875rem;
    cursor: pointer;
    min-width: 120px;
  }

  .dropdown-icon {
    position: absolute;
    right: var(--space-3);
    top: 50%;
    transform: translateY(-50%);
    color: var(--text-muted);
    pointer-events: none;
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

  .error, .empty-state {
    text-align: center;
    padding: var(--space-8);
    color: var(--text-muted);
  }

  .featured-section {
    margin-bottom: var(--space-12);
  }

  .featured-grid {
    display: grid;
    grid-template-columns: 2fr 1fr 1fr 1fr 1fr;
    grid-template-rows: 1fr 1fr;
    gap: var(--space-4);
    height: 400px;
  }

  .featured-card.large {
    grid-row: 1 / 3;
  }

  .featured-card.medium {
    grid-row: 1 / 3;
    border-radius: var(--radius-md);
  }

  .featured-card.small {
    border-radius: var(--radius-md);
  }

  .featured-card {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
    border: none;
  }

  .featured-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px var(--shadow-color);
  }

  .category-section {
    margin-bottom: var(--space-10);
  }

  .section-title {
    font-size: 22px;
    font-weight: 400;
    margin-bottom: var(--space-6);
    color: var(--text-color);
  }

  .category-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: var(--space-4);
  }

  .project-card {
    background: transparent;
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
    border: 1px solid var(--border-color);
    height: 320px;
  }

  .project-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px var(--shadow-color);
  }

  .card-link {
    display: block;
    text-decoration: none;
    color: inherit;
    height: 100%;
    display: flex;
    flex-direction: column;
  }

  .card-image {
    position: relative;
    width: 100%;
    height: 60%;
    overflow: hidden;
  }

  .featured-card.large .card-image,
  .featured-card.medium .card-image {
    height: 70%;
  }

  .card-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s;
  }

  .card-link:hover .card-image img {
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

  .card-link:hover .image-overlay {
    opacity: 1;
  }

  .view-text {
    color: white;
    font-weight: 500;
    font-size: 1rem;
  }

  .card-placeholder {
    width: 100%;
    height: 60%;
    background-color: #181818;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .card-placeholder svg {
    width: 42px;
  }

  .featured-card.large .card-placeholder,
  .featured-card.medium .card-placeholder {
    height: 70%;
  }

  .card-content {
    padding: var(--space-4);
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  .project-status {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: var(--space-2);
  }

  .project-title {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0 0 var(--space-2) 0;
    line-height: 1.3;
  }

  .featured-card.large .project-title {
    font-size: 22px;
  }

  .project-organizer,
  .project-sponsor {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-1) 0;
  }

  .project-tags {
    display: flex;
    gap: var(--space-2);
    margin-top: auto;
    flex-wrap: wrap;
  }

  .tag {
    font-size: 0.75rem;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-sm);
    font-weight: 500;
  }

  .tag.social-cause {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .tag.artistic-medium {
    background-color: var(--color-accent-100);
    color: var(--color-accent-700);
  }

  @media (max-width: 1200px) {
    .featured-grid {
      grid-template-columns: 2fr 1fr 1fr;
      grid-template-rows: 1fr 1fr 1fr;
    }

    .featured-card.large {
      grid-row: 1 / 3;
    }

    .featured-card.medium {
      grid-row: 1 / 2;
    }
  }

  @media (max-width: 768px) {
    .explore-container {
      padding: var(--space-4);
    }

    .header-content {
      flex-direction: column;
      align-items: stretch;
      gap: var(--space-4);
    }

    .header-controls {
      flex-direction: column;
      gap: var(--space-3);
    }

    .search-container {
      width: 100%;
    }

    .featured-grid {
      grid-template-columns: 1fr;
      grid-template-rows: repeat(5, 200px);
      height: auto;
    }

    .featured-card.large,
    .featured-card.medium {
      grid-row: auto;
    }

    .category-grid {
      grid-template-columns: 1fr;
    }

    .project-card {
      height: 280px;
    }
  }
</style>