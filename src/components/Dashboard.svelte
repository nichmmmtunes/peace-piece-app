<script lang="ts">
  import { onMount } from 'svelte';
  import { link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';

  let username = '';
  let userProfile: any = null;
  let activeProjects: any[] = [];
  let applications: any[] = [];
  let projectActivity: any[] = [];
  let timelineReminders: any[] = [];
  let unreadNotifications = 0;
  let loading = true;
  let error: string | null = null;
  let activeApplicationTab: 'all' | 'pending' | 'accepted' | 'declined' = 'all';

  async function loadDashboardData() {
    if (!$user) return;

    try {
      loading = true;
      error = null;

      // Load user profile
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', $user.id)
        .single();

      if (profileError) throw profileError;
      userProfile = profileData;
      username = profileData?.username || '';

      // Load unread notifications count
      const { count: notificationCount, error: notificationError } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', $user.id)
        .eq('read', false);

      if (notificationError) throw notificationError;
      unreadNotifications = notificationCount || 0;

      // Load active projects (where user is organizer)
      const { data: organizerData } = await supabase
        .from('organizers')
        .select('id')
        .eq('user_id', $user.id);

      if (organizerData && organizerData.length > 0) {
        const organizerIds = organizerData.map(org => org.id);
        
        const { data: organizedPieces, error: organizedError } = await supabase
          .from('piece_details')
          .select('*')
          .in('organizer_id', organizerIds)
          .order('created_at', { ascending: false });

        if (organizedError) throw organizedError;
        
        if (organizedPieces) {
          activeProjects = [...activeProjects, ...organizedPieces];
        }
      }

      // Load active projects (where user is contributor)
      const { data: artistData } = await supabase
        .from('artists')
        .select('id')
        .eq('user_id', $user.id)
        .maybeSingle();

      if (artistData) {
        const { data: contributedPieces } = await supabase
          .from('piece_details')
          .select(`
            *,
            piece_artists!inner(role)
          `)
          .eq('piece_artists.artist_id', artistData.id)
          .order('created_at', { ascending: false });

        if (contributedPieces) {
          // Add to active projects, avoiding duplicates
          const existingIds = new Set(activeProjects.map(p => p.id));
          contributedPieces.forEach(piece => {
            if (!existingIds.has(piece.id)) {
              activeProjects.push(piece);
            }
          });
        }
      }

      // Load applications
      // First, applications where user is the applicant
      const { data: userApplications, error: applicationsError } = await supabase
        .from('applications')
        .select(`
          *,
          pieces:piece_id(*)
        `)
        .eq('applicant_profile_id', $user.id)
        .order('created_at', { ascending: false });

      if (applicationsError) throw applicationsError;
      
      // Then, applications for pieces where user is the organizer
      let organizerApplications: any[] = [];
      if (organizerData && organizerData.length > 0) {
        const { data: orgApps, error: orgAppsError } = await supabase
          .from('applications')
          .select(`
            *,
            pieces:piece_id(*),
            profiles:applicant_profile_id(
              username,
              avatar_url
            )
          `)
          .in('piece_id', activeProjects.map(p => p.id))
          .order('created_at', { ascending: false });

        if (orgAppsError) throw orgAppsError;
        if (orgApps) {
          organizerApplications = orgApps;
        }
      }

      // Combine all applications
      applications = [...(userApplications || []), ...(organizerApplications || [])];

      // Load recent activity (notifications)
      const { data: recentNotifications, error: activityError } = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', $user.id)
        .order('created_at', { ascending: false })
        .limit(5);

      if (activityError) throw activityError;
      
      // Transform notifications into activity items
      if (recentNotifications && recentNotifications.length > 0) {
        projectActivity = recentNotifications.map(notification => ({
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          date: notification.created_at,
          actionUrl: notification.action_url,
          read: notification.read
        }));
      } else {
        // Fallback to empty array if no notifications
        projectActivity = [];
      }

      // Generate timeline reminders from project milestones
      const now = new Date();
      const reminders: any[] = [];

      activeProjects.forEach(project => {
        if (project.milestones && Array.isArray(project.milestones)) {
          project.milestones.forEach((milestone: any) => {
            if (milestone.due_date) {
              const dueDate = new Date(milestone.due_date);
              if (dueDate > now) {
                const diffTime = Math.abs(dueDate.getTime() - now.getTime());
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                
                reminders.push({
                  type: milestone.title || 'Deadline',
                  projectTitle: project.title,
                  dueDate: milestone.due_date,
                  daysRemaining: diffDays,
                  formattedDate: formatDate(milestone.due_date)
                });
              }
            }
          });
        }
      });

      // Sort reminders by due date (closest first)
      timelineReminders = reminders.sort((a, b) => 
        new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime()
      ).slice(0, 3); // Take only the 3 closest deadlines

    } catch (e: any) {
      console.error('Error loading dashboard data:', e);
      error = e.message;
    } finally {
      loading = false;
    }
  }

  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: '2-digit', 
      day: '2-digit',
      year: '2-digit'
    });
  }

  function getDaysUntilDate(dateString: string): number {
    const now = new Date();
    const targetDate = new Date(dateString);
    const diffTime = Math.abs(targetDate.getTime() - now.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  function getStatusBadge(status: string): string {
    switch (status) {
      case 'open_to_applications':
        return 'Open to Applications';
      case 'seeking_funding':
        return 'Seeking Funding';
      case 'published':
        return 'Published';
      case 'submitted':
        return 'Pending';
      case 'reviewing':
        return 'Reviewing';
      case 'approved':
        return 'Accepted';
      case 'rejected':
        return 'Declined';
      default:
        return 'Draft';
    }
  }

  function getStatusClass(status: string): string {
    switch (status) {
      case 'open_to_applications':
        return 'status-open';
      case 'seeking_funding':
        return 'status-seeking';
      case 'published':
        return 'status-published';
      case 'submitted':
        return 'status-pending';
      case 'reviewing':
        return 'status-reviewing';
      case 'approved':
        return 'status-accepted';
      case 'rejected':
        return 'status-declined';
      default:
        return 'status-draft';
    }
  }

  function filterApplications(status: string | null = null): any[] {
    if (!status || status === 'all') {
      return applications;
    }
    
    return applications.filter(app => {
      if (status === 'pending') {
        return app.status === 'submitted' || app.status === 'reviewing';
      } else if (status === 'accepted') {
        return app.status === 'approved';
      } else if (status === 'declined') {
        return app.status === 'rejected';
      }
      return true;
    });
  }

  // Get notification icon based on type
  function getNotificationIcon(type: string): string {
    switch (type) {
      case 'success':
        return `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
          <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>`;
      case 'warning':
        return `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
          <line x1="12" y1="9" x2="12" y2="13"></line>
          <line x1="12" y1="17" x2="12.01" y2="17"></line>
        </svg>`;
      case 'error':
        return `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="15" y1="9" x2="9" y2="15"></line>
          <line x1="9" y1="9" x2="15" y2="15"></line>
        </svg>`;
      default: // info
        return `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="12" y1="16" x2="12" y2="12"></line>
          <line x1="12" y1="8" x2="12.01" y2="8"></line>
        </svg>`;
    }
  }

  // Get notification color based on type
  function getNotificationColor(type: string): string {
    switch (type) {
      case 'success':
        return 'var(--color-success-600)';
      case 'warning':
        return 'var(--color-warning-600)';
      case 'error':
        return 'var(--color-error-600)';
      default: // info
        return 'var(--color-primary-600)';
    }
  }

  // Format relative time for notifications
  function formatRelativeTime(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);
    
    if (diffInSeconds < 60) {
      return 'Just now';
    }
    
    const diffInMinutes = Math.floor(diffInSeconds / 60);
    if (diffInMinutes < 60) {
      return `${diffInMinutes} minute${diffInMinutes > 1 ? 's' : ''} ago`;
    }
    
    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) {
      return `${diffInHours} hour${diffInHours > 1 ? 's' : ''} ago`;
    }
    
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays < 7) {
      return `${diffInDays} day${diffInDays > 1 ? 's' : ''} ago`;
    }
    
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
    });
  }

  onMount(() => {
    if ($user) {
      loadDashboardData();
    }
  });

  $: filteredApplications = filterApplications(activeApplicationTab);
