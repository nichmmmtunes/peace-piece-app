<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { fade, fly } from 'svelte/transition';
  import RichTextEditor from './RichTextEditor.svelte';

  let title = '';
  let projectMission = '';
  let pieceDescription = '';
  let imageFile: File | null = null;
  let audioFile: File | null = null;
  let loading = false;
  let message = '';
  let messageTimeout: number;
  let organizerId = '';
  let organizers: any[] = [];
  let artists: any[] = [];
  let selectedArtists: { id: string, role: string }[] = [];
  
  // Project status and milestones
  let projectStatus: 'submitted_for_approval' | 'open_to_applications' | 'seeking_funding' | 'published' = 'submitted_for_approval';
  let milestones: { title: string, description: string, completed: boolean, due_date?: string }[] = [];
  
  // Cause tags and accepted mediums
  let causeTags: string[] = [];
  let acceptedMediums: string[] = [];
  let newCauseTag = '';
  let newAcceptedMedium = '';
  
  // Additional project fields
  let fullProjectOverview = '';
  let collaborationStructure = '';
  let deliverableFormat = '';
  let compensationDetails = '';
  let fundingGoal: number | null = null;

  // Project status options
  const projectStatusOptions = [
    { value: 'submitted_for_approval', label: 'Submit for Approval' },
    { value: 'open_to_applications', label: 'Open to Applications' },
    { value: 'seeking_funding', label: 'Seeking Funding' },
    { value: 'published', label: 'Published' }
  ];

  async function loadOrganizers() {
    if (!$user) return;
    
    const { data } = await supabase
      .from('organizers')
      .select('id, name')
      .eq('user_id', $user.id);
    
    if (data) {
      organizers = data;
      
      // If user has only one organizer, select it by default
      if (data.length === 1) {
        organizerId = data[0].id;
      }
    }
  }

  async function loadArtists() {
    const { data } = await supabase
      .from('artists')
      .select('id, name');
    
    if (data) {
      artists = data;
    }
  }

  async function uploadFile(file: File, bucket: string) {
    const fileExt = file.name.split('.').pop();
    const fileName = `${crypto.randomUUID()}.${fileExt}`;
    
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(fileName, file);
      
    if (error) throw error;
    
    const { data: { publicUrl } } = supabase.storage
      .from(bucket)
      .getPublicUrl(fileName);
      
    return publicUrl;
  }

  async function handleSubmit() {
    try {
      loading = true;
      message = '';

      if (!title || !organizerId) {
        throw new Error('Title and organizer are required');
      }

      let imageUrl = '';
      let audioUrl = '';

      if (imageFile) {
        imageUrl = await uploadFile(imageFile, 'pieces');
      }

      if (audioFile) {
        audioUrl = await uploadFile(audioFile, 'audio');
      }

      const { data, error: pieceError } = await supabase
        .from('pieces')
        .insert({
          title,
          mission: projectMission,
          piece_description: pieceDescription,
          image_url: imageUrl,
          audio_url: audioUrl,
          organizer_id: organizerId,
          project_status: projectStatus,
          milestones: milestones,
          cause_tags: causeTags,
          accepted_mediums: acceptedMediums,
          full_project_overview: fullProjectOverview,
          collaboration_structure: collaborationStructure,
          deliverable_format: deliverableFormat,
          compensation_details: compensationDetails,
          funding_goal: fundingGoal,
          approved: false // New pieces are not approved by default
        })
        .select('id')
        .single();

      if (pieceError) throw pieceError;

      // Insert contributors
      if (selectedArtists.length > 0 && data?.id) {
        const artistInserts = selectedArtists
          .filter(artist => artist.id && artist.role)
          .map(artist => ({
            piece_id: data.id,
            artist_id: artist.id,
            role: artist.role
          }));

        if (artistInserts.length > 0) {
          const { error: artistError } = await supabase
            .from('piece_artists')
            .insert(artistInserts);

          if (artistError) throw artistError;
        }
      }

      message = 'Peace Piece created successfully! It will be reviewed before being published.';
      
      if (messageTimeout) clearTimeout(messageTimeout);
      messageTimeout = setTimeout(() => {
        push(`/piece/${data.id}`);
      }, 2000);

    } catch (error: any) {
      message = error.message;
    } finally {
      loading = false;
    }
  }

  function addArtist() {
    selectedArtists = [...selectedArtists, { id: '', role: '' }];
  }

  function removeArtist(index: number) {
    selectedArtists = selectedArtists.filter((_, i) => i !== index);
  }
  
  function addMilestone() {
    milestones = [...milestones, { title: '', description: '', completed: false }];
  }
  
  function removeMilestone(index: number) {
    milestones = milestones.filter((_, i) => i !== index);
  }
  
  function updateMilestone(index: number, field: string, value: any) {
    milestones = milestones.map((milestone, i) => {
      if (i === index) {
        return { ...milestone, [field]: value };
      }
      return milestone;
    });
  }
  
  function addCauseTag() {
    if (newCauseTag.trim() && !causeTags.includes(newCauseTag.trim())) {
      causeTags = [...causeTags, newCauseTag.trim()];
      newCauseTag = '';
    }
  }
  
  function removeCauseTag(tag: string) {
    causeTags = causeTags.filter(t => t !== tag);
  }
  
  function addAcceptedMedium() {
    if (newAcceptedMedium.trim() && !acceptedMediums.includes(newAcceptedMedium.trim())) {
      acceptedMediums = [...acceptedMediums, newAcceptedMedium.trim()];
      newAcceptedMedium = '';
    }
  }
  
  function removeAcceptedMedium(medium: string) {
    acceptedMediums = acceptedMediums.filter(m => m !== medium);
  }

  function handleMissionUpdate(event: CustomEvent<string>) {
    projectMission = event.detail;
  }

  onMount(() => {
    loadOrganizers();
    loadArtists();
  });
