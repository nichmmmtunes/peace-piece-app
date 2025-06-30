<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';

  let pieces: any[] = [];
  let supporters: any[] = [];
  let artists: any[] = [];
  let organizers: any[] = [];
  let piecesLoading = true;
  let supportersLoading = true;
  let artistsLoading = true;
  let organizersLoading = true;
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
      piecesLoading = true;
      error = null;

      let query = supabase
        .from('piece_details')
        .select('*')
        .eq('approved', true) // Only show approved pieces
        .neq('project_status', 'submitted_for_approval') // Don't show pieces in review
        .order('created_at', { ascending: false });

      const { data, error: fetchError } = await query;

      if (fetchError) throw fetchError;

      pieces = data || [];
    } catch (e: any) {
      error = e.message;
    } finally {
      piecesLoading = false;
    }
  }

  async function loadSupporters() {
    try {
      supportersLoading = true;
      error = null;

      let query = supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });

      const { data, error: fetchError } = await query;

      if (fetchError) throw fetchError;

      supporters = data || [];
    } catch (e: any) {
      error = e.message;
    } finally {
      supportersLoading = false;
    }
  }

  async function loadArtists() {
    try {
      artistsLoading = true;
      const { data, error: fetchError } = await supabase
        .from('artists')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;

      artists = data || [];
    } catch (e: any) {
      error = e.message;
    }
    finally {
      artistsLoading = false;
    }
  }

  async function loadOrganizers() {
    try {
      organizersLoading = true;
      const { data, error: fetchError } = await supabase
        .from('organizers')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;

      organizers = data || [];
    } catch (e: any) {
      error = e.message;
    } finally {
      organizersLoading = false;
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

  // Function to get initials from a name
  function getInitials(name: string | null): string {
    if (!name) return "?";
    
    const nameParts = name.split(" ");
    if (nameParts.length > 1) {
      // Get first letter of first and last name
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
    } else {
      // If only one name, get first letter
      return name[0].toUpperCase();
    }
  }

  onMount(() => {
    loadPieces();
    loadSupporters();
    loadArtists();
    loadOrganizers();
  });
</script>

<div class="explore-container">
  <div class="explore-header">
    <div class="header-content">
      <h1>Featured</h1>
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

  {#if piecesLoading}
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
                  <div class="project-status">
                    {#if piece.project_status === 'open_to_applications'}
                      Open to Applications
                    {:else if piece.project_status === 'seeking_funding'}
                      Seeking Funding
                    {:else if piece.project_status === 'published'}
                      Published
                    {/if}
                  </div>
                  <h3 class="project-title">{piece.title}</h3>
                  <p class="project-organizer">Organized by {piece.organizer_name}</p>                  
                  <div class="project-tags">
                    {#if piece.cause_tags && piece.cause_tags.length > 0}
                      <span class="tag social-cause">{piece.cause_tags[0]}</span>
                    {:else}
                      <span class="tag social-cause">Social Cause</span>
                    {/if}
                    
                    {#if piece.accepted_mediums && piece.accepted_mediums.length > 0}
                      <span class="tag artistic-medium">{piece.accepted_mediums[0]}</span>
                    {:else}
                      <span class="tag artistic-medium">Artistic Medium</span>
                    {/if}
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
                    <div class="project-status">
                      {#if piece.project_status === 'open_to_applications'}
                        Open to Applications
                      {:else if piece.project_status === 'seeking_funding'}
                        Seeking Funding
                      {:else if piece.project_status === 'published'}
                        Published
                      {/if}
                    </div>
                    <h3 class="project-title">{piece.title}</h3>
                    <p class="project-organizer">Organized by {piece.organizer_name}</p>                    
                    <div class="project-tags">
                      {#if piece.cause_tags && piece.cause_tags.length > 0}
                        <span class="tag social-cause">{piece.cause_tags[0]}</span>
                      {:else}
                        <span class="tag social-cause">Social Cause</span>
                      {/if}
                      
                      {#if piece.accepted_mediums && piece.accepted_mediums.length > 0}
                        <span class="tag artistic-medium">{piece.accepted_mediums[0]}</span>
                      {:else}
                        <span class="tag artistic-medium">Artistic Medium</span>
                      {/if}
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

    {#if artists.length > 0}
      <section class="artists-section">
        <h2 class="section-title">Artists</h2>
        <div class="artists-grid">
          {#each artists as artist, index (artist.id)}
          {#if artist.user_id !== $user?.id && artist.artist_username}
            <div class="artist-card" in:fly={{ y: 20, duration: 300, delay: index * 50 }}>
              <a href="/artist/{artist.artist_username}" use:link class="card-link">
                {#if artist.avatar_url}
                  <img src={artist.avatar_url} alt={artist.artist_username} />
                {:else}
                  <div class="avatar-placeholder-initials">
                    {getInitials(artist.name)}
                  </div>
                {/if}
                <p>{artist.name}</p>
              </a>
            </div>
          {/if}
          {/each}
        </div>
      </section>
    {/if}

    {#if organizers.length > 0}
      <section class="organizers-section">
        <h2 class="section-title">Organizers</h2>
        <div class="organizers-grid">
          {#each organizers as organizer, index (organizer.id)}
          {#if organizer.user_id !== $user?.id && organizer.organizer_username}
            <div class="organizer-card" in:fly={{ y: 20, duration: 300, delay: index * 50 }}>
              <a href="/organizer/{organizer.organizer_username}" use:link class="card-link">
                {#if organizer.avatar_url}
                  <img src={organizer.avatar_url} alt={organizer.organizer_username} />
                {:else}
                  <div class="avatar-placeholder-initials">
                    {getInitials(organizer.name)}
                  </div>
                {/if}
                <p>{organizer.name}</p>
              </a>
            </div>
          {/if}
          {/each}
        </div>
      </section>
    {/if}

    <!-- Supporters Section -->
    {#if supporters.length > 0}
      <section class="supporters-section">
        <h2 class="section-title">Supporters</h2>
        <div class="supporters-grid">
          {#each supporters as supporter, index (supporter.id)}
          {#if supporter.id !== $user?.id}
            <div class="supporter-card" in:fly={{ y: 20, duration: 300, delay: index * 50 }}>
              <a href="/profile/{supporter.username}" use:link class="card-link">
                {#if supporter.avatar_url}
                  <img src={supporter.avatar_url} alt={supporter.username} />
                {:else}
                  <div class="avatar-placeholder-initials">
                    {getInitials(supporter.username)}
                  </div>
                {/if}
                <p>{supporter.username}</p>
              </a>
            </div>
          {/if}
          {/each}
        </div>
      </section>
    {/if}

  {/if}
</div>

<style>
  .explore-container {
    padding: var(--space-6);
    max-width: 1400px;
    margin: 0 auto 0 0;
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
    font-weight: 500;
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
    border: none;
    border-radius: var(--radius-md);
    background: var(--card-bg);
    font-size: 0.875rem;
  }

  :global(.light-mode) .search-input {
    background: var(--bg-color);
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
    border: none;
    border-radius: var(--radius-md);
    background: var(--card-bg);
    font-size: 0.875rem;
    cursor: pointer;
    min-width: 120px;
    user-select: none;
  }

  :global(.light-mode) .category-filter select {
    background: var(--bg-color);
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

  .featured-grid {
    display: flex;
    gap: var(--space-4);
    padding: var(--space-6) 0px;
  }

  .featured-grid .featured-card:nth-child(n+6) {
    display: none;
  }

  .featured-card.large:first-child {
    width: 45%;
    border-radius: var(--radius-creative);
  }

  .featured-card.medium {
    width: 15%;
    border-radius: 40px;
  }

  .featured-card.small {
    width: 15%;
    border-radius: 40px;
  }

  .featured-card {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s, width .2s;
    border: none;
  }

  :global(.light-mode) .featured-card {
    background: var(--bg-color);
  }

  .featured-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px var(--shadow-color);
  }

  .featured-card.small:hover
  .featured-card.medium:hover {
    width: 20%;
  }

  .category-section {
    margin-bottom: var(--space-10);
  }

  .section-title {
    font-size: 1.7rem;
    font-weight: 400;
    margin-bottom: var(--space-6);
    color: var(--text-color);
    font-family: var(--font-instrument-serif);
  }

  .supporters-section,
  .artists-section,
  .organizers-section {
    margin-top: var(--space-6);
  }

  .category-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: var(--space-4);
  }

  .supporters-grid,
  .artists-grid,
  .organizers-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: var(--space-4);
  }

  .project-card {
    background: transparent;
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
    border: none;
    height: 250px;
  }

  .supporter-card,
  .artist-card,
  .organizer-card {
    background: transparent;
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
    border: none;
    height: 180px;
  }

  .project-card:hover,
  .supporter-card:hover,
  .artist-card:hover,
  .organizer-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px var(--shadow-color);
  }

  .supporter-card .card-link,
  .artist-card .card-link,
  .organizer-card .card-link {
    position: relative;
  }

  .supporter-card .card-link img,
  .artist-card .card-link img,
  .organizer-card .card-link img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    user-select: none;
  }

  .avatar-placeholder-initials {
    width: 100%;
    height: 100%;
    color: white;
    background: linear-gradient(45deg, #262626, var(--color-neutral-900));
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2rem;
    font-weight: 600;
  }

  .supporter-card .card-link:after,
  .artist-card .card-link:after,
  .organizer-card .card-link:after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(transparent 50%, rgba(0, 0, 0, 0.8) calc(100% - 10px));
    z-index: 1;
  }

  .supporter-card .card-link p,
  .artist-card .card-link p,
  .organizer-card .card-link p {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    width: 100%;
    padding: var(--space-2) var(--space-4);
    z-index: 2;
    margin-bottom: 0px;
    font-weight: 400;
    color: var(--color-neutral-100);
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

  .featured-card.small .card-image,
  .featured-card.medium .card-image {
    height: 50%;
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
    background: linear-gradient(45deg, var(--color-neutral-200), var(--color-primary-00));
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .featured-card.small .card-placeholder,
  .featured-card.medium .card-placeholder {
    height: 50%;
  }

  :global(.dark-mode) .card-placeholder {
    background: linear-gradient(45deg, #262626, var(--color-neutral-900));
  }

  .card-placeholder svg {
    width: 42px;
  }

  .featured-card.large .card-placeholder {
    height: 60%;
  }

  .card-content {
    padding: var(--space-4) var(--space-4) var(--space-6);
    flex: 1;
    display: flex;
    flex-direction: column;
    user-select: none;
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
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    line-height: 1.3;
  }

  .featured-card.large .project-title {
    font-size: 20px;
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
    margin-top: .5rem;
    flex-wrap: wrap;
  }

  .tag {
    font-size: 0.75rem;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-sm);
    font-weight: 500;
  }

  .featured-card.small .tag,
  .featured-card.medium .tag {
    font-size: .7rem;
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
      flex-wrap: wrap;
    }

    .featured-card.large:first-child {
      width: 100%;
    }

    .featured-card.large:first-child .card-image {
      height: 270px;
    }

    .featured-card.medium,
    .featured-card.small {
      width: calc(50% - var(--space-2));
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
      height: auto;
    }

    .featured-card.large,
    .featured-card.medium,
    .featured-card.small {
      grid-row: auto;
      width: 100%;
    }

    .project-card {
      height: 280px;
    }
  }
</style>