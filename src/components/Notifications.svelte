<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { fade, fly } from 'svelte/transition';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';

  let notifications: any[] = [];
  let loading = true;
  let error: string | null = null;
  let filter: 'all' | 'unread' | 'read' = 'all';
  let subscription: any = null;

  async function loadNotifications() {
    if (!$user) return;

    try {
      loading = true;
      error = null;

      let query = supabase
        .from('notifications')
        .select('*')
        .eq('user_id', $user.id)
        .order('created_at', { ascending: false });

      if (filter === 'unread') {
        query = query.eq('read', false);
      } else if (filter === 'read') {
        query = query.eq('read', true);
      }

      const { data, error: fetchError } = await query;

      if (fetchError) throw fetchError;

      notifications = data || [];
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  async function markAsRead(notificationId: string) {
    try {
      const { error } = await supabase
        .from('notifications')
        .update({ read: true })
        .eq('id', notificationId);

      if (error) throw error;

      // Update local state
      notifications = notifications.map(n => 
        n.id === notificationId ? { ...n, read: true } : n
      );
    } catch (e: any) {
      console.error('Error marking notification as read:', e);
    }
  }

  async function markAllAsRead() {
    if (!$user) return;

    try {
      const { error } = await supabase
        .from('notifications')
        .update({ read: true })
        .eq('user_id', $user.id)
        .eq('read', false);

      if (error) throw error;

      // Update local state
      notifications = notifications.map(n => ({ ...n, read: true }));
    } catch (e: any) {
      console.error('Error marking all notifications as read:', e);
    }
  }

  async function deleteNotification(notificationId: string) {
    try {
      const { error } = await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);

      if (error) throw error;

      // Update local state
      notifications = notifications.filter(n => n.id !== notificationId);
    } catch (e: any) {
      console.error('Error deleting notification:', e);
    }
  }

  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

    if (diffInHours < 1) {
      const diffInMinutes = Math.floor(diffInHours * 60);
      return diffInMinutes <= 1 ? 'Just now' : `${diffInMinutes} minutes ago`;
    } else if (diffInHours < 24) {
      const hours = Math.floor(diffInHours);
      return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    } else {
      const diffInDays = Math.floor(diffInHours / 24);
      if (diffInDays < 7) {
        return `${diffInDays} day${diffInDays > 1 ? 's' : ''} ago`;
      } else {
        return date.toLocaleDateString('en-US', { 
          month: 'short', 
          day: 'numeric',
          year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
        });
      }
    }
  }

  function getNotificationIcon(type: string): string {
    switch (type) {
      case 'success':
        return '✓';
      case 'warning':
        return '⚠';
      case 'error':
        return '✕';
      default:
        return 'ℹ';
    }
  }

  function getNotificationColor(type: string): string {
    switch (type) {
      case 'success':
        return 'var(--color-success-600)';
      case 'warning':
        return 'var(--color-warning-600)';
      case 'error':
        return 'var(--color-error-600)';
      default:
        return 'var(--color-primary-600)';
    }
  }

  $: unreadCount = notifications.filter(n => !n.read).length;

  onMount(() => {
    if ($user) {
      loadNotifications();

      // Set up real-time subscription
      subscription = supabase
        .channel('notifications-page')
        .on('postgres_changes', 
          { 
            event: '*', 
            schema: 'public', 
            table: 'notifications',
            filter: `user_id=eq.${$user.id}`
          }, 
          () => {
            loadNotifications();
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

  $: if (filter) {
    loadNotifications();
  }
</script>

<div class="notifications-container">
  <div class="notifications-header">
    <div class="header-content">
      <div class="title-section">
        <h1>Notifications</h1>
        <p>Stay updated with your Peace Piece activity</p>
      </div>
      {#if unreadCount > 0}
        <div class="unread-badge">
          {unreadCount} unread
        </div>
      {/if}
    </div>
  </div>

  <div class="notifications-controls">
    <div class="filter-buttons">
      <button 
        class:active={filter === 'all'}
        on:click={() => filter = 'all'}
      >
        All
      </button>
      <button 
        class:active={filter === 'unread'}
        on:click={() => filter = 'unread'}
      >
        Unread ({unreadCount})
      </button>
      <button 
        class:active={filter === 'read'}
        on:click={() => filter = 'read'}
      >
        Read
      </button>
    </div>

    {#if unreadCount > 0}
      <button class="mark-all-read" on:click={markAllAsRead}>
        <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        Mark all as read
      </button>
    {/if}
  </div>

  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading notifications...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h3>Error loading notifications</h3>
        <p>{error}</p>
        <button class="primary" on:click={loadNotifications}>Try Again</button>
      </div>
    </div>
  {:else if notifications.length === 0}
    <div class="empty-state" transition:fade>
      <div class="empty-icon">
        <svg viewBox="0 0 24 24" width="48" height="48" stroke="currentColor" stroke-width="1" fill="none">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
          <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
        </svg>
      </div>
      {#if filter === 'unread'}
        <h3>No unread notifications</h3>
        <p>You're all caught up! Check back later for updates.</p>
      {:else if filter === 'read'}
        <h3>No read notifications</h3>
        <p>Notifications you've read will appear here.</p>
      {:else}
        <h3>No notifications yet</h3>
        <p>When you follow pieces or interact with the community, notifications will appear here.</p>
      {/if}
    </div>
  {:else}
    <div class="notifications-list">
      {#each notifications as notification, index (notification.id)}
        <div 
          class="notification-item"
          class:unread={!notification.read}
          in:fly={{ y: 20, duration: 300, delay: index * 50 }}
        >
          <div class="notification-content">
            <div class="notification-header">
              <div class="notification-icon" style="color: {getNotificationColor(notification.type)}">
                {getNotificationIcon(notification.type)}
              </div>
              <div class="notification-meta">
                <h3 class="notification-title">{notification.title}</h3>
                <span class="notification-time">{formatDate(notification.created_at)}</span>
              </div>
              {#if !notification.read}
                <div class="unread-indicator"></div>
              {/if}
            </div>

            <p class="notification-message">{notification.message}</p>

            {#if notification.action_url}
              <a href={notification.action_url} class="notification-action">
                View Details →
              </a>
            {/if}
          </div>

          <div class="notification-actions">
            {#if !notification.read}
              <button 
                class="mark-read-btn"
                on:click={() => markAsRead(notification.id)}
                title="Mark as read"
              >
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
              </button>
            {/if}
            
            <button 
              class="delete-btn"
              on:click={() => deleteNotification(notification.id)}
              title="Delete notification"
            >
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <polyline points="3 6 5 6 21 6"></polyline>
                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
              </svg>
            </button>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .notifications-container {
    padding: var(--space-6);
    max-width: 1000px;
    margin: 0 auto 0 0;
  }

  .notifications-header {
    margin-bottom: var(--space-6);
  }

  .header-content {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: var(--space-4);
  }

  .title-section h1 {
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .title-section p {
    color: var(--text-muted);
    font-size: 1.125rem;
    margin: 0;
  }

  .unread-badge {
    background-color: var(--color-primary-600);
    color: white;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
    white-space: nowrap;
  }

  .notifications-controls {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-6);
    gap: var(--space-4);
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-md);
    padding: var(--space-4);
  }

  :global(.light-mode) .notifications-controls {
    background: var(--bg-color);
  }

  .filter-buttons {
    display: flex;
    gap: var(--space-2);
  }

  .filter-buttons button {
    background: none;
    border: none;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    cursor: pointer;
    color: var(--text-muted);
    font-size: 0.875rem;
    font-weight: 500;
    transition: all 0.2s;
  }

  .filter-buttons button:hover {
    background-color: var(--border-color);
    color: var(--text-color);
  }

  .filter-buttons button.active {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .mark-all-read {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background: none;
    border: 1px solid var(--color-primary-600);
    color: var(--color-primary-600);
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    cursor: pointer;
    font-size: 0.875rem;
    font-weight: 500;
    transition: all 0.2s;
  }

  .mark-all-read:hover {
    background-color: var(--color-primary-600);
    color: white;
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
    padding: var(--space-8);
  }

  .error-card {
    background: var(--card-bg);
    border: 1px solid var(--color-error-200);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    text-align: center;
    max-width: 400px;
  }

  .error-card h3 {
    color: var(--color-error-600);
    margin-bottom: var(--space-2);
  }

  .empty-state {
    text-align: center;
    padding: var(--space-12);
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
  }

  .empty-icon {
    display: flex;
    justify-content: center;
    margin-bottom: var(--space-4);
    color: var(--text-muted);
  }

  .empty-state h3 {
    font-size: 1.25rem;
    font-weight: 600;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .empty-state p {
    color: var(--text-muted);
    margin: 0;
  }

  .notifications-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .notification-item {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    padding: var(--space-4);
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-md);
    transition: all 0.2s;
    position: relative;
  }

  .notification-item.unread {
    background: color-mix(in srgb, var(--color-primary-50) 50%, var(--card-bg));
    border-left: 4px solid var(--color-primary-600);
  }

  .notification-content {
    flex: 1;
  }

  .notification-header {
    display: flex;
    align-items: flex-start;
    gap: var(--space-3);
    margin-bottom: var(--space-2);
  }

  .notification-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background-color: color-mix(in srgb, currentColor 10%, transparent);
    font-weight: bold;
    font-size: 0.875rem;
    flex-shrink: 0;
  }

  .notification-meta {
    flex: 1;
  }

  .notification-title {
    font-size: 1rem;
    font-weight: 600;
    margin: 0 0 var(--space-1) 0;
    line-height: 1.3;
  }

  .notification-time {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .unread-indicator {
    width: 8px;
    height: 8px;
    background-color: var(--color-primary-600);
    border-radius: 50%;
    flex-shrink: 0;
  }

  .notification-message {
    color: var(--text-muted);
    line-height: 1.4;
    margin: 0 0 var(--space-3) 0;
  }

  .notification-action {
    color: var(--color-primary-600);
    text-decoration: none;
    font-size: 0.875rem;
    font-weight: 500;
    transition: color 0.2s;
  }

  .notification-action:hover {
    color: var(--color-primary-700);
  }

  .notification-actions {
    display: flex;
    gap: var(--space-2);
    margin-left: var(--space-3);
  }

  .mark-read-btn, .delete-btn {
    background: none;
    border: none;
    color: var(--text-muted);
    padding: var(--space-1);
    border-radius: 4px;
    cursor: pointer;
    opacity: 0.7;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .notification-item:hover .mark-read-btn,
  .notification-item:hover .delete-btn {
    opacity: 1;
  }

  .mark-read-btn:hover {
    color: var(--color-success-600);
    background-color: var(--color-success-50);
  }

  .delete-btn:hover {
    color: var(--color-error-600);
    background-color: var(--color-error-50);
  }

  @media (max-width: 768px) {
    .notifications-container {
      padding: var(--space-4);
    }

    .header-content {
      flex-direction: column;
      align-items: stretch;
    }

    .title-section h1 {
      font-size: 2rem;
    }

    .notifications-controls {
      flex-direction: column;
      align-items: stretch;
      gap: var(--space-3);
    }

    .filter-buttons {
      justify-content: center;
    }

    .notification-item {
      flex-direction: column;
      gap: var(--space-3);
    }

    .notification-actions {
      align-self: flex-end;
      margin-left: 0;
    }
  }
</style>