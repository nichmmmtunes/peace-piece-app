<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  
  export let params = { id: '' };
  
  let application: any = null;
  let piece: any = null;
  let applicantProfile: any = null;
  let artistProfile: any = null;
  let loading = true;
  let error: string | null = null;
  let processing = false;
  let canReview = false;
  let feedbackNote = '';
  
  async function loadApplication() {
    try {
      loading = true;
      error = null;
      
      // Load application details
      const { data: applicationData, error: applicationError } = await supabase
        .from('applications')
        .select(`
          *,
          pieces:piece_id(*),
          profiles:applicant_profile_id(*)
        `)
        .eq('id', params.id)
        .single();
        
      if (applicationError) throw applicationError;
      
      application = applicationData;
      piece = application.pieces;
      applicantProfile = application.profiles;
      
      console.log('DEBUG: Current user ID (from $user store):', $user?.id);
      console.log('DEBUG: Piece ID from application:', piece.id);
      console.log('DEBUG: Piece organizer ID (from piece object):', piece.organizer_id);
      console.log('DEBUG: Applicant Profile ID (from application object):', applicantProfile.id);
      
      // Check if current user is the organizer of this piece
      if ($user && piece.organizer_id) {
        // Get the organizer data to check if current user owns this organizer
        const { data: organizerData, error: organizerError } = await supabase
          .from('organizers')
          .select('user_id')
          .eq('id', piece.organizer_id)
          .single();
      
        if (organizerError) {
          console.error('DEBUG: Error fetching organizer data:', organizerError);
        } else {
          console.log('DEBUG: Fetched organizer data (user_id):', organizerData?.user_id);
          if (organizerData && organizerData.user_id === $user.id) {
            canReview = true;
            console.log('DEBUG: User is identified as organizer, canReview set to true.');
          } else {
            console.log('DEBUG: User is NOT the organizer for this piece based on fetched organizer data.');
          }
        }
      } else {
        console.log('DEBUG: User not authenticated or piece.organizer_id is missing, skipping organizer check.');
      }
      
      // Load artist profile of the applicant
      const { data: artistData, error: artistError } = await supabase
        .from('artists')
        .select('*')
        .eq('user_id', applicantProfile.id)
        .maybeSingle();
        
      if (!artistError && artistData) {
        artistProfile = artistData;
      }
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
  
  async function updateApplicationStatus(newStatus: 'approved' | 'rejected') {
    if (!application || !canReview) return;
    
    try {
      processing = true;
      
      // Update application status
      const { error: updateError } = await supabase
        .from('applications')
        .update({ status: newStatus })
        .eq('id', application.id);
        
      if (updateError) throw updateError;
      
      // Create notification for the applicant
      const notificationTitle = newStatus === 'approved' 
        ? 'Application Approved!' 
        : 'Application Status Update';
        
      const notificationMessage = newStatus === 'approved'
        ? `Your application to contribute to "${piece.title}" has been approved! The organizer will be in touch with next steps.`
        : `Your application to contribute to "${piece.title}" was not selected at this time. ${feedbackNote}`;
        
      const notificationType = newStatus === 'approved' ? 'success' : 'info';
      
      await supabase
        .from('notifications')
        .insert({
          user_id: applicantProfile.id,
          title: notificationTitle,
          message: notificationMessage,
          type: notificationType,
          action_url: `/piece/${piece.id}`
        });
      
      // If approved, add the artist to the piece_artists table
      if (newStatus === 'approved' && artistProfile) {
        // Check if the artist is already a contributor to this piece
        const { data: existingContributor } = await supabase
          .from('piece_artists')
          .select('*')
          .eq('piece_id', piece.id)
          .eq('artist_id', artistProfile.id)
          .maybeSingle();
          
        if (!existingContributor) {
          // Get the selected mediums from the application
          const selectedMediums = application.selected_mediums || [];
          // Use the first selected medium as the role, or a default if none
          const role = selectedMediums.length > 0 ? selectedMediums[0] : 'Contributor';
          
          // Add the artist to the piece_artists table
          await supabase
            .from('piece_artists')
            .insert({
              piece_id: piece.id,
              artist_id: artistProfile.id,
              role: role
            });
        }
      }
      
      // Redirect back to dashboard after successful update
      push('/dashboard');
      
    } catch (e: any) {
      error = e.message;
    } finally {
      processing = false;
    }
  }
  
  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      year: 'numeric',
      month: 'long', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
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
    if (params.id) {
      loadApplication();
    }
  });
</script>

