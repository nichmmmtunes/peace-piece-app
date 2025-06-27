<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  
  export let params = { id: '' };
  
  let piece: any = null;
  let loading = true;
  let submitting = false;
  let componentError: string | null = null;
  let success = false;
  let artistProfile: any = null;
  let hasExistingApplication = false;
  
  // Form fields
  let selectedMediums: string[] = [];
  let pitchFit = '';
  let pitchCause = '';
  let portfolioUrl = '';
  
  async function loadPiece() {
    try {
      loading = true;
      componentError = null;
      
      const { data, error: pieceError } = await supabase
        .from('piece_details')
        .select('*')
        .eq('id', params.id)
        .single();
        
      if (pieceError) throw pieceError;
      
      piece = data;
      
      // Check if the user has an artist profile
      await checkArtistProfile();
      
      // Check if the user already has an application for this piece
      await checkExistingApplication();
      
    } catch (e: any) {
      componentError = e.message;
    } finally {
      loading = false;
    }
  }
  
  async function checkArtistProfile() {
    if (!$user) return;
    
    try {
      const { data, error } = await supabase
        .from('artists')
        .select('*')
        .eq('user_id', $user.id)
        .maybeSingle();
        
      if (error) throw error;
      
      artistProfile = data;
      
      if (!artistProfile) {
        componentError = 'You need to create an artist profile before applying to this piece.';
      }
    } catch (e: any) {
      console.error('Error checking artist profile:', e);
    }
  }
  
  async function checkExistingApplication() {
    if (!$user) return;
    
    try {
      const { data, error } = await supabase
        .from('applications')
        .select('*')
        .eq('piece_id', params.id)
        .eq('applicant_profile_id', $user.id)
        .maybeSingle();
        
      if (error) throw error;
      
      hasExistingApplication = !!data;
      
      if (hasExistingApplication) {
        componentError = 'You have already applied to this piece.';
      }
    } catch (e: any) {
      console.error('Error checking existing application:', e);
    }
  }
  
  function toggleMedium(medium: string) {
    if (selectedMediums.includes(medium)) {
      selectedMediums = selectedMediums.filter(m => m !== medium);
    } else {
      selectedMediums = [...selectedMediums, medium];
    }
  }
  
  async function submitApplication() {
    if (!$user || !piece || !artistProfile) return;
    
    if (selectedMediums.length === 0) {
      componentError = 'Please select at least one artistic medium.';
      return;
    }
    
    if (!pitchFit.trim()) {
      componentError = 'Please explain why you are a good fit for this project.';
      return;
    }
    
    if (!pitchCause.trim()) {
      componentError = 'Please explain why you believe in this cause.';
      return;
    }
    
    try {
      submitting = true;
      componentError = null;
      
      // Create the application
      const { error: applicationError } = await supabase
        .from('applications')
        .insert({
          piece_id: params.id,
          applicant_profile_id: $user.id,
          pitch_fit: pitchFit.trim(),
          pitch_cause: pitchCause.trim(),
          portfolio_url: portfolioUrl.trim(),
          selected_mediums: selectedMediums
        });
        
      if (applicationError) throw applicationError;
      
      // Create notification for the applicant
      await supabase
        .from('notifications')
        .insert({
          user_id: $user.id,
          title: 'Application Submitted',
          message: `Your application to "${piece.title}" has been submitted successfully. You will be notified when the organizer reviews your application.`,
          type: 'success',
          action_url: `/piece/${params.id}`
        });
      
      // Create notification for the organizer
      if (piece.organizer_user_id) {
        await supabase
          .from('notifications')
          .insert({
            user_id: piece.organizer_user_id,
            title: 'New Artist Application',
            message: `${artistProfile.name} has applied to contribute to your piece "${piece.title}". Review their application in your organizer dashboard.`,
            type: 'info',
            action_url: `/piece/${params.id}`
          });
      }
      
      success = true;
      
      // Redirect back to the piece page after a short delay
      setTimeout(() => {
        push(`/piece/${params.id}`);
      }, 3000);
      
    } catch (e: any) {
      componentError = e.message;
    } finally {
      submitting = false;
    }
  }
  
  onMount(() => {
    if (params.id) {
      loadPiece();
    }
  });
