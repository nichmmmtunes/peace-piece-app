<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { link, location } from 'svelte-spa-router';
  import { user, signOut } from '../stores/authStore';
  import { supabase } from '../lib/supabase';
  import { onMount, onDestroy } from 'svelte';
  import ThemeToggle from './ThemeToggle.svelte';
  
  export let collapsed = false;
  export let isOpenOnMobile = false;
  
  const dispatch = createEventDispatcher();
  
  let unreadNotifications = 0;
  let subscription: any = null;
  let collapseButton: HTMLButtonElement;
  let userProfile: any = null;
  let showProfileMenu = false;
  let profileMenuElement: HTMLElement;
  let darkMode = false;
  
  async function handleSignOut() {
    await signOut();
  }

  function toggleSidebar() {
    dispatch('toggle');
    // Unfocus the collapse button after toggling
    if (collapseButton) {
      collapseButton.blur();
    }
  }

  function toggleProfileMenu() {
    showProfileMenu = !showProfileMenu;
  }

  function closeProfileMenu() {
    showProfileMenu = false;
  }

  function toggleDarkMode() {
    darkMode = !darkMode;
    dispatch('toggleDarkMode');
  }

  function navigateToProfile() {
    if (userProfile?.username) {
      closeProfileMenu();
      // Use the link action to navigate
      window.location.hash = `/profile/${userProfile.username}`;
    }
  }

  // NEW: Function to handle navigation clicks and close mobile sidebar
  function handleNavigationClick() {
    // Close mobile sidebar when navigation item is clicked
    isOpenOnMobile = false;
  }

  // Close menu when clicking outside
  function handleClickOutside(event: MouseEvent) {
    if (showProfileMenu && profileMenuElement && !profileMenuElement.contains(event.target as Node)) {
      closeProfileMenu();
    }
  }

  async function loadUnreadCount() {
    if (!$user) return;

    try {
      const { count, error } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', $user.id)
        .eq('read', false);

      if (error) throw error;

      unreadNotifications = count || 0;
    } catch (error) {
      console.error('Error loading unread notifications count:', error);
    }
  }

  async function loadUserProfile() {
    if (!$user) return;

    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', $user.id)
        .maybeSingle();

      if (error) throw error;

      userProfile = data;
    } catch (error) {
      console.error('Error loading user profile:', error);
    }
  }

  onMount(() => {
    // Check system theme preference
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    darkMode = prefersDark;

    // Add click outside listener
    document.addEventListener('click', handleClickOutside);

    if ($user) {
      loadUnreadCount();
      loadUserProfile();

      subscription = supabase
        .channel('notification-count-sidebar')
        .on('postgres_changes', 
          { 
            event: '*', 
            schema: 'public', 
            table: 'notifications',
            filter: `user_id=eq.${$user.id}`
          }, 
          () => {
            loadUnreadCount();
          }
        )
        .subscribe();
    }
  });

  onDestroy(() => {
    document.removeEventListener('click', handleClickOutside);
    if (subscription) {
      supabase.removeChannel(subscription);
    }
  });

  $: if ($user) {
    loadUnreadCount();
    loadUserProfile();
  } else {
    unreadNotifications = 0;
    userProfile = null;
  }

  const navigationItems = [
    { path: '/dashboard', label: 'Dashboard', icon: 'dashboard' },
    { path: '/pieces', label: 'My Pieces', icon: 'pieces' },
    { path: '/explore', label: 'Explore', icon: 'explore' },
    { path: '/notifications', label: 'Updates', icon: 'notifications', badge: unreadNotifications },
    { path: '/settings', label: 'Settings', icon: 'settings' },
  ];

  const profileMenuItems = [
    { path: '/help', label: 'Help & FAQ', icon: 'help' },
    { path: '/terms', label: 'Terms of Use', icon: 'document' },
    { path: '/privacy', label: 'Privacy Policy', icon: 'shield' },
    { path: '/community', label: 'Community Policies', icon: 'users' },
  ];

  function getIcon(iconName: string) {
    const icons = {
      dashboard: `<svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        <rect x="3" y="3" width="7" height="7"></rect>
        <rect x="14" y="3" width="7" height="7"></rect>
        <rect x="14" y="14" width="7" height="7"></rect>
        <rect x="3" y="14" width="7" height="7"></rect>
      </svg>`,
      pieces: `<svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"></path>
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"></path>
      </svg>`,
      explore: `<svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        <circle cx="11" cy="11" r="8"></circle>
        <path d="M21 21l-4.35-4.35"></path>
      </svg>`,
      notifications: `<svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
        <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
      </svg>`,
      settings: `<svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        <circle cx="12" cy="12" r="3"></circle>
        <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
      </svg>`,
      help: `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <circle cx="12" cy="12" r="10"></circle>
        <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
        <line x1="12" y1="17" x2="12.01" y2="17"></line>
      </svg>`,
      document: `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
        <polyline points="14 2 14 8 20 8"></polyline>
        <line x1="16" y1="13" x2="8" y2="13"></line>
        <line x1="16" y1="17" x2="8" y2="17"></line>
        <polyline points="10 9 9 9 8 9"></polyline>
      </svg>`,
      shield: `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
      </svg>`,
      users: `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
        <circle cx="9" cy="7" r="4"></circle>
        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
      </svg>`,
      add: `<svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="12" y1="8" x2="12" y2="16"></line>
        <line x1="8" y1="12" x2="16" y2="12"></line>
      </svg>`
    };
    return icons[iconName] || '';
  }
