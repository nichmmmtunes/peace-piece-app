<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import DonateButton from './DonateButton.svelte';

  export let params = { id: '' };
  
  let piece: any = null;
  let applications: any[] = [];
  let donations: any[] = [];
  let loading = true;
  let error: string | null = null;
  let stats = {
    totalDonations: 0,
    totalDonors: 0,
    pendingApplications: 0,
    approvedApplications: 0
  };
  
  // Sponsor management
  let sponsors: any[] = [];
  let allSponsors: any[] = [];
  let showSponsorModal = false;
  let editingSponsorId: string | null = null;
  let sponsorName = '';
  let sponsorAmount: number | null = null;
  let sponsorId = '';
  
  async function loadPieceData() {
    try {
      loading = true;
      error = null;
      
      // Load piece details
      const { data: pieceData, error: pieceError } = await supabase
        .from('piece_details')
        .select('*')
        .eq('id', params.id)
        .single();
        
      if (pieceError) throw pieceError;
      
      // Verify the current user is the organizer
      if (pieceData.organizer_user_id !== $user?.id) {
        throw new Error('You do not have permission to manage this piece');
      }
      
      piece = pieceData;
      
      // Load applications for this piece
      const { data: applicationsData, error: applicationsError } = await supabase
        .from('applications')
        .select(`
          *,
          profiles:applicant_profile_id(
            username,
            avatar_url
          )
        `)
        .eq('piece_id', params.id)
        .order('created_at', { ascending: false });
        
      if (applicationsError) throw applicationsError;
      
      applications = applicationsData || [];
      
      // Calculate application stats
      stats.pendingApplications = applications.filter(app => 
        app.status === 'submitted' || app.status === 'reviewing'
      ).length;
      
      stats.approvedApplications = applications.filter(app => 
        app.status === 'approved'
      ).length;
      
      // Load donations for this piece
      const { data: donationsData, error: donationsError } = await supabase
        .from('stripe_orders')
        .select('*')
        .eq('piece_id', params.id)
        .eq('status', 'completed')
        .order('created_at', { ascending: false });
        
      if (donationsError) throw donationsError;
      
      donations = donationsData || [];
      
      // Calculate donation stats
      stats.totalDonations = donations.reduce((sum, donation) => sum + donation.amount_total, 0);
      stats.totalDonors = new Set(donations.map(d => d.customer_id)).size;
      
      // Extract sponsors from piece data
      if (piece.sponsors && Array.isArray(piece.sponsors)) {
        sponsors = piece.sponsors;
      }
      
      // Load all available sponsors for the dropdown
      await loadAllSponsors();
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
  
  async function loadAllSponsors() {
    try {
      const { data, error } = await supabase
        .from('sponsors')
        .select('*')
        .order('name');
        
      if (error) throw error;
      
      allSponsors = data || [];
    } catch (e: any) {
      console.error('Error loading sponsors:', e);
    }
  }
  
  function formatAmount(amount: number): string {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount / 100); // Convert cents to dollars
  }
  
  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  }
  
  function getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'submitted':
        return 'status-pending';
      case 'reviewing':
        return 'status-reviewing';
      case 'approved':
        return 'status-approved';
      case 'rejected':
        return 'status-rejected';
      default:
        return 'status-pending';
    }
  }
  
  function getStatusLabel(status: string): string {
    switch (status) {
      case 'submitted':
        return 'Pending';
      case 'reviewing':
        return 'Reviewing';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Declined';
      default:
        return 'Pending';
    }
  }
  
  async function updateProjectStatus(newStatus: string) {
    try {
      loading = true;
      
      const { error: updateError } = await supabase
        .from('pieces')
        .update({
          project_status: newStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', params.id);
        
      if (updateError) throw updateError;
      
      // Reload piece data to get updated status
      await loadPieceData();
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
  
  // Sponsor management functions
  function openSponsorModal(sponsor: any = null) {
    if (sponsor) {
      // Edit existing sponsor
      editingSponsorId = sponsor.id;
      sponsorId = sponsor.id;
      sponsorName = sponsor.name;
      sponsorAmount = sponsor.amount;
    } else {
      // Add new sponsor
      editingSponsorId = null;
      sponsorId = '';
      sponsorName = '';
      sponsorAmount = null;
    }
    
    showSponsorModal = true;
  }
  
  function closeSponsorModal() {
    showSponsorModal = false;
    editingSponsorId = null;
    sponsorId = '';
    sponsorName = '';
    sponsorAmount = null;
  }
  
  async function saveSponsor() {
    try {
      if (!sponsorId && !sponsorName) {
        throw new Error('Please select or enter a sponsor name');
      }
      
      if (!sponsorAmount) {
        throw new Error('Please enter a sponsorship amount');
      }
      
      loading = true;
      
      // If editing an existing sponsor
      if (editingSponsorId) {
        // First delete the existing relationship
        const { error: deleteError } = await supabase
          .from('piece_sponsors')
          .delete()
          .eq('piece_id', params.id)
          .eq('sponsor_id', editingSponsorId);
          
        if (deleteError) throw deleteError;
      }
      
      // If using an existing sponsor
      if (sponsorId) {
        // Insert the piece_sponsors relationship
        const { error: insertError } = await supabase
          .from('piece_sponsors')
          .insert({
            piece_id: params.id,
            sponsor_id: sponsorId,
            amount: sponsorAmount * 100 // Convert to cents
          });
          
        if (insertError) throw insertError;
      } else {
        // Create a new sponsor first
        const { data: newSponsor, error: sponsorError } = await supabase
          .from('sponsors')
          .insert({
            name: sponsorName,
            logo_url: null,
            website: null
          })
          .select('id')
          .single();
          
        if (sponsorError) throw sponsorError;
        
        // Then create the relationship
        const { error: relationError } = await supabase
          .from('piece_sponsors')
          .insert({
            piece_id: params.id,
            sponsor_id: newSponsor.id,
            amount: sponsorAmount * 100 // Convert to cents
          });
          
        if (relationError) throw relationError;
      }
      
      // Reload piece data to get updated sponsors
      await loadPieceData();
      closeSponsorModal();
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
  
  async function deleteSponsor(sponsorId: string) {
    if (!confirm('Are you sure you want to remove this sponsor?')) return;
    
    try {
      loading = true;
      
      const { error: deleteError } = await supabase
        .from('piece_sponsors')
        .delete()
        .eq('piece_id', params.id)
        .eq('sponsor_id', sponsorId);
        
      if (deleteError) throw deleteError;
      
      // Reload piece data to get updated sponsors
      await loadPieceData();
      
    } catch (e: any) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
  
  onMount(() => {
    if (params.id) {
      loadPieceData();
    }
  });
</script>

<div class="manage-piece-container">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading management dashboard...</p>
    </div>
  {:else if error}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Error</h2>
        <p>{error}</p>
        <a href="/dashboard" use:link class="primary">Back to Dashboard</a>
      </div>
    </div>
  {:else if piece}
    <div class="manage-content" in:fly={{ y: 20, duration: 300 }}>
      <div class="manage-header">
        <div class="breadcrumb">
          <a href="/piece/{piece.id}" use:link>← Back to Piece Details</a>
        </div>
        <h1>Manage "{piece.title}"</h1>
      </div>

      <!-- Status and Quick Stats -->
      <div class="status-bar">
        <div class="status-badge" class:status-open={piece.project_status === 'open_to_applications'} class:status-funding={piece.project_status === 'seeking_funding'} class:status-published={piece.project_status === 'published'}>
          <span>Status: {piece.project_status === 'open_to_applications' ? 'Open to Applications' : piece.project_status === 'seeking_funding' ? 'Seeking Funding' : 'Published'}</span>
        </div>
        
        <div class="quick-stats">
          <div class="stat-item">
            <span class="stat-value">${piece.amount_raised || 0}</span>
            <span class="stat-label">Raised</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{stats.totalDonors}</span>
            <span class="stat-label">Donors</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{stats.pendingApplications}</span>
            <span class="stat-label">Pending Applications</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{stats.approvedApplications}</span>
            <span class="stat-label">Approved Artists</span>
          </div>
        </div>
      </div>

      <div class="manage-grid">
        <!-- Applications Section -->
        <section class="applications-section card">
          <h2>Artist Applications</h2>
          
          {#if applications.length > 0}
            <div class="applications-list">
              {#each applications.slice(0, 5) as application}
                <div class="application-item">
                  <div class="applicant-info">
                    <div class="applicant-avatar">
                      {#if application.profiles?.avatar_url}
                        <img src={application.profiles.avatar_url} alt="Applicant" />
                      {:else}
                        <div class="avatar-placeholder">
                          {application.profiles?.username?.[0]?.toUpperCase() || 'A'}
                        </div>
                      {/if}
                    </div>
                    <div class="applicant-details">
                      <h3>{application.profiles?.username || 'Anonymous'}</h3>
                      <p class="application-date">Applied on {formatDate(application.created_at)}</p>
                    </div>
                  </div>
                  
                  <div class="application-actions">
                    <span class="status-badge {getStatusBadgeClass(application.status)}">
                      {getStatusLabel(application.status)}
                    </span>
                    <a href="/review-application/{application.id}" use:link class="review-button">
                      Review
                    </a>
                  </div>
                </div>
              {/each}
              
              {#if applications.length > 5}
                <div class="view-all">
                  <button class="view-all-button">View All Applications ({applications.length})</button>
                </div>
              {/if}
            </div>
          {:else}
            <div class="empty-state">
              <p>No applications received yet.</p>
            </div>
          {/if}
        </section>

        <!-- Donations Section -->
        <section class="donations-section card">
          <h2>Donations & Payouts</h2>
          
          <div class="donation-summary">
            <div class="summary-card">
              <h3>Total Raised</h3>
              <div class="amount">${piece.amount_raised || 0}</div>
              
              {#if piece.funding_goal}
                <div class="progress-container">
                  <div class="progress-bar">
                    <div 
                      class="progress-fill" 
                      style="width: {Math.min(100, ((piece.amount_raised || 0) / piece.funding_goal) * 100)}%"
                    ></div>
                  </div>
                  <div class="progress-text">
                    <span>{Math.round(((piece.amount_raised || 0) / piece.funding_goal) * 100)}% of {formatAmount(piece.funding_goal)}</span>
                  </div>
                </div>
              {/if}
            </div>
            
            <div class="summary-card">
              <h3>Artist Fees</h3>
              <div class="amount">{formatAmount(piece.artist_fees || 0)}</div>
              <p class="fees-note">Fees will be distributed to approved artists</p>
            </div>
          </div>
          
          {#if donations.length > 0}
            <h3>Recent Donations</h3>
            <div class="donations-list">
              {#each donations.slice(0, 5) as donation}
                <div class="donation-item">
                  <div class="donation-info">
                    <span class="donation-amount">{formatAmount(donation.amount_total)}</span>
                    <span class="donation-date">{formatDate(donation.created_at)}</span>
                  </div>
                </div>
              {/each}
              
              {#if donations.length > 5}
                <div class="view-all">
                  <button class="view-all-button">View All Donations ({donations.length})</button>
                </div>
              {/if}
            </div>
          {:else}
            <div class="empty-state">
              <p>No donations received yet.</p>
              <p>Share your piece to start receiving support.</p>
            </div>
          {/if}
        </section>

        <!-- Sponsors Section -->
        <section class="sponsors-section card">
          <h2>Sponsors</h2>
          
          {#if sponsors && sponsors.length > 0}
            <div class="sponsors-list">
              {#each sponsors as sponsor}
                <div class="sponsor-item">
                  <div class="sponsor-info">
                    <span class="sponsor-name">{sponsor.name}</span>
                    <span class="sponsor-amount">{formatAmount(sponsor.amount)}</span>
                  </div>
                  <div class="sponsor-actions">
                    <button class="edit-sponsor-btn" on:click={() => openSponsorModal(sponsor)}>Edit</button>
                    <button class="delete-sponsor-btn" on:click={() => deleteSponsor(sponsor.id)}>Remove</button>
                  </div>
                </div>
              {/each}
            </div>
          {:else}
            <div class="empty-state">
              <p>No sponsors yet.</p>
              <p>Add sponsors to support your piece.</p>
            </div>
          {/if}
          
          <button class="add-sponsor-btn action-button" on:click={() => openSponsorModal()}>
            <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            Add New Sponsor
          </button>
        </section>

        <!-- Piece Actions -->
        <section class="piece-actions card">
          <h2>Piece Actions</h2>
          
          <div class="action-buttons">
            <a href="/update/{piece.id}" use:link class="action-button">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
              Edit Details
            </a>
            
            <a href="/edit/{piece.id}" use:link class="action-button">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <path d="M15 10l4.553-2.276A1 1 0 0 1 21 8.618v6.764a1 1 0 0 1-1.447.894L15 14M5 18h8a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2z"></path>
              </svg>
              Media Editor
            </a>
            
            <div class="status-actions">
              <h3>Change Status</h3>
              <div class="status-buttons">
                <button 
                  class="status-button" 
                  class:active={piece.project_status === 'open_to_applications'}
                  on:click={() => updateProjectStatus('open_to_applications')}
                  disabled={piece.project_status === 'open_to_applications'}
                >
                  Open to Applications
                </button>
                
                <button 
                  class="status-button" 
                  class:active={piece.project_status === 'seeking_funding'}
                  on:click={() => updateProjectStatus('seeking_funding')}
                  disabled={piece.project_status === 'seeking_funding'}
                >
                  Seeking Funding
                </button>
                
                <button 
                  class="status-button" 
                  class:active={piece.project_status === 'published'}
                  on:click={() => updateProjectStatus('published')}
                  disabled={piece.project_status === 'published'}
                >
                  Published
                </button>
              </div>
            </div>
          </div>
          
          <div class="billing-settings">
            <h3>Billing & Payout Settings</h3>
            <p>Configure your payment methods and payout preferences.</p>
            <button class="billing-button">
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect>
                <line x1="1" y1="10" x2="23" y2="10"></line>
              </svg>
              Configure Billing
            </button>
          </div>
        </section>
      </div>
    </div>
    
    <!-- Sponsor Modal -->
    {#if showSponsorModal}
      <div class="modal-overlay" on:click={closeSponsorModal}>
        <div class="modal-content" on:click|stopPropagation>
          <div class="modal-header">
            <h3>{editingSponsorId ? 'Edit Sponsor' : 'Add New Sponsor'}</h3>
            <button class="close-modal-btn" on:click={closeSponsorModal}>×</button>
          </div>
          
          <div class="modal-body">
            <div class="form-group">
              <label for="sponsorSelect">Select Existing Sponsor</label>
              <select 
                id="sponsorSelect" 
                bind:value={sponsorId}
                disabled={loading}
              >
                <option value="">-- Create New Sponsor --</option>
                {#each allSponsors as sponsor}
                  <option value={sponsor.id}>{sponsor.name}</option>
                {/each}
              </select>
            </div>
            
            {#if !sponsorId}
              <div class="form-group">
                <label for="sponsorName">Sponsor Name</label>
                <input 
                  type="text" 
                  id="sponsorName" 
                  bind:value={sponsorName}
                  placeholder="Enter sponsor name"
                  disabled={loading}
                />
              </div>
            {/if}
            
            <div class="form-group">
              <label for="sponsorAmount">Sponsorship Amount ($)</label>
              <input 
                type="number" 
                id="sponsorAmount" 
                bind:value={sponsorAmount}
                placeholder="Enter amount"
                min="1"
                step="100"
                disabled={loading}
              />
            </div>
          </div>
          
          <div class="modal-footer">
            <button class="cancel-btn" on:click={closeSponsorModal} disabled={loading}>Cancel</button>
            <button class="save-btn" on:click={saveSponsor} disabled={loading || (!sponsorId && !sponsorName) || !sponsorAmount}>
              {#if loading}
                <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                    <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                  </circle>
                </svg>
                Saving...
              {:else}
                Save Sponsor
              {/if}
            </button>
          </div>
        </div>
      </div>
    {/if}
  {/if}
</div>

<style>
  .manage-piece-container {
    padding: var(--space-8) var(--space-6) var(--space-6);
    max-width: 1200px;
    margin: 0 auto 0 0;
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
    min-height: 400px;
  }

  .error-card {
    background: var(--card-bg);
    border: 1px solid var(--color-error-200);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    max-width: 500px;
  }

  .error-card h2 {
    color: var(--color-error-600);
    margin-bottom: var(--space-4);
  }

  .manage-header {
    text-align: center;
    margin-bottom: var(--space-6);
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

  .manage-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .manage-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
    margin: 0;
  }

  .status-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-4) var(--space-6);
    margin-bottom: var(--space-6);
  }

  .status-badge {
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    font-weight: 500;
    font-size: 0.875rem;
  }

  .status-badge.status-open {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .status-badge.status-funding {
    background-color: var(--color-warning-100);
    color: var(--color-warning-700);
  }

  .status-badge.status-published {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .quick-stats {
    display: flex;
    gap: var(--space-6);
  }

  .stat-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .stat-value {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--text-color);
  }

  .stat-label {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .manage-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-6);
  }

  :global(.light-mode) .manage-grid section {
    background: var(--bg-color);
  }

  .card {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .applications-section {
    grid-column: 1;
    grid-row: 1 / 3;
  }

  .donations-section {
    grid-column: 2;
    grid-row: 1;
  }

  .sponsors-section {
    grid-column: 1;
    grid-row: 3;
  }

  .piece-actions {
    grid-column: 2;
    grid-row: 2 / 4;
  }

  .card h2 {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
    padding-bottom: var(--space-3);
    border-bottom: 1px solid var(--border-color);
  }

  .card h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: var(--space-4) 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .applications-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .application-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--space-3);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    border: none;
  }

  .applicant-info {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .applicant-avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    overflow: hidden;
  }

  .applicant-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder {
    width: 100%;
    height: 100%;
    background-color: var(--color-primary-400);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 500;
  }

  .applicant-details h3 {
    font-size: 0.875rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .application-date {
    font-size: 0.75rem;
    color: var(--text-muted);
    margin: 0;
  }

  .application-actions {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .status-badge {
    font-size: 0.75rem;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-sm);
  }

  .status-badge.status-pending {
    background-color: var(--color-warning-100);
    color: var(--color-warning-700);
  }

  .status-badge.status-reviewing {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }

  .status-badge.status-approved {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }

  .status-badge.status-rejected {
    background-color: var(--color-error-100);
    color: var(--color-error-700);
  }

  .review-button {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: var(--space-1) var(--space-3);
    background-color: var(--color-primary-600);
    color: white;
    border-radius: var(--radius-md);
    text-decoration: none;
    font-size: 0.75rem;
    font-weight: 500;
    transition: background-color 0.2s;
  }

  .review-button:hover {
    background-color: var(--color-primary-700);
  }

  .donation-summary {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-4);
    margin-bottom: var(--space-6);
  }

  .summary-card {
    background: var(--bg-color);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    border: none;
  }

  .summary-card h3 {
    font-size: 0.875rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .amount {
    font-size: 1.5rem;
    font-weight: 600;
    color: var(--text-color);
    margin-bottom: var(--space-2);
  }

  .progress-container {
    margin-top: var(--space-2);
  }

  .progress-bar {
    height: 8px;
    background-color: var(--color-neutral-200);
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: var(--space-1);
  }

  .progress-fill {
    height: 100%;
    background-color: var(--color-success-600);
    border-radius: 4px;
  }

  .progress-text {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-align: right;
  }

  .fees-note {
    font-size: 0.75rem;
    color: var(--text-muted);
    margin: 0;
  }

  .donations-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .donation-item {
    padding: var(--space-2) var(--space-3);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    border: none;
  }

  .donation-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .donation-amount {
    font-weight: 500;
    color: var(--text-color);
  }

  .donation-date {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .sponsors-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
    margin-bottom: var(--space-4);
  }

  .sponsor-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--space-2) var(--space-3);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    border: none;
  }

  .sponsor-info {
    display: flex;
    flex-direction: column;
  }

  .sponsor-name {
    font-weight: 500;
    color: var(--text-color);
  }

  .sponsor-amount {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .sponsor-actions {
    display: flex;
    gap: var(--space-2);
  }

  .edit-sponsor-btn, .delete-sponsor-btn {
    background: none;
    border: none;
    font-size: 0.75rem;
    cursor: pointer;
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-sm);
    transition: all 0.2s;
  }

  .edit-sponsor-btn {
    color: var(--color-primary-600);
  }

  .edit-sponsor-btn:hover {
    background-color: var(--color-primary-50);
  }

  .delete-sponsor-btn {
    color: var(--color-error-600);
  }

  .delete-sponsor-btn:hover {
    background-color: var(--color-error-50);
  }

  .add-sponsor-btn {
    margin-top: var(--space-3);
    width: 100%;
  }

  .action-buttons {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .action-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3);
    background-color: var(--bg-color);
    color: var(--text-color);
    border-radius: 50px;
    text-decoration: none;
    font-weight: 500;
    transition: background-color 0.2s;
    border: none;
  }

  :global(.light-mode) .action-button {
    background: var(--card-bg);
  }

  .status-actions {
    margin-top: var(--space-4);
    padding-top: var(--space-4);
    border-top: 1px solid var(--border-color);
  }

  .status-buttons {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .status-button {
    padding: var(--space-2) var(--space-3);
    background-color: var(--bg-color);
    color: var(--text-color);
    border: none;
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
    border: none;
  }

  :global(.light-mode) .status-button {
    background: var(--card-bg);
  }

  .status-button.active {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
    border-color: var(--color-primary-300);
  }

  :global(.light-mode) .status-button.active {
    background: var(--color-neutral-200);
    color: #000;
  }


  .status-button:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .billing-settings {
    margin-top: var(--space-6);
    padding-top: var(--space-4);
    border-top: 1px solid var(--border-color);
  }

  .billing-settings p {
    color: var(--text-muted);
    font-size: 0.875rem;
    margin-bottom: var(--space-3);
  }

  .billing-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    width: 100%;
    padding: var(--space-3);
    background-color: var(--bg-color);
    color: var(--text-color);
    border: none;
    border-radius: 50px;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .empty-state {
    text-align: center;
    padding: var(--space-6);
    color: var(--text-muted);
  }

  .view-all {
    text-align: center;
    margin-top: var(--space-3);
  }

  .view-all-button {
    background: none;
    border: none;
    color: var(--color-primary-600);
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    transition: background-color 0.2s;
  }

  .view-all-button:hover {
    background-color: var(--color-primary-50);
  }

  /* Modal Styles */
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: var(--space-4);
  }

  .modal-content {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    width: 100%;
    max-width: 500px;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
  }

  .modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--space-4) var(--space-6);
    border-bottom: 1px solid var(--border-color);
  }

  .modal-header h3 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 500;
  }

  .close-modal-btn {
    background: none;
    border: none;
    font-size: 1.5rem;
    color: var(--text-muted);
    cursor: pointer;
    padding: 0;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: background-color 0.2s;
  }

  .close-modal-btn:hover {
    background-color: var(--border-color);
    color: var(--text-color);
  }

  .modal-body {
    padding: var(--space-6);
  }

  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: var(--space-3);
    padding: var(--space-4) var(--space-6);
    border-top: 1px solid var(--border-color);
  }

  .cancel-btn {
    padding: var(--space-2) var(--space-4);
    background: var(--bg-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .cancel-btn:hover {
    background-color: var(--color-neutral-100);
  }

  .save-btn {
    padding: var(--space-2) var(--space-4);
    background-color: var(--color-primary-600);
    color: white;
    border: none;
    border-radius: var(--radius-md);
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    gap: var(--space-2);
  }

  .save-btn:hover:not(:disabled) {
    background-color: var(--color-primary-700);
  }

  .save-btn:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  @media (max-width: 1024px) {
    .manage-grid {
      grid-template-columns: 1fr;
    }

    .applications-section,
    .donations-section,
    .sponsors-section,
    .piece-actions {
      grid-column: 1;
      grid-row: auto;
    }
  }

  @media (max-width: 768px) {
    .manage-piece-container {
      padding: var(--space-4);
    }

    .manage-header h1 {
      font-size: 2rem;
    }

    .status-bar {
      flex-direction: column;
      gap: var(--space-4);
      align-items: flex-start;
    }

    .quick-stats {
      width: 100%;
      justify-content: space-between;
    }

    .donation-summary {
      grid-template-columns: 1fr;
    }

    .sponsor-item {
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-2);
    }

    .sponsor-actions {
      align-self: flex-end;
    }
  }
</style>