</script>

<div class="dashboard-container">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading your dashboard...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Error Loading Dashboard</h2>
        <p>{error}</p>
        <button class="primary" on:click={loadDashboardData}>Try Again</button>
      </div>
    </div>
  {:else}
    <div class="dashboard-content">
      <!-- Welcome Header -->
      <div class="welcome-header">
        <h1>Welcome back, {username || 'there'}!</h1>
        
        <div class="notification-bar">
          <div class="notification-item">
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
              <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
            </svg>
            <span>{unreadNotifications} New Notifications</span>
          </div>
          
          {#if timelineReminders.length > 0}
            <div class="notification-item">
              <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
              </svg>
              <span>Feedback due in 3 days</span>
            </div>
          {/if}
        </div>
      </div>

      <div class="dashboard-grid">
        <!-- Left Column -->
        <div class="dashboard-left">
          <!-- My Active Projects Section -->
          <section class="projects-section">
            <div class="section-header">
              <h2>My Active Projects</h2>
              <span class="count-badge">{activeProjects.length} Projects</span>
            </div>

            {#if activeProjects.length > 0}
              <div class="projects-list">
                {#each activeProjects.slice(0, 2) as project (project.id)}
                  <div class="project-card" in:fly={{ y: 20, duration: 300 }}>
                    <div class="project-image">
                      {#if project.image_url}
                        <img src={project.image_url} alt={project.title} loading="lazy" />
                      {:else}
                        <div class="image-placeholder">
                          <svg viewBox="0 0 24 24" width="32" height="32" stroke="currentColor" stroke-width="1" fill="none">
                            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                            <circle cx="8.5" cy="8.5" r="1.5"></circle>
                            <polyline points="21,15 16,10 5,21"></polyline>
                          </svg>
                        </div>
                      {/if}
                    </div>
                    
                    <div class="project-details">
                      <div class="project-header">
                        <h3 class="project-title">{project.title}</h3>
                        <div class="project-status-badge">
                          {#if project.project_status === 'open_to_applications'}
                            <span class="status-badge open-to-applications">Open to Applications</span>
                          {:else if project.project_status === 'seeking_funding'}
                            <span class="status-badge seeking-funding">Seeking Funding</span>
                          {:else if project.project_status === 'published'}
                            <span class="status-badge published">Published</span>
                          {:else}
                            <span class="status-badge draft">Draft</span>
                          {/if}
                        </div>
                      </div>
                      
                      <div class="project-meta">
                        <div class="project-dates">
                          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                            <line x1="16" y1="2" x2="16" y2="6"></line>
                            <line x1="8" y1="2" x2="8" y2="6"></line>
                            <line x1="3" y1="10" x2="21" y2="10"></line>
                          </svg>
                          <span>July 29 - Sept 25</span>
                        </div>
                        
                        <div class="project-timeline">
                          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12 6 12 12 16 14"></polyline>
                          </svg>
                          <span>Starts in 34 days</span>
                        </div>
                      </div>
                      
                      <div class="project-actions">
                        {#if project.project_status === 'open_to_applications'}
                          <a href="/edit/{project.id}" use:link class="action-button">
                            <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                            </svg>
                            Edit Project
                          </a>
                        {:else}
                          <a href="/piece/{project.id}" use:link class="action-button">
                            <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                              <circle cx="12" cy="12" r="3"></circle>
                            </svg>
                            View Project
                          </a>
                        {/if}
                      </div>
                    </div>
                  </div>
                {/each}
              </div>
            {:else}
              <div class="empty-state">
                <p>You don't have any active projects yet.</p>
                <a href="/create-peace" use:link class="primary">Create Your First Project</a>
              </div>
            {/if}
          </section>

          <!-- Project Activity Section -->
          <section class="activity-section">
            <div class="section-header">
              <h2>Project Activity</h2>
            </div>

            {#if projectActivity.length > 0}
              <div class="activity-list">
                {#each projectActivity as activity (activity.id)}
                  <div class="activity-item" in:fly={{ y: 20, duration: 300 }}>
                    <div class="activity-icon" style="color: {getNotificationColor(activity.type)}">
                      {@html getNotificationIcon(activity.type)}
                    </div>
                    
                    <div class="activity-details">
                      <div class="activity-header">
                        <h3 class="activity-title">{activity.title}</h3>
                        <span class="activity-time">{formatRelativeTime(activity.date)}</span>
                      </div>
                      <p class="activity-message">{activity.message}</p>
                      
                      {#if activity.actionUrl}
                        <a href={activity.actionUrl} use:link class="activity-action">
                          View Details →
                        </a>
                      {/if}
                    </div>
                    
                    {#if !activity.read}
                      <div class="unread-indicator"></div>
                    {/if}
                  </div>
                {/each}
              </div>
            {:else}
              <div class="empty-state">
                <p>No recent activity to show.</p>
              </div>
            {/if}
          </section>

          <!-- Applications Section -->
          <section class="applications-section">
            <div class="section-header">
              <h2>Applications</h2>
              <span class="count-badge">{applications.length} Applications</span>
            </div>

            <div class="applications-tabs">
              <button 
                class:active={activeApplicationTab === 'all'} 
                on:click={() => activeApplicationTab = 'all'}
              >
                All ({applications.length})
              </button>
              <button 
                class:active={activeApplicationTab === 'pending'} 
                on:click={() => activeApplicationTab = 'pending'}
              >
                Pending ({applications.filter(a => a.status === 'submitted' || a.status === 'reviewing').length})
              </button>
              <button 
                class:active={activeApplicationTab === 'accepted'} 
                on:click={() => activeApplicationTab = 'accepted'}
              >
                Accepted ({applications.filter(a => a.status === 'approved').length})
              </button>
              <button 
                class:active={activeApplicationTab === 'declined'} 
                on:click={() => activeApplicationTab = 'declined'}
              >
                Declined ({applications.filter(a => a.status === 'rejected').length})
              </button>
            </div>

            {#if filteredApplications.length > 0}
              <div class="applications-list">
                {#each filteredApplications.slice(0, 2) as application (application.id)}
                  <div class="application-card" in:fly={{ y: 20, duration: 300 }}>
                    <div class="applicant-avatar">
                      {#if application.profiles?.avatar_url}
                        <img src={application.profiles.avatar_url} alt="Applicant" />
                      {:else}
                        <div class="avatar-placeholder">
                          {application.profiles?.username?.[0]?.toUpperCase() || 'A'}
                        </div>
                      {/if}
                    </div>
                    
                    <div class="application-details">
                      <div class="applicant-info">
                        <h3 class="applicant-name">{application.profiles?.username || 'Unknown Applicant'}</h3>
                        <span class="applicant-role">{application.selected_mediums?.[0] || 'Artist'}</span>
                      </div>
                      
                      <div class="application-meta">
                        <span class="application-date">Applied {formatDate(application.created_at)}</span>
                      </div>
                    </div>
                    
                    <div class="application-actions">
                      <span class="status-badge {getStatusClass(application.status)}">
                        {getStatusBadge(application.status)}
                      </span>
                      
                      {#if application.status === 'submitted' || application.status === 'reviewing'}
                        {#if $user && application.pieces?.organizer_id && application.pieces?.organizer_user_id === $user.id}
                          <div class="action-buttons">
                            <a href="/review-application/{application.id}" use:link class="action-button review">
                              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                <circle cx="12" cy="12" r="3"></circle>
                              </svg>
                              Review
                            </a>
                          </div>
                        {:else}
                          <!-- If status is submitted/reviewing but user is not the organizer -->
                          <a href="/profile/{application.profiles?.username}" use:link class="action-button">
                            <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                              <circle cx="12" cy="12" r="3"></circle>
                            </svg>
                            View Portfolio
                          </a>
                        {/if}
                      {:else}
                        <!-- For other statuses (approved, rejected), always show View Portfolio -->
                        <a href="/profile/{application.profiles?.username}" use:link class="action-button">
                          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                            <circle cx="12" cy="12" r="3"></circle>
                          </svg>
                          View Portfolio
                        </a>
                      {/if}
                    </div>
                  </div>
                {/each}
              </div>
            {:else}
              <div class="empty-state">
                <p>No applications to show.</p>
              </div>
            {/if}
          </section>
        </div>

        <!-- Right Column -->
        <div class="dashboard-right">
          <!-- Timeline Reminders Section -->
          <section class="reminders-section">
            <div class="section-header">
              <h2>Timeline Reminders</h2>
            </div>

            {#if timelineReminders.length > 0}
              <div class="reminders-list">
                {#each timelineReminders as reminder, index (index)}
                  <div class="reminder-card" in:fly={{ y: 20, duration: 300, delay: index * 100 }}>
                    <div class="reminder-header">
                      <h3 class="reminder-title">{reminder.type}</h3>
                      <span class="days-badge days-{reminder.daysRemaining <= 3 ? 'critical' : reminder.daysRemaining <= 7 ? 'warning' : 'normal'}">
                        {reminder.daysRemaining} Days
                      </span>
                    </div>
                    <div class="reminder-project">
                      <span>{reminder.projectTitle}</span>
                    </div>
                    <div class="reminder-date">
                      <span>Due {reminder.formattedDate}</span>
                    </div>
                  </div>
                {/each}
              </div>
            {:else}
              <div class="empty-state">
                <p>No upcoming deadlines.</p>
              </div>
            {/if}
          </section>

          <!-- Impact Summary Section -->
          <section class="impact-section">
            <div class="section-header">
              <h2>Impact Summary</h2>
            </div>
            
            <div class="impact-content">
              <div class="impact-placeholder">
                <p>Your impact summary will appear here as you contribute to more projects.</p>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .dashboard-container {
    padding: var(--space-6);
    max-width: 1400px;
    margin: 0 auto;
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

  .error-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
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

  .dashboard-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  /* Welcome Header */
  .welcome-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-6);
  }

  .welcome-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0;
    color: var(--text-color);
  }

  .notification-bar {
    display: flex;
    gap: var(--space-4);
  }

  .notification-item {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    background: var(--bg-color);
    border: solid 1px var(--border-color);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    color: var(--text-color);
  }

  /* Dashboard Grid Layout */
  .dashboard-grid {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: var(--space-6);
  }

  .dashboard-left {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .dashboard-right {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  /* Section Styling */
  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-4);
  }

  .section-header h2 {
    font-size: 1.25rem;
    font-weight: 600;
    margin: 0;
    color: var(--text-color);
  }

  .count-badge {
    font-size: 0.875rem;
    padding: var(--space-1) var(--space-2);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    color: var(--text-muted);
  }

  /* Projects Section */
  .projects-section,
  .activity-section,
  .applications-section,
  .reminders-section,
  .impact-section {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    border: none;
  }

  .projects-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .project-card {
    display: flex;
    gap: var(--space-4);
    padding: var(--space-4);
    background: transparent;
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
  }

  .project-image {
    width: 80px;
    height: 80px;
    border-radius: var(--radius-md);
    overflow: hidden;
    flex-shrink: 0;
  }

  .project-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .image-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--color-neutral-100);
    color: var(--text-muted);
  }

  .project-details {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }

  .project-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: var(--space-2);
  }

  .project-title {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0;
    color: var(--text-color);
  }

  .project-status-badge {
    display: flex;
    align-items: center;
  }

  .status-badge {
    font-size: 0.75rem;
    font-weight: 500;
    position: relative;
    padding-left: 25px;
  }

  .status-badge.draft::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 16px;
    height: 16px;
    background-color: var(--color-neutral-400);
    border-radius: 50%;
  }

  .status-badge.open-to-applications::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 16px;
    height: 16px;
    background-color: var(--color-primary-00);
    border-radius: 50%;
  }

  .status-badge.seeking-funding::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 16px;
    height: 16px;
    background-color: var(--color-warning-500);
    border-radius: 50%;
  }

  .status-badge.published::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 16px;
    height: 16px;
    background-color: var(--color-success-500);
    border-radius: 50%;
  }

  .status-badge.status-pending::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 16px;
    height: 16px;
    background-color: var(--color-neutral-300);
    border-radius: 50%;
  }

  .status-badge.status-accepted::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 16px;
    height: 16px;
    background-color: var(--color-success-400);
    border-radius: 50%;
  }

  .status-badge.status-declined::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 16px;
    height: 16px;
    background-color: var(--color-error-400);
    border-radius: 50%;
  }

  .project-meta {
    display: flex;
    gap: var(--space-4);
    margin-bottom: var(--space-3);
  }

  .project-dates,
  .project-timeline {
    display: flex;
    align-items: center;
    gap: var(--space-1);
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .project-actions {
    display: flex;
    justify-content: flex-end;
  }

  .action-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-3);
    background: var(--bg-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    color: var(--text-color);
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    text-decoration: none;
    transition: all 0.2s;
  }

  .action-button:hover {
    background: var(--card-bg);
    outline: solid 1px var(--color-primary-500);
  }

  .action-button.dark {
    background: var(--color-neutral-900);
    color: white;
    border-color: var(--color-neutral-800);
  }

  .action-button.dark:hover {
    background: var(--color-neutral-800);
  }

  .action-button.review {
    background: var(--color-primary-600);
    color: white;
    border-color: var(--color-primary-700);
  }

  .action-button.review:hover {
    background: var(--color-primary-700);
  }

  .action-button.approve {
    background: var(--color-success-600);
    color: white;
    border-color: var(--color-success-700);
  }

  .action-button.approve:hover {
    background: var(--color-success-700);
  }

  .action-button.decline {
    background: var(--color-error-600);
    color: white;
    border-color: var(--color-error-700);
  }

  .action-button.decline:hover {
    background: var(--color-error-700);
  }

  /* Activity Section */
  .activity-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .activity-item {
    display: flex;
    gap: var(--space-3);
    padding: var(--space-4);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
    position: relative;
  }

  .activity-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    background-color: color-mix(in srgb, currentColor 10%, transparent);
    border-radius: 50%;
    flex-shrink: 0;
  }

  .activity-details {
    flex: 1;
  }

  .activity-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: var(--space-2);
  }

  .activity-title {
    font-size: 1rem;
    font-weight: 600;
    margin: 0;
    color: var(--text-color);
  }

  .activity-time {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .activity-message {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-2) 0;
    line-height: 1.4;
  }

  .activity-action {
    font-size: 0.875rem;
    color: var(--color-primary-600);
    text-decoration: none;
    display: inline-block;
  }

  .activity-action:hover {
    text-decoration: underline;
  }

  .unread-indicator {
    position: absolute;
    top: 12px;
    right: 12px;
    width: 8px;
    height: 8px;
    background-color: var(--color-primary-600);
    border-radius: 50%;
  }

  /* Applications Section */
  .applications-tabs {
    display: flex;
    gap: var(--space-2);
    margin-bottom: var(--space-4);
    border-bottom: 1px solid var(--border-color);
    padding-bottom: var(--space-2);
  }

  .applications-tabs button {
    background: none;
    border: none;
    padding: var(--space-2) var(--space-3);
    font-size: 0.875rem;
    color: var(--text-muted);
    cursor: pointer;
    border-radius: var(--radius-md);
    transition: all 0.2s;
  }

  .applications-tabs button:hover {
    background: var(--bg-color);
    color: var(--text-color);
  }

  .applications-tabs button.active {
    background: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .applications-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .application-card {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    padding: var(--space-4);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
  }

  .applicant-avatar {
    width: 60px;
    height: 60px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
  }

  .applicant-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--color-neutral-200);
    color: var(--color-neutral-600);
    font-size: 22px;
    font-weight: 600;
  }

  .application-details {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
  }

  .applicant-info {
    display: flex;
    flex-direction: column;
  }

  .applicant-name {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0;
    color: var(--text-color);
  }

  .applicant-role {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .application-meta {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .application-actions {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: var(--space-2);
  }

  .action-buttons {
    display: flex;
    gap: var(--space-2);
  }

  /* Reminders Section */
  .reminders-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .reminder-card {
    padding: var(--space-4);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
  }

  .reminder-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-2);
  }

  .reminder-title {
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0;
    color: var(--text-color);
    padding-right: 20px;
  }

  .days-badge {
    font-size: 0.75rem;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-full);
    font-weight: 500;
    white-space: nowrap;
  }

  .days-critical {
    background: var(--color-error-100);
    color: var(--color-error-700);
  }

  .days-warning {
    background: var(--color-warning-100);
    color: var(--color-warning-700);
  }

  .days-normal {
    background: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .reminder-project,
  .reminder-date {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-bottom: var(--space-1);
  }

  /* Impact Section */
  .impact-content {
    min-height: 200px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .impact-placeholder {
    text-align: center;
    color: var(--text-muted);
    padding: var(--space-4);
  }

  /* Empty States */
  .empty-state {
    text-align: center;
    padding: var(--space-6);
    color: var(--text-muted);
  }

  .empty-state p {
    margin-bottom: var(--space-4);
  }

  /* Responsive Adjustments */
  @media (max-width: 1024px) {
    .dashboard-grid {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 768px) {
    .dashboard-container {
      padding: var(--space-4);
    }

    .welcome-header {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-4);
    }

    .welcome-header h1 {
      font-size: 2rem;
    }

    .notification-bar {
      width: 100%;
      flex-direction: column;
      gap: var(--space-2);
    }

    .project-card,
    .activity-item,
    .application-card {
      flex-direction: column;
      align-items: flex-start;
    }

    .project-image {
      width: 100%;
      height: 160px;
    }

    .project-header {
      flex-direction: column;
      gap: var(--space-2);
    }

    .project-meta {
      flex-direction: column;
      gap: var(--space-2);
    }

    .project-actions,
    .activity-actions,
    .application-actions {
      width: 100%;
      justify-content: flex-start;
      margin-top: var(--space-3);
    }

    .applications-tabs {
      overflow-x: auto;
      padding-bottom: var(--space-2);
    }

    .applications-tabs button {
      white-space: nowrap;
    }
  }
</style>