</script>

<aside class="sidebar" class:collapsed class:mobile-open={isOpenOnMobile}>
  <div class="sidebar-header">
    <div class="logo">
      <a href="/" use:link class="logo-link" on:click={handleNavigationClick}>
        <div class="logo-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="42" height="66" viewBox="0 0 42 66" fill="none">
            <path d="M25.3202 0C28.0469 5.45346e-08 30.2573 2.21041 30.2573 4.93709V11.9901C30.2573 12.5354 29.8152 12.9775 29.2699 12.9775H22.1008L25.644 21.1168C26.2778 20.8125 26.9526 20.5609 27.666 20.3697C35.4895 18.2735 42.9379 24.7869 41.9035 32.82L38.672 57.9158C38.5593 58.7909 37.4427 59.09 36.9075 58.3885L26.6131 44.8935L22.641 52.5808L28.9396 64.3328L28.9555 64.3637C29.2771 65.0153 28.8039 65.7867 28.0692 65.7867H13.986C13.2397 65.7866 12.7632 64.9906 13.1157 64.3328L19.4142 52.5808L15.4197 44.8503L5.0925 58.3885C4.55733 59.09 3.44074 58.7909 3.32802 57.9158L0.0965279 32.82C-0.937889 24.7868 6.51049 18.2734 14.334 20.3697C15.0436 20.5599 15.715 20.8098 16.3457 21.1119L19.8869 12.9775H16.4335C13.7068 12.9775 11.4964 10.7671 11.4964 8.0404V0.987417C11.4964 0.442088 11.9385 1.22146e-05 12.4838 0H25.3202Z" fill="url(#paint0_linear_264_1443)"/>
            <defs>
              <linearGradient id="paint0_linear_264_1443" x1="21" y1="0" x2="21" y2="65.7867" gradientUnits="userSpaceOnUse">
                <stop stop-color="var(--logo-gradient-stop1)"/>
                <stop offset="1" stop-color="var(--logo-gradient-stop2)"/>
              </linearGradient>
            </defs>
          </svg>
        </div>
        {#if !collapsed}
          <span class="logo-text">Peace Piece</span>
        {/if}
      </a>
    </div>
    
    <button 
      bind:this={collapseButton}
      class="collapse-btn" 
      on:click={toggleSidebar}
      aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
    >
      <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        {#if collapsed}
          <path d="M9 18l6-6-6-6"></path>
        {:else}
          <path d="M15 18l-6-6 6-6"></path>
        {/if}
      </svg>
    </button>
  </div>

  <nav class="sidebar-nav">
    {#each navigationItems as item}
      <a 
        href={item.path} 
        use:link 
        class="nav-item"
        class:active={$location === item.path}
        title={collapsed ? item.label : ''}
        on:click={handleNavigationClick}
      >
        <div class="nav-icon">
          {@html getIcon(item.icon)}
        </div>
        {#if !collapsed}
          <span class="nav-label">{item.label}</span>
          {#if item.badge && item.badge > 0}
            <span class="nav-badge">{item.badge}</span>
          {/if}
        {:else if item.badge && item.badge > 0}
          <span class="nav-badge-collapsed">{item.badge}</span>
        {/if}
      </a>
    {/each}
  </nav>

  <!-- New Peace Piece Button -->
  <div class="create-piece-container">
    <a 
      href="/create-peace" 
      use:link 
      class="create-piece-btn"
      title={collapsed ? "Create New Peace Piece" : ""}
      on:click={handleNavigationClick}
    >
      <div class="create-icon">
        {@html getIcon('add')}
      </div>
      {#if !collapsed}
        <span class="create-label">New Peace Piece</span>
      {/if}
    </a>
  </div>

  <div class="sidebar-footer">
    {#if $user}
      <!-- Profile Row -->
      <div class="profile-row">
        <button class="profile-info" on:click={navigateToProfile}>
          <div class="profile-avatar">
            {#if userProfile?.avatar_url}
              <img src={userProfile.avatar_url} alt="Profile" class="avatar-image" />
            {:else}
              <div class="avatar-placeholder">
                {userProfile?.username?.[0]?.toUpperCase() || $user.email?.[0]?.toUpperCase() || '?'}
              </div>
            {/if}
          </div>
          {#if !collapsed}
            <div class="profile-details">
              <span class="username">{userProfile?.username || 'User'}</span>
            </div>
          {/if}
        </button>
        
        {#if !collapsed}
          <div class="profile-menu-container" bind:this={profileMenuElement}>
            <button 
              class="profile-menu-btn" 
              on:click={toggleProfileMenu}
              title="Profile menu"
            >
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <circle cx="12" cy="12" r="1"></circle>
                <circle cx="12" cy="5" r="1"></circle>
                <circle cx="12" cy="19" r="1"></circle>
              </svg>
            </button>

            {#if showProfileMenu}
              <div class="profile-menu">
                <!-- Theme Toggle -->
                <div class="menu-item theme-toggle-item">
                  <div class="menu-item-content">
                    <span>{darkMode ? 'Light Mode' : 'Dark Mode'}</span>
                  </div>
                  <ThemeToggle {darkMode} on:toggle={toggleDarkMode} />
                </div>

                <!-- Separator -->
                <div class="menu-separator"></div>

                <!-- Menu Items -->
                {#each profileMenuItems as item}
                  <a 
                    href={item.path} 
                    use:link 
                    class="menu-item"
                    on:click={() => {
                      closeProfileMenu();
                      handleNavigationClick();
                    }}
                  >
                    <div class="menu-item-content">
                      {@html getIcon(item.icon)}
                      <span>{item.label}</span>
                    </div>
                  </a>
                {/each}

                <!-- Separator -->
                <div class="menu-separator"></div>

                <!-- Sign Out Row -->
                <div class="signout-row">
                  <button 
                    class="sign-out-btn" 
                    on:click={handleSignOut}
                    title={collapsed ? 'Sign Out' : ''}
                  >
                    <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
                      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                      <polyline points="16 17 21 12 16 7"></polyline>
                      <line x1="21" y1="12" x2="9" y2="12"></line>
                    </svg>
                    {#if !collapsed}
                      <span>Sign Out</span>
                    {/if}
                  </button>
                </div>
              </div>
            {/if}
          </div>
        {/if}
      </div>

    {/if}
  </div>
</aside>

<style>
  .sidebar {
    position: fixed;
    left: 0;
    top: 0;
    height: 100vh;
    width: 280px;
    background: var(--card-bg);
    border-right: 1px solid var(--border-color);
    display: flex;
    flex-direction: column;
    transition: width 0.3s ease;
    z-index: 100;
    overflow: hidden;
  }

  .sidebar.collapsed {
    width: 69px;
  }

  .sidebar-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--space-4);
    border-bottom: 1px solid var(--border-color);
    min-height: 80px;
  }

  .logo {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .logo-link {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    text-decoration: none;
    color: inherit;
  }

  .logo-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    flex-shrink: 0;
    transition: all .3s ease;
    opacity: 1;
    margin-right: 0;
    position: relative;
    left: 2.2px;
  }

  .sidebar:not(.collapsed) .logo .logo-icon {
    opacity: 0;
    margin-right: -37px;
  }

  .logo-icon svg {
    width: 100%;
    height: 100%;
  }

  .logo-text {
    font-weight: 500;
    font-size: 1.25rem;
    color: var(--text-color);
    white-space: nowrap;
    position: relative;
    top: 3px;
  }

  .collapse-btn {
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    padding: var(--space-2);
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
    flex-shrink: 0;
    position: relative;
    top: 4px;
  }

  .sidebar.collapsed .collapse-btn {
    padding: 0px;
    border-radius: 4px 0px 0px 4px;
  }

  .collapse-btn:hover {
    background: var(--border-color);
    color: var(--text-color);
  }

  .sidebar-nav {
    flex: 1;
    padding: var(--space-4) 0;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .sidebar:not(.collapsed) .sidebar-nav {
    margin: 0 0 0 6px;
  }

  .nav-item {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    padding: 0px;
    color: var(--text-color);
    text-decoration: none;
    transition: all 0.2s;
    position: relative;
    margin: 0 var(--space-2);
  }

  .nav-item:hover {
    color: var(--text-color);
  }

  .sidebar.collapsed .nav-item {
    justify-content: center;
  }

  .nav-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    border-radius: 100px;
    background: var(--bg-color);
    padding: 10px;
    filter: drop-shadow(2px 4px 6px rgba(0,0,0,.1));
  }

  .nav-item.active .nav-icon {
    background: var(--color-primary-600);
    color: white;
  }

  .nav-label {
    font-weight: 500;
    white-space: nowrap;
  }

  .nav-badge {
    background-color: var(--color-error-600);
    color: white;
    font-size: 0.75rem;
    font-weight: 600;
    padding: 2px 6px;
    border-radius: 10px;
    min-width: 18px;
    height: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-left: auto;
  }

  .nav-badge-collapsed {
    position: absolute;
    top: 8px;
    right: 8px;
    background-color: var(--color-error-600);
    color: white;
    font-size: 0.75rem;
    font-weight: 600;
    padding: 2px 6px;
    border-radius: 10px;
    min-width: 18px;
    height: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  /* New Peace Piece Button */
  .create-piece-container {
    padding: var(--space-4);
  }

  .create-piece-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-3);
    background: var(--bg-color);
    color: var(--text-color);
    padding: var(--space-3);
    border-radius: 100px;
    text-decoration: none;
    font-weight: 500;
    transition: all 0.2s;
    width: 100%;
  }

  .create-piece-btn:hover {
    background-color: var(--color-primary-600);
    color: white;
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }

  .create-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .create-label {
    white-space: nowrap;
  }

  .sidebar-footer {
    border-top: 1px solid var(--border-color);
    padding: var(--space-4);
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .profile-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: var(--space-3);
  }

  .profile-info {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    flex: 1;
    min-width: 0;
    background: none;
    border: none;
    padding: 0;
    cursor: pointer;
    text-align: left;
    transition: opacity 0.2s;
    border-radius: 17px;
  }

  .profile-info:hover {
    opacity: 0.8;
  }

  .profile-avatar {
    width: 35px;
    height: 45px;
    overflow: hidden;
    border-radius: 100px;
    border: solid 2px var(--bg-color);
    filter: drop-shadow(2px 4px 6px rgba(0,0,0,.1));
  }

  .avatar-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder {
    width: 100%;
    height: 100%;
    background-color: var(--color-neutral-200);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    color: var(--color-neutral-600);
    font-size: 0.875rem;
  }

  .profile-details {
    flex: 1;
    min-width: 0;
  }

  .username {
    font-size: 0.875rem;
    font-weight: 500;
    color: var(--text-color);
    display: block;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .profile-menu-container {
    position: relative;
  }

  .profile-menu-btn {
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    padding: var(--space-1);
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
    flex-shrink: 0;
  }

  .profile-menu-btn:hover {
    background: var(--border-color);
    color: var(--text-color);
  }

  .profile-menu {
    position: absolute;
    bottom: 100%;
    right: 0;
    background: var(--bg-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    box-shadow: 0 8px 16px var(--shadow-color);
    min-width: 200px;
    padding: var(--space-2);
    z-index: 1000;
    animation: slideUp 0.2s ease-out;
  }

  @keyframes slideUp {
    from {
      opacity: 0;
      transform: translateY(8px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .menu-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    text-decoration: none;
    color: var(--text-color);
    transition: background-color 0.2s;
    cursor: pointer;
  }

  .menu-item:hover {
    background-color: var(--border-color);
  }

  .menu-item-content {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    font-size: 0.875rem;
  }

  .theme-toggle-item {
    cursor: default;
  }

  .theme-toggle-item:hover {
    background-color: transparent;
  }

  .menu-separator {
    height: 1px;
    background-color: var(--border-color);
    margin: var(--space-2) 0;
  }

  .signout-row {
    display: flex;
  }

  .sign-out-btn {
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    padding: var(--space-2);
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    gap: var(--space-2);
    transition: all 0.2s;
    font-size: 0.875rem;
    flex-shrink: 0;
    width: 100%;
    justify-content: flex-start;
  }

  .sign-out-btn:hover {
    background-color: var(--color-error-50);
    color: var(--color-error-600);
  }

  /* Mobile responsiveness */
  @media (max-width: 768px) {
    .sidebar {
      transform: translateX(-100%);
      transition: transform 0.3s ease, width 0.3s ease;
      z-index: 200;
    }

    .sidebar.mobile-open {
      transform: translateX(0);
    }
  }
</style>