</script>

<div class="create-piece">
  <div class="create-container">
    <!-- Header -->
    <div class="create-header" in:fade>
      <div class="breadcrumb">
        <a href="/dashboard" use:link>← Back to Dashboard</a>
      </div>
      <h1>Create New Peace Piece</h1>
      <p>Share your creative work with the world</p>
    </div>

    <!-- Form -->
    <div class="create-form" in:fly={{ y: 20, duration: 300 }}>
      {#if message}
        <div 
          class="message" 
          class:error={message.includes('Error') || message.includes('error')} 
          transition:fade
        >
          {message}
        </div>
      {/if}

      <form on:submit|preventDefault={handleSubmit}>
        <!-- Basic Information -->
        <section class="form-section">
          <h2>Basic Information</h2>
          
          <div class="form-grid">
            <div class="form-group">
              <label for="title">Title *</label>
              <input
                type="text"
                id="title"
                bind:value={title}
                required
                disabled={loading}
                placeholder="Enter the title of your piece"
              />
            </div>

            <div class="form-group">
              <label for="organizer">Organizer *</label>
              <select
                id="organizer"
                bind:value={organizerId}
                required
                disabled={loading}
              >
                <option value="">Select an organizer</option>
                {#each organizers as organizer}
                  <option value={organizer.id}>{organizer.name}</option>
                {/each}
              </select>
              {#if organizers.length === 0}
                <p class="field-help">
                  <a href="/settings/organizer-profile" use:link>Create an organizer profile</a> before creating a piece.
                </p>
              {/if}
            </div>
          </div>

          <div class="form-group">
            <label for="pieceDescription">Description (Markdown supported)</label>
            <textarea
              id="pieceDescription"
              bind:value={pieceDescription}
              rows="6"
              disabled={loading}
              placeholder="Describe your piece using markdown formatting. You can use **bold**, *italic*, and [links](url)..."
            ></textarea>
            <div class="field-help">
              <p>You can use markdown formatting:</p>
              <ul>
                <li><code>**bold text**</code> for <strong>bold text</strong></li>
                <li><code>*italic text*</code> for <em>italic text</em></li>
                <li><code>[link text](url)</code> for links</li>
              </ul>
            </div>
          </div>

          <div class="form-group">
            <label for="projectMission">Project Mission</label>
            <RichTextEditor 
              content={projectMission} 
              on:update={handleMissionUpdate}
              placeholder="Share your project's mission, goals, and inspiring content..."
              minHeight="200px"
            />
          </div>
          
          <!-- Project Status -->
          <div class="form-group">
            <label for="projectStatus">Project Status *</label>
            <select
              id="projectStatus"
              bind:value={projectStatus}
              required
              disabled={loading}
            >
              {#each projectStatusOptions as option}
                <option value={option.value}>{option.label}</option>
              {/each}
            </select>
            <div class="field-help">
              <p>Select the current status of your project:</p>
              <ul>
                <li><strong>Submit for Approval:</strong> Your piece will be reviewed before being published</li>
                <li><strong>Open to Applications:</strong> Artists can apply to contribute</li>
                <li><strong>Seeking Funding:</strong> Project is looking for sponsors and donations</li>
                <li><strong>Published:</strong> Project is complete and published</li>
              </ul>
            </div>
          </div>
          
          <!-- Funding Goal -->
          <div class="form-group">
            <label for="fundingGoal">Funding Goal ($)</label>
            <input
              type="number"
              id="fundingGoal"
              bind:value={fundingGoal}
              min="0"
              step="100"
              disabled={loading}
              placeholder="Enter your funding goal amount (e.g., 5000)"
            />
            <div class="field-help">
              <p>Set a realistic funding goal for your project. This will be displayed on your project page with a progress bar.</p>
            </div>
          </div>
        </section>
        
        <!-- Cause Tags Section -->
        <section class="form-section">
          <div class="section-header">
            <h2>Cause Tags</h2>
            <div class="tag-input-container">
              <input
                type="text"
                bind:value={newCauseTag}
                placeholder="Add a cause tag..."
                disabled={loading}
                class="tag-input"
              />
              <button 
                type="button" 
                class="add-tag-button" 
                on:click={addCauseTag}
                disabled={loading || !newCauseTag.trim()}
              >
                Add
              </button>
            </div>
          </div>
          
          {#if causeTags.length > 0}
            <div class="tags-container">
              {#each causeTags as tag}
                <div class="tag-item">
                  <span class="tag-text">{tag}</span>
                  <button 
                    type="button" 
                    class="remove-tag-button" 
                    on:click={() => removeCauseTag(tag)}
                    disabled={loading}
                  >
                    ×
                  </button>
                </div>
              {/each}
            </div>
          {:else}
            <div class="empty-tags">
              <p>No cause tags added yet. Add tags to help categorize your project.</p>
            </div>
          {/if}
        </section>
        
        <!-- Accepted Mediums Section -->
        <section class="form-section">
          <div class="section-header">
            <h2>Accepted Artistic Mediums</h2>
            <div class="tag-input-container">
              <input
                type="text"
                bind:value={newAcceptedMedium}
                placeholder="Add an artistic medium..."
                disabled={loading}
                class="tag-input"
              />
              <button 
                type="button" 
                class="add-tag-button" 
                on:click={addAcceptedMedium}
                disabled={loading || !newAcceptedMedium.trim()}
              >
                Add
              </button>
            </div>
          </div>
          
          {#if acceptedMediums.length > 0}
            <div class="tags-container">
              {#each acceptedMediums as medium}
                <div class="tag-item medium-tag">
                  <span class="tag-text">{medium}</span>
                  <button 
                    type="button" 
                    class="remove-tag-button" 
                    on:click={() => removeAcceptedMedium(medium)}
                    disabled={loading}
                  >
                    ×
                  </button>
                </div>
              {/each}
            </div>
          {:else}
            <div class="empty-tags">
              <p>No artistic mediums added yet. Add mediums to specify what types of art you're looking for.</p>
            </div>
          {/if}
        </section>
        
        <!-- Project Details Section -->
        <section class="form-section">
          <h2>Project Details</h2>
          
          <div class="form-group">
            <label for="fullProjectOverview">Full Project Overview</label>
            <textarea
              id="fullProjectOverview"
              bind:value={fullProjectOverview}
              rows="8"
              disabled={loading}
              placeholder="Provide a comprehensive overview of your project, its goals, and its significance..."
            ></textarea>
          </div>
          
          <div class="form-group">
            <label for="collaborationStructure">Collaboration Structure</label>
            <textarea
              id="collaborationStructure"
              bind:value={collaborationStructure}
              rows="4"
              disabled={loading}
              placeholder="Explain how artists will collaborate on this project..."
            ></textarea>
          </div>
          
          <div class="form-group">
            <label for="deliverableFormat">Deliverable Format</label>
            <textarea
              id="deliverableFormat"
              bind:value={deliverableFormat}
              rows="4"
              disabled={loading}
              placeholder="Describe the final format of the piece (e.g., digital exhibition, printed book, etc.)..."
            ></textarea>
          </div>
          
          <div class="form-group">
            <label for="compensationDetails">Compensation Details</label>
            <textarea
              id="compensationDetails"
              bind:value={compensationDetails}
              rows="4"
              disabled={loading}
              placeholder="Explain how artists will be compensated for their contributions..."
            ></textarea>
          </div>
        </section>

        <!-- Media Section -->
        <section class="form-section">
          <h2>Media</h2>
          
          <div class="media-grid">
            <div class="form-group">
              <label for="image">Image</label>
              <input
                type="file"
                id="image"
                accept="image/*"
                on:change={(e) => imageFile = e.target.files?.[0] || null}
                disabled={loading}
                class="file-input"
              />
              {#if imageFile}
                <div class="new-file-indicator">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <polyline points="20 6 9 17 4 12"></polyline>
                  </svg>
                  Selected: {imageFile.name}
                </div>
              {/if}
            </div>

            <div class="form-group">
              <label for="audio">Audio (optional)</label>
              <input
                type="file"
                id="audio"
                accept="audio/*"
                on:change={(e) => audioFile = e.target.files?.[0] || null}
                disabled={loading}
                class="file-input"
              />
              {#if audioFile}
                <div class="new-file-indicator">
                  <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                    <polyline points="20 6 9 17 4 12"></polyline>
                  </svg>
                  Selected: {audioFile.name}
                </div>
              {/if}
            </div>
          </div>
        </section>
        
        <!-- Milestones Section -->
        <section class="form-section">
          <div class="section-header">
            <h2>Project Milestones</h2>
            <button type="button" class="add-button" on:click={addMilestone}>
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
              </svg>
              Add Milestone
            </button>
          </div>
          
          {#if milestones.length > 0}
            <div class="milestones-list">
              {#each milestones as milestone, i}
                <div class="milestone-row" in:fly={{ y: 20, duration: 300 }}>
                  <div class="milestone-header">
                    <div class="milestone-checkbox">
                      <label class="checkbox-container">
                        <input 
                          type="checkbox" 
                          checked={milestone.completed} 
                          on:change={(e) => updateMilestone(i, 'completed', e.target.checked)}
                          disabled={loading}
                        />
                        <span class="checkmark"></span>
                      </label>
                    </div>
                    
                    <div class="milestone-title-container">
                      <input
                        type="text"
                        placeholder="Milestone title"
                        value={milestone.title}
                        on:input={(e) => updateMilestone(i, 'title', e.target.value)}
                        disabled={loading}
                        class="milestone-title-input"
                      />
                    </div>
                    
                    <button 
                      type="button"
                      class="remove-button"
                      on:click={() => removeMilestone(i)}
                      disabled={loading}
                      title="Remove milestone"
                    >
                      <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                      </svg>
                    </button>
                  </div>
                  
                  <div class="milestone-details">
                    <textarea
                      placeholder="Milestone description"
                      value={milestone.description}
                      on:input={(e) => updateMilestone(i, 'description', e.target.value)}
                      disabled={loading}
                      rows="2"
                      class="milestone-description"
                    ></textarea>
                    
                    <div class="milestone-date-container">
                      <label for={`due-date-${i}`} class="date-label">Due Date:</label>
                      <input
                        type="date"
                        id={`due-date-${i}`}
                        value={milestone.due_date ? milestone.due_date.split('T')[0] : ''}
                        on:input={(e) => updateMilestone(i, 'due_date', e.target.value)}
                        disabled={loading}
                        class="milestone-date"
                      />
                    </div>
                  </div>
                </div>
              {/each}
            </div>
          {:else}
            <div class="empty-milestones">
              <p>No milestones added yet. Click "Add Milestone" to create project milestones.</p>
            </div>
          {/if}
        </section>

        <!-- Contributors Section -->
        <section class="form-section">
          <div class="section-header">
            <h2>Contributors</h2>
            <button type="button" class="add-button" on:click={addArtist}>
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
              </svg>
              Add Contributor
            </button>
          </div>

          {#if selectedArtists.length > 0}
            <div class="contributors-list">
              {#each selectedArtists as artist, i}
                <div class="contributor-row" in:fly={{ y: 20, duration: 300 }}>
                  <div class="contributor-fields">
                    <select
                      bind:value={artist.id}
                      disabled={loading}
                      class="artist-select"
                    >
                      <option value="">Select an artist</option>
                      {#each artists as a}
                        <option value={a.id}>{a.name}</option>
                      {/each}
                    </select>

                    <input
                      type="text"
                      placeholder="Role (e.g., Poet, Musician, Artist)"
                      bind:value={artist.role}
                      disabled={loading}
                      class="role-input"
                    />
                  </div>

                  <button 
                    type="button"
                    class="remove-button"
                    on:click={() => removeArtist(i)}
                    disabled={loading}
                    title="Remove contributor"
                  >
                    <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                      <line x1="18" y1="6" x2="6" y2="18"></line>
                      <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                  </button>
                </div>
              {/each}
            </div>
          {:else}
            <div class="empty-contributors">
              <p>No contributors added yet. Click "Add Contributor" to get started.</p>
            </div>
          {/if}
        </section>

        <!-- Form Actions -->
        <div class="form-actions">
          <button 
            type="button" 
            class="secondary"
            on:click={() => push('/dashboard')}
            disabled={loading}
          >
            Cancel
          </button>
          
          <button type="submit" class="primary" disabled={loading}>
            {#if loading}
              <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                  <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                </circle>
              </svg>
              Creating...
            {:else}
              Create Peace Piece
            {/if}
          </button>
        </div>
      </form>
    </div>
  </div>
</div>

<style>
  .create-piece {
    padding: var(--space-6);
    max-width: 900px;
    margin: 0 auto;
  }

  .create-container {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .create-header {
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

  .create-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .create-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
    margin: 0;
  }

  .create-form {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .message {
    padding: var(--space-3);
    border-radius: var(--radius-md);
    margin-bottom: var(--space-6);
    background-color: var(--color-success-50);
    color: var(--color-success-700);
    border: 1px solid var(--color-success-200);
  }

  .message.error {
    background-color: var(--color-error-50);
    color: var(--color-error-700);
    border-color: var(--color-error-200);
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
    font-weight: 600;
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-4);
  }

  .form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-4);
  }

  .media-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-6);
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .form-group label {
    font-weight: 500;
    color: var(--text-color);
  }

  .form-group input,
  .form-group select,
  .form-group textarea {
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  .field-help {
    background: transparent;
    border-radius: var(--radius-md);
    padding: var(--space-3);
    margin-top: var(--space-2);
  }

  .field-help p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-2) 0;
    font-weight: 500;
  }

  .field-help ul {
    margin: 0;
    padding-left: var(--space-4);
  }

  .field-help li {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-bottom: var(--space-1);
    line-height: 1.4;
  }

  .field-help li:last-child {
    margin-bottom: 0;
  }

  .field-help code {
    background-color: var(--color-neutral-200);
    padding: 2px 4px;
    border-radius: 3px;
    font-family: monospace;
    font-size: 0.8rem;
  }

  .file-input {
    padding: var(--space-3);
    border: 2px dashed var(--border-color);
    border-radius: var(--radius-md);
    background: var(--bg-color);
    color: var(--text-muted);
    cursor: pointer;
    transition: all 0.2s;
  }

  .new-file-indicator {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    margin-top: var(--space-2);
    font-size: 0.875rem;
    color: var(--color-success-600);
  }

  .add-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background: var(--color-primary-100);
    color: var(--color-primary-700);
    border: 1px solid var(--color-primary-200);
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .add-button:hover {
    background-color: var(--color-primary-200);
  }
  
  /* Tags Styling */
  .tag-input-container {
    display: flex;
    gap: var(--space-2);
  }
  
  .tag-input {
    flex: 1;
  }
  
  .add-tag-button {
    background-color: var(--color-primary-600);
    color: white;
    border: none;
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: background-color 0.2s;
  }
  
  .add-tag-button:hover:not(:disabled) {
    background-color: var(--color-primary-700);
  }
  
  .add-tag-button:disabled {
    background-color: var(--color-neutral-300);
    cursor: not-allowed;
  }
  
  .tags-container {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
    margin-top: var(--space-4);
  }
  
  .tag-item {
    display: flex;
    align-items: center;
    gap: var(--space-1);
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
    padding: var(--space-1) var(--space-2);
    border-radius: var(--radius-md);
    font-size: 0.875rem;
  }
  
  .tag-item.medium-tag {
    background-color: var(--color-success-100);
    color: var(--color-success-700);
  }
  
  .remove-tag-button {
    background: none;
    border: none;
    color: inherit;
    cursor: pointer;
    font-size: 1rem;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0;
    width: 16px;
    height: 16px;
    border-radius: 50%;
    transition: background-color 0.2s;
  }
  
  .remove-tag-button:hover {
    background-color: rgba(0, 0, 0, 0.1);
  }
  
  .empty-tags {
    text-align: center;
    padding: var(--space-4);
    color: var(--text-muted);
    background-color: var(--color-neutral-50);
    border-radius: var(--radius-md);
    border: 1px dashed var(--border-color);
    margin-top: var(--space-4);
  }
  
  /* Milestones styles */
  .milestones-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }
  
  .milestone-row {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
    padding: var(--space-3);
    background: transparent;
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
  }
  
  .milestone-header {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }
  
  .milestone-checkbox {
    display: flex;
    align-items: center;
  }
  
  .checkbox-container {
    display: block;
    position: relative;
    padding-left: 30px;
    cursor: pointer;
    user-select: none;
    height: 24px;
    display: flex;
    align-items: center;
  }
  
  .checkbox-container input {
    position: absolute;
    opacity: 0;
    cursor: pointer;
    height: 0;
    width: 0;
  }
  
  .checkmark {
    position: absolute;
    top: 0;
    left: 0;
    height: 22px;
    width: 22px;
    background: var(--card-bg);
    border: 2px solid var(--border-color);
    border-radius: 4px;
  }
  
  .checkbox-container:hover input ~ .checkmark {
    background-color: var(--color-neutral-100);
  }
  
  .checkbox-container input:checked ~ .checkmark {
    background-color: var(--color-primary-600);
    border-color: var(--color-primary-600);
  }
  
  .checkmark:after {
    content: "";
    position: absolute;
    display: none;
  }
  
  .checkbox-container input:checked ~ .checkmark:after {
    display: block;
  }
  
  .checkbox-container .checkmark:after {
    left: 7px;
    top: 3px;
    width: 5px;
    height: 10px;
    border: solid white;
    border-width: 0 2px 2px 0;
    transform: rotate(45deg);
  }
  
  .milestone-title-container {
    flex: 1;
  }
  
  .milestone-title-input {
    width: 100%;
    font-weight: 500;
  }
  
  .milestone-details {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
    margin-left: 30px;
  }
  
  .milestone-description {
    width: 100%;
    resize: vertical;
    min-height: 60px;
  }
  
  .milestone-date-container {
    display: flex;
    align-items: center;
    gap: var(--space-2);
  }
  
  .date-label {
    font-size: 0.875rem;
    color: var(--text-muted);
    white-space: nowrap;
  }
  
  .milestone-date {
    flex: 1;
    max-width: 200px;
  }
  
  .empty-milestones {
    text-align: center;
    padding: var(--space-6);
    color: var(--text-muted);
    background-color: var(--color-neutral-50);
    border-radius: var(--radius-md);
    border: 1px dashed var(--border-color);
  }

  .contributors-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .contributor-row {
    display: flex;
    gap: var(--space-3);
    align-items: flex-start;
    padding: var(--space-3);
    background: transparent;
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
  }

  .contributor-fields {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-3);
    flex: 1;
  }

  .artist-select,
  .role-input {
    margin: 0;
  }

  .remove-button {
    background-color: var(--color-error-50);
    color: var(--color-error-600);
    border: 1px solid var(--color-error-200);
    padding: var(--space-2);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .remove-button:hover {
    background-color: var(--color-error-100);
  }

  .empty-contributors {
    text-align: center;
    padding: var(--space-6);
    color: var(--text-muted);
    background-color: var(--color-neutral-50);
    border-radius: var(--radius-md);
    border: 1px dashed var(--border-color);
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

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  @media (max-width: 768px) {
    .create-piece {
      padding: var(--space-4);
    }

    .create-header h1 {
      font-size: 2rem;
    }

    .form-grid,
    .media-grid {
      grid-template-columns: 1fr;
    }

    .contributor-fields {
      grid-template-columns: 1fr;
    }

    .contributor-row {
      flex-direction: column;
    }

    .remove-button {
      align-self: flex-end;
    }

    .form-actions {
      flex-direction: column-reverse;
    }
    
    .milestone-header {
      flex-wrap: wrap;
    }
    
    .milestone-title-container {
      flex: 1 0 100%;
      order: -1;
      margin-bottom: var(--space-2);
    }
    
    .milestone-details {
      margin-left: 0;
    }
    
    .milestone-date-container {
      flex-direction: column;
      align-items: flex-start;
    }
    
    .milestone-date {
      max-width: none;
      width: 100%;
    }
  }
</style>