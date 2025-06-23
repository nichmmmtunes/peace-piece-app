<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { user, signOut } from '../stores/authStore';
  import { supabase } from '../lib/supabase';
  import ThemeToggle from './ThemeToggle.svelte';
  import { onMount, onDestroy } from 'svelte';
  
  export let darkMode: boolean;
  
  const dispatch = createEventDispatcher();
  
  let unreadNotifications = 0;
  let subscription: any = null;
  
  function toggleDarkMode() {
    dispatch('toggleDarkMode');
  }

  async function handleSignOut() {
    await signOut();
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

  onMount(() => {
    if ($user) {
      loadUnreadCount();

      // Set up real-time subscription for notification count
      subscription = supabase
        .channel('notification-count')
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
    if (subscription) {
      supabase.removeChannel(subscription);
    }
  });

  // Reload count when user changes
  $: if ($user) {
    loadUnreadCount();
  } else {
    unreadNotifications = 0;
  }
</script>

<header>
  <div class="container">
    <div class="header-content">
      <div class="logo">
        <a href="/" use:link>
          <div class="logo-icon">
            <svg viewBox="0 0 597 933" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M295.474 730.578C296.983 727.764 301.017 727.764 302.526 730.578L402.365 916.86C403.793 919.525 401.862 922.75 398.839 922.75H199.161C196.138 922.75 194.207 919.525 195.635 916.86L295.474 730.578Z" fill="currentColor" stroke="currentColor" stroke-width="20"/>
              <path d="M294.854 181.425C296.249 178.22 300.794 178.22 302.189 181.425L382.606 366.153C383.756 368.795 381.82 371.75 378.938 371.75H218.104C215.222 371.75 213.286 368.795 214.436 366.153L294.854 181.425Z" fill="currentColor" stroke="currentColor" stroke-width="20"/>
              <path d="M302.554 761.123C301.063 764.008 296.937 764.008 295.446 761.123L132.275 445.336C130.899 442.674 132.832 439.5 135.828 439.5L462.172 439.5C465.168 439.5 467.101 442.674 465.725 445.336L302.554 761.123Z" fill="currentColor" stroke="currentColor" stroke-width="20"/>
              <path d="M176 14C176 11.7909 177.791 10 180 10H362C395.137 10 422 36.8629 422 70V170C422 172.209 420.209 174 418 174H236C202.863 174 176 147.137 176 114V14Z" fill="currentColor" stroke="currentColor" stroke-width="20"/>
              <path d="M314.513 536.553C249.178 450.905 291.655 326.35 395.709 298.469C499.762 270.588 598.825 357.217 585.068 464.059L539.249 819.876C538.793 823.421 534.27 824.633 532.102 821.791L314.513 536.553Z" fill="currentColor"/>
              <path d="M282.702 536.553C348.038 450.905 305.56 326.35 201.507 298.469C97.4538 270.588 -1.60994 357.217 12.148 464.059L57.9663 819.876C58.4228 823.421 62.9459 824.633 65.1139 821.791L282.702 536.553Z" fill="currentColor"/>
              <path d="M314.513 536.553C249.178 450.905 291.655 326.35 395.709 298.469C499.762 270.588 598.825 357.217 585.068 464.059L539.249 819.876C538.793 823.421 534.27 824.633 532.102 821.791L314.513 536.553Z" stroke="currentColor" stroke-width="20"/>
              <path d="M282.702 536.553C348.038 450.905 305.56 326.35 201.507 298.469C97.4538 270.588 -1.60994 357.217 12.148 464.059L57.9663 819.876C58.4228 823.421 62.9459 824.633 65.1139 821.791L282.702 536.553Z" stroke="currentColor" stroke-width="20"/>
            </svg>
          </div>
          <span class="logo-text hide-sm">Peace Piece</span>
        </a>
      </div>
      
      <nav>
        <a href="/explore" use:link class="nav-link">Explore</a>
        {#if $user}
          <a href="/notifications" use:link class="nav-link notifications-link">
            Notifications
            {#if unreadNotifications > 0}
              <span class="notification-badge">{unreadNotifications}</span>
            {/if}
          </a>
          <a href="/settings" use:link class="nav-link">Settings</a>
          <button class="sign-out" on:click={handleSignOut}>Sign Out</button>
        {/if}
        <ThemeToggle {darkMode} on:toggle={toggleDarkMode} />
      </nav>
    </div>
  </div>
</header>

<style>
  header {
    background: var(--card-bg);
    box-shadow: 0 2px 4px var(--shadow-color);
    position: sticky;
    top: 0;
    z-index: 10;
    transition: background-color 0.3s, box-shadow 0.3s;
  }
  
  .header-content {
    display: flex;
    align-items: center;
    justify-content: space-between;
    height: 64px;
  }
  
  .logo {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    font-weight: 500;
    font-size: 1.25rem;
  }
  
  .logo a {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    text-decoration: none;
    color: inherit;
  }
  
  .logo-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    color: var(--color-primary-600);
    transition: color 0.3s;
  }

  .logo-icon svg {
    width: 100%;
    height: 100%;
  }

  /* Dark mode logo color */
  @media (prefers-color-scheme: dark) {
    .logo-icon {
      color: var(--color-primary-400);
    }
  }

  /* Manual dark mode override */
  :global(.dark-mode) .logo-icon {
    color: var(--color-primary-400);
  }
  
  .logo-text {
    color: var(--text-color);
  }
  
  nav {
    display: flex;
    align-items: center;
    gap: var(--space-4);
  }

  .nav-link {
    color: var(--text-color);
    text-decoration: none;
    font-weight: 500;
    position: relative;
  }

  .nav-link:hover {
    color: var(--color-primary-600);
  }

  .notifications-link {
    display: flex;
    align-items: center;
    gap: var(--space-1);
  }

  .notification-badge {
    background-color: var(--color-error-600);
    color: white;
    font-size: 0.75rem;
    font-weight: 500;
    padding: 2px 6px;
    border-radius: 10px;
    min-width: 18px;
    height: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
    line-height: 1;
  }

  .sign-out {
    background: none;
    border: none;
    color: var(--text-color);
    cursor: pointer;
    padding: var(--space-2);
    font-weight: 500;
  }

  .sign-out:hover {
    color: var(--color-error-600);
  }
  
  @media (max-width: 640px) {
    .header-content {
      height: 56px;
    }
    
    .logo-icon {
      width: 28px;
      height: 28px;
    }

    nav {
      gap: var(--space-2);
    }

    .nav-link {
      font-size: 0.875rem;
    }
  }
</style>