</script>

<div class="apply-artist">
  {#if loading}
    <div class="loading" transition:fade>
      <div class="loading-spinner"></div>
      <p>Loading application form...</p>
    </div>
  {:else if componentError}
    <div class="error-container" transition:fade>
      <div class="error-card">
        <h2>Cannot Apply</h2>
        <p>{componentError}</p>
        
        {#if !artistProfile}
          <a href="/settings/artist-profile" use:link class="primary action-button">
            Create Artist Profile
          </a>
        {:else}
          <a href="/piece/{params.id}" use:link class="primary action-button">
            Back
          </a>
        {/if}
      </div>
    </div>
  {:else if success}
    <div class="success-container" transition:fade>
      <div class="success-card">
        <div class="success-icon">
          <svg viewBox="0 0 24 24" width="48" height="48" stroke="currentColor" stroke-width="2" fill="none">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
        </div>
        <h2>Application Submitted!</h2>
        <p>Your application to "{piece.title}" has been submitted successfully.</p>
        <p>The organizer will review your application and get back to you soon.</p>
        <p class="redirect-text">Redirecting back to the piece page...</p>
      </div>
    </div>
  {:else if piece}
    <div class="apply-container">
      <!-- Header -->
      <div class="apply-header" in:fade>
        <div class="breadcrumb">
          <a href="/piece/{params.id}" use:link>← Back to Piece</a>
        </div>
        <h1>Apply to "{piece.title}"</h1>
        <p>Share your interest and qualifications to collaborate on this piece</p>
      </div>

      <!-- Application Form -->
      <div class="apply-form" in:fly={{ y: 20, duration: 300 }}>
        <form on:submit|preventDefault={submitApplication}>
          <!-- Artistic Mediums Section -->
          <section class="form-section">
            <h2>Artistic Mediums</h2>
            <p class="section-description">Select the artistic mediums you can contribute to this project</p>
            
            <div class="mediums-grid">
              {#if piece.accepted_mediums && piece.accepted_mediums.length > 0}
                {#each piece.accepted_mediums as medium}
                  <label class="medium-option" class:selected={selectedMediums.includes(medium)}>
                    <input 
                      type="checkbox" 
                      checked={selectedMediums.includes(medium)} 
                      on:change={() => toggleMedium(medium)}
                      disabled={submitting}
                    />
                    <span class="medium-name">{medium}</span>
                  </label>
                {/each}
              {:else}
                <!-- Default mediums if none specified by the organizer -->
                {#each ['Visual Art', 'Painting', 'Drawing', 'Sculpture', 'Photography', 'Digital Art', 'Poetry', 'Music', 'Dance', 'Film', 'Performance'] as medium}
                  <label class="medium-option" class:selected={selectedMediums.includes(medium)}>
                    <input 
                      type="checkbox" 
                      checked={selectedMediums.includes(medium)} 
                      on:change={() => toggleMedium(medium)}
                      disabled={submitting}
                    />
                    <span class="medium-name">{medium}</span>
                  </label>
                {/each}
              {/if}
            </div>
          </section>

          <!-- Pitch Section -->
          <section class="form-section">
            <h2>Your Pitch</h2>
            
            <div class="form-group">
              <label for="pitchFit">Why are you a good fit for this project? *</label>
              <textarea
                id="pitchFit"
                bind:value={pitchFit}
                rows="5"
                required
                disabled={submitting}
                placeholder="Describe your relevant skills, experience, and what you can bring to this project..."
              ></textarea>
            </div>
            
            <div class="form-group">
              <label for="pitchCause">Why do you believe in this cause? *</label>
              <textarea
                id="pitchCause"
                bind:value={pitchCause}
                rows="5"
                required
                disabled={submitting}
                placeholder="Share why this cause matters to you and how your art can contribute to it..."
              ></textarea>
            </div>
            
            <div class="form-group">
              <label for="portfolioUrl">Portfolio URL</label>
              <input
                type="url"
                id="portfolioUrl"
                bind:value={portfolioUrl}
                disabled={submitting}
                placeholder="https://your-portfolio-website.com"
              />
              <p class="field-help">Share a link to your portfolio, personal website, or social media showcasing your work</p>
            </div>
          </section>

          <!-- Form Actions -->
          <div class="form-actions">
            <button 
              type="button" 
              class="secondary"
              on:click={() => push(`/piece/${params.id}`)}
              disabled={submitting}
            >
              Cancel
            </button>
            
            <button type="submit" class="primary" disabled={submitting}>
              {#if submitting}
                <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                    <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                  </circle>
                </svg>
                Submitting...
              {:else}
                Submit Application
              {/if}
            </button>
          </div>
        </form>
      </div>
    </div>
  {/if}
</div>

<style>
  .apply-artist {
    padding: var(--space-6);
    max-width: 900px;
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

  .error-container, .success-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
  }

  .error-card, .success-card {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    max-width: 500px;
    box-shadow: 0 4px 12px var(--shadow-color);
  }

  .error-card {
    border: 1px solid var(--color-error-200);
  }

  .success-card {
    border: 1px solid var(--color-success-200);
  }

  .error-card h2 {
    color: var(--color-error-600);
    margin-bottom: var(--space-4);
  }

  .success-icon {
    display: flex;
    justify-content: center;
    margin-bottom: var(--space-6);
  }

  .success-icon svg {
    color: var(--color-success-600);
  }

  .success-card h2 {
    color: var(--color-success-700);
    margin-bottom: var(--space-4);
  }

  .success-card p {
    color: var(--text-color);
    margin-bottom: var(--space-2);
    line-height: 1.5;
  }

  .redirect-text {
    font-style: italic;
    color: var(--text-muted);
    margin-top: var(--space-4);
    font-size: 0.875rem;
  }

  .action-button {
    display: inline-block;
    margin-top: var(--space-4);
    padding: var(--space-3) var(--space-6);
    border-radius: 50px;
    text-decoration: none;
  }

  .apply-container {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .apply-header {
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

  .apply-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .apply-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
    margin: 0;
  }

  .apply-form {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .form-section {
    margin-bottom: var(--space-8);
    padding-bottom: var(--space-6);
    border-bottom: 1px solid var(--border-color);
  }

  .form-section:last-of-type {
    border-bottom: none;
    margin-bottom: 0;
    padding-bottom: 0;
  }

  .form-section h2 {
    font-size: 1.25rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .section-description {
    color: var(--text-muted);
    margin-bottom: var(--space-4);
    font-size: 0.875rem;
  }

  .mediums-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: var(--space-3);
  }

  .medium-option {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-3);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: all 0.2s;
    background: var(--card-bg);
  }

  .medium-option:hover {
    border-color: var(--color-primary-400);
    background-color: var(--color-primary-50);
  }

  .medium-option.selected {
    border-color: var(--color-primary-600);
    background-color: var(--color-primary-100);
  }

  .medium-option input[type="checkbox"] {
    width: auto;
    margin: 0;
  }

  .medium-name {
    font-size: 0.875rem;
    font-weight: 500;
  }

  .form-group {
    margin-bottom: var(--space-6);
  }

  .form-group label {
    display: block;
    font-weight: 500;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .form-group textarea, .form-group input {
    width: 100%;
    padding: var(--space-3);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    background: var(--card-bg);
    color: var(--text-color);
    font-size: 1rem;
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  .form-group textarea:focus, .form-group input:focus {
    outline: none;
    border-color: var(--color-primary-500);
    box-shadow: 0 0 0 3px var(--color-primary-100);
  }

  .field-help {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-top: var(--space-1);
  }

  .form-actions {
    display: flex;
    gap: var(--space-3);
    justify-content: flex-end;
    margin-top: var(--space-6);
    padding-top: var(--space-6);
    border-top: 1px solid var(--border-color);
  }

  .secondary {
    background: var(--card-bg);
    color: var(--text-color);
    border: 1px solid var(--border-color);
  }

  .secondary:hover {
    background-color: var(--color-neutral-100);
  }

  .spinner {
    animation: spin 1s linear infinite;
  }

  @media (max-width: 768px) {
    .apply-artist {
      padding: var(--space-4);
    }

    .apply-header h1 {
      font-size: 2rem;
    }

    .mediums-grid {
      grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    }

    .form-actions {
      flex-direction: column-reverse;
    }

    .form-actions button {
      width: 100%;
    }
  }
</style>