<div class="review-application">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading application details...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Error Loading Application</h2>
        <p>{error}</p>
        <a href="/dashboard" use:link class="primary">Back to Dashboard</a>
      </div>
    </div>
  {:else if !canReview}
    <div class="unauthorized-container" transition:fade>
      <div class="unauthorized-card">
        <h2>Access Denied</h2>
        <p>You don't have permission to review this application. Only the organizer of the piece can review applications.</p>
        <a href="/dashboard" use:link class="primary">Back to Dashboard</a>
      </div>
    </div>
  {:else if application}
    <div class="review-container">
      <!-- Header -->
      <div class="review-header" in:fade>
        <div class="breadcrumb">
          <a href="/dashboard" use:link>← Back to Dashboard</a>
        </div>
        <h1>Review Application</h1>
        <p>Review application for "{piece.title}"</p>
      </div>

      <!-- Application Details -->
      <div class="review-content" in:fly={{ y: 20, duration: 300 }}>
        <!-- Applicant Info -->
        <section class="applicant-section">
          <h2>Applicant Information</h2>
          
          <div class="applicant-profile">
            <div class="applicant-avatar">
              {#if applicantProfile.avatar_url}
                <img src={applicantProfile.avatar_url} alt={applicantProfile.username} />
              {:else}
                <div class="avatar-placeholder-initials">
                  {getInitials(applicantProfile.username)}
                </div>
              {/if}
            </div>
            
            <div class="applicant-details">
              <h3 class="applicant-name">{applicantProfile.username || 'Anonymous User'}</h3>
              
              {#if applicantProfile.website}
                <a href={applicantProfile.website} target="_blank" rel="noopener noreferrer" class="applicant-website">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path>
                    <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path>
                  </svg>
                  {applicantProfile.website}
                </a>
              {/if}
              
              <div class="applicant-meta">
                <span class="application-date">Applied on {formatDate(application.created_at)}</span>
                
                {#if application.portfolio_url}
                  <a href={application.portfolio_url} target="_blank" rel="noopener noreferrer" class="portfolio-link">
                    <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>
                      <polyline points="15 3 21 3 21 9"></polyline>
                      <line x1="10" y1="14" x2="21" y2="3"></line>
                    </svg>
                    View Portfolio
                  </a>
                {/if}
                
                <a href={`/profile/${applicantProfile.username}`} use:link class="profile-link">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                  </svg>
                  View Full Profile
                </a>
              </div>
            </div>
          </div>
          
          {#if artistProfile}
            <div class="artist-info">
              <h3>Artist Profile</h3>
              
              <div class="artist-bio">
                <p>{artistProfile.bio || 'No artist bio provided.'}</p>
              </div>
              
              {#if artistProfile.artistic_mediums && artistProfile.artistic_mediums.length > 0}
                <div class="artist-mediums">
                  <h4>Artistic Mediums</h4>
                  <div class="mediums-list">
                    {#each artistProfile.artistic_mediums as medium}
                      <span class="medium-tag">{medium}</span>
                    {/each}
                  </div>
                </div>
              {/if}
            </div>
          {/if}
        </section>
        
        <!-- Application Details -->
        <section class="application-details-section">
          <h2>Application Details</h2>
          
          {#if application.selected_mediums && application.selected_mediums.length > 0}
            <div class="selected-mediums">
              <h3>Selected Mediums</h3>
              <div class="mediums-list">
                {#each application.selected_mediums as medium}
                  <span class="medium-tag">{medium}</span>
                {/each}
              </div>
            </div>
          {/if}
          
          <div class="pitch-section">
            <h3>Why they're a good fit</h3>
            <div class="pitch-content">
              <p>{application.pitch_fit}</p>
            </div>
          </div>
          
          <div class="pitch-section">
            <h3>Why they believe in this cause</h3>
            <div class="pitch-content">
              <p>{application.pitch_cause}</p>
            </div>
          </div>
        </section>
        
        <!-- Review Decision -->
        <section class="decision-section">
          <h2>Review Decision</h2>
          
          <div class="feedback-form">
            <label for="feedback">Feedback Note (optional)</label>
            <textarea 
              id="feedback" 
              bind:value={feedbackNote} 
              placeholder="Add a personal note or feedback for the applicant..."
              rows="3"
            ></textarea>
            <p class="feedback-help">This note will be included in the notification to the applicant if you decline their application.</p>
          </div>
          
          <div class="decision-actions">
            <button 
              class="decline-button" 
              on:click={() => updateApplicationStatus('rejected')}
              disabled={processing}
            >
              {#if processing}
                <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                    <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                  </circle>
                </svg>
                Processing...
              {:else}
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
                Decline Application
              {/if}
            </button>
            
            <button 
              class="approve-button" 
              on:click={() => updateApplicationStatus('approved')}
              disabled={processing}
            >
              {#if processing}
                <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                    <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                  </circle>
                </svg>
                Processing...
              {:else}
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                Approve Application
              {/if}
            </button>
          </div>
        </section>
      </div>
    </div>
  {/if}
</div>

<style>
  .review-application {
    padding: var(--space-6);
    max-width: 900px;
    margin: 0 auto;
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

  .error-container,
  .unauthorized-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
  }

  .error-card,
  .unauthorized-card {
    background: var(--card-bg);
    border: 1px solid var(--color-error-200);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    max-width: 500px;
  }

  .error-card h2,
  .unauthorized-card h2 {
    color: var(--color-error-600);
    margin-bottom: var(--space-4);
  }

  .review-container {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .review-header {
    text-align: center;
  }

  .breadcrumb {
    margin-bottom: var(--space-4);
  }

  .breadcrumb a {
    color: var(--text-muted);
    text-decoration: none;
    font-size: 0.875rem;
    display: inline-flex;
    align-items: center;
    gap: var(--space-1);
  }

  .breadcrumb a:hover {
    text-decoration: underline;
  }

  .review-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .review-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
    margin: 0;
  }

  .review-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .applicant-section,
  .application-details-section,
  .decision-section {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .applicant-section h2,
  .application-details-section h2,
  .decision-section h2 {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
    padding-bottom: var(--space-2);
    border-bottom: 1px solid var(--border-color);
  }

  .applicant-profile {
    display: flex;
    gap: var(--space-4);
    margin-bottom: var(--space-6);
  }

  .applicant-avatar {
    width: 80px;
    height: 97px;
    border-radius: 100px;
    overflow: hidden;
    flex-shrink: 0;
  }

  .applicant-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder-initials {
    width: 100%;
    height: 100%;
    background-color: var(--color-neutral-400);
    color: var(--color-neutral-800);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2rem;
    font-weight: 600;
  }

  .applicant-details {
    flex: 1;
  }

  .applicant-name {
    font-size: 1.5rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .applicant-website {
    display: flex;
    align-items: center;
    gap: var(--space-1);
    color: var(--color-primary-600);
    text-decoration: none;
    margin-bottom: var(--space-2);
    font-size: 0.875rem;
  }

  .applicant-website:hover {
    text-decoration: underline;
  }

  .applicant-meta {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-3);
    margin-top: var(--space-2);
  }

  .application-date {
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .portfolio-link,
  .profile-link {
    display: flex;
    align-items: center;
    gap: var(--space-1);
    color: var(--color-primary-600);
    text-decoration: none;
    font-size: 0.875rem;
  }

  .portfolio-link:hover,
  .profile-link:hover {
    text-decoration: underline;
  }

  .artist-info {
    margin-top: var(--space-4);
    padding-top: var(--space-4);
    border-top: 1px solid var(--border-color);
  }

  .artist-info h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .artist-bio {
    margin-bottom: var(--space-4);
  }

  .artist-bio p {
    color: var(--text-color);
    line-height: 1.6;
    margin: 0;
  }

  .artist-mediums h4 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .mediums-list {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }

  .medium-tag {
    display: inline-block;
    padding: var(--space-1) var(--space-2);
    background-color: var(--color-success-100);
    color: var(--color-success-700);
    border-radius: var(--radius-md);
    font-size: 0.75rem;
    font-weight: 500;
  }

  .selected-mediums {
    margin-bottom: var(--space-4);
  }

  .selected-mediums h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .pitch-section {
    margin-bottom: var(--space-4);
  }

  .pitch-section:last-child {
    margin-bottom: 0;
  }

  .pitch-section h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .pitch-content {
    background-color: var(--bg-color);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    border: 1px solid var(--border-color);
  }

  .pitch-content p {
    color: var(--text-color);
    line-height: 1.6;
    margin: 0;
    white-space: pre-line;
  }

  .feedback-form {
    margin-bottom: var(--space-6);
  }

  .feedback-form label {
    display: block;
    font-weight: 500;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .feedback-form textarea {
    width: 100%;
    padding: var(--space-3);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    background: var(--bg-color);
    color: var(--text-color);
    font-size: 1rem;
    transition: border-color 0.2s, box-shadow 0.2s;
    resize: vertical;
  }

  .feedback-form textarea:focus {
    outline: none;
    border-color: var(--color-primary-500);
    box-shadow: 0 0 0 3px var(--color-primary-100);
  }

  .feedback-help {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-top: var(--space-2);
  }

  .decision-actions {
    display: flex;
    gap: var(--space-4);
  }

  .decline-button,
  .approve-button {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3);
    border-radius: var(--radius-md);
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .decline-button {
    background-color: var(--color-error-600);
    color: white;
    border: none;
  }

  .decline-button:hover:not(:disabled) {
    background-color: var(--color-error-700);
  }

  .approve-button {
    background-color: var(--color-success-600);
    color: white;
    border: none;
  }

  .approve-button:hover:not(:disabled) {
    background-color: var(--color-success-700);
  }

  .decline-button:disabled,
  .approve-button:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .spinner {
    animation: spin 1s linear infinite;
  }

  @media (max-width: 768px) {
    .review-application {
      padding: var(--space-4);
    }

    .review-header h1 {
      font-size: 2rem;
    }

    .applicant-profile {
      flex-direction: column;
      align-items: center;
      text-align: center;
    }

    .applicant-meta {
      justify-content: center;
    }

    .decision-actions {
      flex-direction: column;
    }
  }
</style>