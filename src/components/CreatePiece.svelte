<script lang="ts">
import { onMount } from 'svelte';
import { push, link } from 'svelte-spa-router';
import { supabase } from '../lib/supabase';
import { user } from '../stores/authStore';
import { fade, fly } from 'svelte/transition';
import { products } from '../stripe-config';
import RichTextEditor from './RichTextEditor.svelte';
  
let title = '';
let pieceDescription = '';
let projectMission = '';
let imageFile: File | null = null;
let audioFile: File | null = null;
let videoFile: File | null = null;
let loading = false;
let message = '';
let messageTimeout: number;
  
// Organizer variables
let organizers: any[] = [];
let organizerId = '';
let newOrganizerName = '';
let newOrganizerDescription = '';
let creatingNewOrganizer = false;

// Sponsor variables
let sponsors: any[] = [];
let selectedSponsorId = '';
let creatingNewSponsor = false;
let newSponsorName = '';
let newSponsorLogoUrl = '';
let newSponsorWebsite = '';
let newSponsorBio = '';
let newSponsorAmount = '';
let newSponsorAdditionalLinks: { name: string, url: string }[] = [{ name: '', url: '' }];
  
// Form fields
let causeTags: string[] = [];
let acceptedMediums: string[] = [];
let fullProjectOverview = '';
let collaborationStructure = '';
let deliverableFormat = '';
let artistsNeeded = 1;
let projectVisibility = 'open';
let compensationDetails = '';
let fundingGoal = '';
let donationCtaType = 'project';
let preliminarySponsorInfo = '';
  
// Timeline dates
let applicationStartDate = '';
let applicationEndDate = '';
let kickoffDate = '';
let submissionDueDate = '';
let feedbackWindowEndDate = '';
let publicationTargetDate = '';

// Project status and milestones
let projectStatus: 'open_to_applications' | 'seeking_funding' | 'published' = 'open_to_applications';
let milestones: { title: string, description: string, completed: boolean, due_date?: string }[] = [];
  
// Step management
let currentStep = 1;
const totalSteps = 5; // Increased from 4 to 5 to include milestones
  
const causeTagOptions = [
  'Education', 'Environment', 'Health', 'Poverty', 'Equality', 
  'Peace', 'Justice', 'Community', 'Arts', 'Culture', 'Human Rights'
];
  
const mediumOptions = [
  'Visual Art', 'Poetry', 'Music', 'Dance', 'Photography', 
  'Film', 'Digital Art', 'Sculpture', 'Performance', 'Mixed Media'
];
  
const collaborationOptions = [
  { value: 'interwoven', label: 'Interwoven (consecutive contributions)' },
  { value: 'collaborative', label: 'Collaborative (artists work together)' }
];
  
const deliverableOptions = [
  { value: 'image', label: 'Image with audio' },
  { value: 'video', label: 'Video with audio' },
];
  
const visibilityOptions = [
  { value: 'open', label: 'Open' },
  { value: 'invite_only', label: 'Invite-Only' }
];
  
const donationCtaOptions = [
  { value: 'cause', label: 'Direct to cause' },
  { value: 'project', label: 'Direct to project' },
  { value: 'both_cta', label: 'Both (Cause & Project)' }
];

const compensationOptions = [
  { 
    value: 'artist_fee', 
    label: 'Artist Fee', 
    description: 'Artists receives a fixed fee for their work. Donations go directly to the cause.',
    forceDonationCta: 'cause'
  },
  { 
    value: 'equal_share', 
    label: 'Equal Share of Donations', 
    description: 'Artists receive an equal share of donations made to the project.',
    forceDonationCta: 'project'
  },
  { 
    value: 'artist_fee_and_equal_share', 
    label: 'Artist Fee + Equal Share', 
    description: 'Artists receive both a fixed fee and a share of project donations.',
    forceDonationCta: 'both_cta'
  }
];

// Project status options
const projectStatusOptions = [
  { value: 'open_to_applications', label: 'Open to Applications' },
  { value: 'seeking_funding', label: 'Seeking Funding' },
  { value: 'published', label: 'Published' }
];

// Reactive variables for donation CTA type disabling
$: disableDonationCtaCause = compensationDetails === 'equal_share' || compensationDetails === 'artist_fee_and_equal_share';
$: disableDonationCtaProject = compensationDetails === 'artist_fee' || compensationDetails === 'artist_fee_and_equal_share';
$: disableDonationCtaBoth = compensationDetails !== 'artist_fee_and_equal_share';

// Reactive logic to handle compensation selection and donation CTA type
$: {
  if (compensationDetails === 'artist_fee') {
    donationCtaType = 'cause';
  } else if (compensationDetails === 'equal_share') {
    donationCtaType = 'project';
  } else if (compensationDetails === 'artist_fee_and_equal_share') {
    donationCtaType = 'both_cta';
  }
}

async function loadOrganizers() {
  if (!$user) return;
  
  try {
    const { data, error } = await supabase
      .from('organizers')
      .select('id, name')
      .eq('user_id', $user.id);
      
    if (error) throw error;
    
    organizers = data || [];
    
    // If user has organizers, use the first one by default
    if (organizers.length > 0) {
      organizerId = organizers[0].id;
      creatingNewOrganizer = false;
    } else {
      // If no organizers exist, default to creating a new one
      creatingNewOrganizer = true;
      // Pre-fill with user's profile name as a default organizer name
      const { data: profile } = await supabase
        .from('profiles')
        .select('username')
        .eq('id', $user.id)
        .single();
        
      if (profile && profile.username) {
        newOrganizerName = profile.username;
      } else if ($user.email) {
        const emailName = $user.email.split('@')[0];
        newOrganizerName = emailName.charAt(0).toUpperCase() + emailName.slice(1) + " Productions";
      }
    }
  } catch (error) {
    console.error('Error loading organizers:', error);
  }
}

async function loadSponsors() {
  try {
    const { data, error } = await supabase
      .from('sponsors')
      .select('*');
      
    if (error) throw error;
    
    sponsors = data || [];
  } catch (error) {
    console.error('Error loading sponsors:', error);
  }
}

async function createOrganizer() {
  if (!$user || !newOrganizerName.trim()) return null;
  
  try {
    const { data, error } = await supabase
      .from('organizers')
      .insert({
        name: newOrganizerName.trim(),
        description: newOrganizerDescription.trim(),
        user_id: $user.id
      })
      .select('id')
      .single();
      
    if (error) throw error;
    
    return data.id;
  } catch (error) {
    console.error('Error creating organizer:', error);
    throw error;
  }
}

async function createSponsor() {
  if (!newSponsorName.trim()) return null;
  
  try {
    const { data, error } = await supabase
      .from('sponsors')
      .insert({
        name: newSponsorName.trim(),
        logo_url: newSponsorLogoUrl.trim(),
        website: newSponsorWebsite.trim(),
        bio: newSponsorBio.trim(),
        additional_links: newSponsorAdditionalLinks.filter(link => link.name.trim() && link.url.trim())
      })
      .select('id')
      .single();
      
    if (error) throw error;
    
    return data.id;
  } catch (error) {
    console.error('Error creating sponsor:', error);
    throw error;
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

    if (!title) {
      throw new Error('Title is required');
    }

    // Handle organizer selection/creation
    let finalOrganizerId;
    
    if (creatingNewOrganizer) {
      if (!newOrganizerName.trim()) {
        throw new Error('Organizer name is required');
      }
      finalOrganizerId = await createOrganizer();
    } else {
      if (!organizerId) {
        throw new Error('Please select an organizer');
      }
      finalOrganizerId = organizerId;
    }

    // Upload files if provided
    let imageUrl = null;
    let audioUrl = null;
    let videoUrl = null;

    if (imageFile) {
      imageUrl = await uploadFile(imageFile, 'pieces');
    }

    if (audioFile) {
      audioUrl = await uploadFile(audioFile, 'audio');
    }

    if (videoFile) {
      videoUrl = await uploadFile(videoFile, 'videos');
    }

    // Prepare piece data
    const pieceData = {
      title,
      piece_description: pieceDescription,
      mission: projectMission,
      image_url: imageUrl,
      audio_url: audioUrl,
      video_url: videoUrl,
      organizer_id: finalOrganizerId,
      cause_tags: causeTags,
      accepted_mediums: acceptedMediums,
      full_project_overview: fullProjectOverview,
      collaboration_structure: collaborationStructure,
      deliverable_format: deliverableFormat,
      application_start_date: applicationStartDate ? new Date(applicationStartDate).toISOString() : null,
      application_end_date: applicationEndDate ? new Date(applicationEndDate).toISOString() : null,
      kickoff_date: kickoffDate ? new Date(kickoffDate).toISOString() : null,
      submission_due_date: submissionDueDate ? new Date(submissionDueDate).toISOString() : null,
      feedback_window_end_date: feedbackWindowEndDate ? new Date(feedbackWindowEndDate).toISOString() : null,
      publication_target_date: publicationTargetDate ? new Date(publicationTargetDate).toISOString() : null,
      artists_needed: artistsNeeded,
      project_visibility: projectVisibility,
      compensation_details: compensationDetails,
      funding_goal: fundingGoal ? parseInt(fundingGoal) : null,
      donation_cta_type: donationCtaType,
      preliminary_sponsor_info: preliminarySponsorInfo,
      project_status: projectStatus,
      milestones: milestones
    };

    // Insert the piece
    const { data, error } = await supabase
      .from('pieces')
      .insert(pieceData)
      .select('id')
      .single();

    if (error) throw error;

    // Handle sponsor if provided
    if ((creatingNewSponsor && newSponsorName.trim()) || (!creatingNewSponsor && selectedSponsorId)) {
      let sponsorId;
      
      if (creatingNewSponsor) {
        sponsorId = await createSponsor();
      } else {
        sponsorId = selectedSponsorId;
      }
      
      if (sponsorId && newSponsorAmount) {
        const amount = parseInt(newSponsorAmount);
        if (amount > 0) {
          const { error: sponsorError } = await supabase
            .from('piece_sponsors')
            .insert({
              piece_id: data.id,
              sponsor_id: sponsorId,
              amount: amount
            });
            
          if (sponsorError) {
            console.error('Error linking sponsor:', sponsorError);
          }
        }
      }
    }

    message = 'Peace Piece created successfully!';
    
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

function toggleCauseTag(tag: string) {
  if (causeTags.includes(tag)) {
    causeTags = causeTags.filter(t => t !== tag);
  } else {
    causeTags = [...causeTags, tag];
  }
}

function toggleMedium(medium: string) {
  if (acceptedMediums.includes(medium)) {
    acceptedMediums = acceptedMediums.filter(m => m !== medium);
  } else {
    acceptedMediums = [...acceptedMediums, medium];
  }
}

function nextStep() {
  if (currentStep < totalSteps) {
    currentStep++;
    window.scrollTo(0, 0);
  }
}

function prevStep() {
  if (currentStep > 1) {
    currentStep--;
    window.scrollTo(0, 0);
  }
}

function toggleOrganizerCreation() {
  creatingNewOrganizer = !creatingNewOrganizer;
}

function toggleSponsorCreation() {
  creatingNewSponsor = !creatingNewSponsor;
}

function addSponsorLink() {
  newSponsorAdditionalLinks = [...newSponsorAdditionalLinks, { name: '', url: '' }];
}

function removeSponsorLink(index: number) {
  newSponsorAdditionalLinks = newSponsorAdditionalLinks.filter((_, i) => i !== index);
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

function handleMissionUpdate(event: CustomEvent<string>) {
  projectMission = event.detail;
}

onMount(() => {
  if ($user) {
    loadOrganizers();
    loadSponsors();
  }
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
      <p>Share your vision and invite artists to collaborate</p>
    </div>

    <!-- Progress Indicator -->
    <div class="progress-container">
      <div class="progress-bar">
        <div class="progress-fill" style="width: {(currentStep / totalSteps) * 100}%"></div>
      </div>
      <div class="progress-steps">
        {#each Array(totalSteps) as _, i}
          <div class="progress-step" class:active={currentStep >= i + 1} class:completed={currentStep > i + 1}>
            <div class="step-number">{i + 1}</div>
            <div class="step-label">
              {#if i === 0}
                Basic Info
              {:else if i === 1}
                Project Details
              {:else if i === 2}
                Timeline
              {:else if i === 3}
                Milestones
              {:else if i === 4}
                Funding
              {/if}
            </div>
          </div>
        {/each}
      </div>
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
        <!-- Step 1: Basic Information -->
        {#if currentStep === 1}
          <section class="form-section">
            <h2>Basic Information</h2>
            
            <div class="form-group">
              <label for="title">Project Title *</label>
              <input
                type="text"
                id="title"
                bind:value={title}
                required
                disabled={loading}
                placeholder="Enter a title for your peace piece"
              />
            </div>

            <div class="form-group">
              <label for="pieceDescription">Short Description (1-2 sentences, for previews)</label>
              <textarea
                id="pieceDescription"
                bind:value={pieceDescription}
                rows="3"
                disabled={loading}
                placeholder="Briefly describe your peace piece in 1-2 sentences"
              ></textarea>
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
                  <li><strong>Open to Applications:</strong> Artists can apply to contribute</li>
                  <li><strong>Seeking Funding:</strong> Project is looking for sponsors and donations</li>
                  <li><strong>Published:</strong> Project is complete and published</li>
                </ul>
              </div>
            </div>

            <div class="form-group">
              <label>Organizer *</label>
              
              <div class="organizer-options">
                {#if organizers.length > 0}
                  <label class="radio-option">
                    <input
                      type="radio"
                      name="organizer-type"
                      checked={!creatingNewOrganizer}
                      on:change={() => creatingNewOrganizer = false}
                      disabled={loading}
                    />
                    <span>Use Existing Organizer</span>
                  </label>
                {/if}
                
                <label class="radio-option">
                  <input
                    type="radio"
                    name="organizer-type"
                    checked={creatingNewOrganizer}
                    on:change={() => creatingNewOrganizer = true}
                    disabled={loading}
                  />
                  <span>Create New Organizer</span>
                </label>
              </div>

              {#if creatingNewOrganizer}
                <div class="nested-fields" in:fly={{ y: 10, duration: 200 }}>
                  <div class="form-group">
                    <label for="newOrganizerName">Organizer Name *</label>
                    <input
                      type="text"
                      id="newOrganizerName"
                      bind:value={newOrganizerName}
                      required={creatingNewOrganizer}
                      disabled={loading}
                      placeholder="Enter organizer name"
                    />
                  </div>
                  
                  <div class="form-group">
                    <label for="newOrganizerDescription">Organizer Description</label>
                    <textarea
                      id="newOrganizerDescription"
                      bind:value={newOrganizerDescription}
                      rows="3"
                      disabled={loading}
                      placeholder="Describe the organizing entity or individual"
                    ></textarea>
                  </div>
                </div>
              {:else if organizers.length > 0}
                <div class="form-group" in:fly={{ y: 10, duration: 200 }}>
                  <select
                    bind:value={organizerId}
                    disabled={loading}
                    required={!creatingNewOrganizer}
                  >
                    <option value="">Select an organizer</option>
                    {#each organizers as organizer}
                      <option value={organizer.id}>{organizer.name}</option>
                    {/each}
                  </select>
                </div>
              {/if}
            </div>

            <div class="media-grid">
              <div class="form-group">
                <label for="image">Cover Image (optional)</label>
                <input
                  type="file"
                  id="image"
                  accept="image/*"
                  on:change={(e) => imageFile = e.target.files?.[0] || null}
                  disabled={loading}
                  class="file-input"
                />
                {#if imageFile}
                  <div class="file-preview">
                    <div class="preview-label">Selected image:</div>
                    <div class="file-name">{imageFile.name}</div>
                  </div>
                {/if}
              </div>
            </div>
          </section>
        {/if}

        <!-- Step 2: Project Details -->
        {#if currentStep === 2}
          <section class="form-section">
            <h2>Project Details</h2>
            
            <div class="form-group">
              <label>Cause Tags (select all that apply)</label>
              <div class="tags-grid">
                {#each causeTagOptions as tag}
                  <label class="tag-option">
                    <input 
                      type="checkbox" 
                      checked={causeTags.includes(tag)} 
                      on:change={() => toggleCauseTag(tag)}
                    />
                    <span>{tag}</span>
                  </label>
                {/each}
              </div>
            </div>

            <div class="form-group">
              <label>Accepted Mediums (select all that apply)</label>
              <div class="tags-grid">
                {#each mediumOptions as medium}
                  <label class="tag-option">
                    <input 
                      type="checkbox" 
                      checked={acceptedMediums.includes(medium)} 
                      on:change={() => toggleMedium(medium)}
                    />
                    <span>{medium}</span>
                  </label>
                {/each}
              </div>
            </div>

            <div class="form-group">
              <label for="fullProjectOverview">Full Project Overview (for artists)</label>
              <textarea
                id="fullProjectOverview"
                bind:value={fullProjectOverview}
                rows="6"
                disabled={loading}
                placeholder="Describe your vision, theme, personal motivation, why this matters to the community and who would be good artists to contribute..."
              ></textarea>
            </div>

            <div class="form-group">
              <label>Collaboration Structure</label>
              <div class="radio-options">
                {#each collaborationOptions as option}
                  <label class="radio-card">
                    <input 
                      type="radio" 
                      name="collaboration" 
                      value={option.value}
                      bind:group={collaborationStructure}
                    />
                    <div class="radio-card-content">
                      <div class="radio-card-title">{option.label}</div>
                    </div>
                  </label>
                {/each}
              </div>
            </div>

            <div class="form-group">
              <label>Deliverable Format</label>
              <div class="radio-options">
                {#each deliverableOptions as option}
                  <label class="radio-card">
                    <input 
                      type="radio" 
                      name="deliverable" 
                      value={option.value}
                      bind:group={deliverableFormat}
                    />
                    <div class="radio-card-content">
                      <div class="radio-card-title">{option.label}</div>
                    </div>
                  </label>
                {/each}
              </div>
            </div>

            <div class="form-group">
              <label for="artistsNeeded">Number of Artists Needed</label>
              <input
                type="number"
                id="artistsNeeded"
                bind:value={artistsNeeded}
                min="1"
                max="100"
                disabled={loading}
              />
            </div>

            <div class="form-group">
              <label>Project Visibility</label>
              <div class="radio-options">
                {#each visibilityOptions as option}
                  <label class="radio-card">
                    <input 
                      type="radio" 
                      name="visibility" 
                      value={option.value}
                      bind:group={projectVisibility}
                    />
                    <div class="radio-card-content">
                      <div class="radio-card-title">{option.label}</div>
                    </div>
                  </label>
                {/each}
              </div>
            </div>
          </section>
        {/if}

        <!-- Step 3: Timeline -->
        {#if currentStep === 3}
          <section class="form-section">
            <h2>Timeline</h2>
            
            <div class="date-grid">
              <div class="form-group">
                <label for="applicationStartDate">Application Start Date</label>
                <input
                  type="date"
                  id="applicationStartDate"
                  bind:value={applicationStartDate}
                  disabled={loading}
                />
              </div>
              
              <div class="form-group">
                <label for="applicationEndDate">Application End Date</label>
                <input
                  type="date"
                  id="applicationEndDate"
                  bind:value={applicationEndDate}
                  disabled={loading}
                />
              </div>
              
              <div class="form-group">
                <label for="kickoffDate">Kickoff Date</label>
                <input
                  type="date"
                  id="kickoffDate"
                  bind:value={kickoffDate}
                  disabled={loading}
                />
              </div>
              
              <div class="form-group">
                <label for="submissionDueDate">Submission Due Date</label>
                <input
                  type="date"
                  id="submissionDueDate"
                  bind:value={submissionDueDate}
                  disabled={loading}
                />
              </div>
              
              <div class="form-group">
                <label for="feedbackWindowEndDate">Feedback Window End Date</label>
                <input
                  type="date"
                  id="feedbackWindowEndDate"
                  bind:value={feedbackWindowEndDate}
                  disabled={loading}
                />
              </div>
              
              <div class="form-group">
                <label for="publicationTargetDate">Publication Target Date</label>
                <input
                  type="date"
                  id="publicationTargetDate"
                  bind:value={publicationTargetDate}
                  disabled={loading}
                />
              </div>
            </div>
            
            <div class="timeline-visualization">
              <div class="timeline-line"></div>
              {#if applicationStartDate}
                <div class="timeline-marker" style="left: 0%">
                  <div class="marker-label">Applications Open</div>
                </div>
              {/if}
              {#if applicationEndDate}
                <div class="timeline-marker" style="left: 20%">
                  <div class="marker-label">Applications Close</div>
                </div>
              {/if}
              {#if kickoffDate}
                <div class="timeline-marker" style="left: 40%">
                  <div class="marker-label">Project Kickoff</div>
                </div>
              {/if}
              {#if submissionDueDate}
                <div class="timeline-marker" style="left: 60%">
                  <div class="marker-label">Submissions Due</div>
                </div>
              {/if}
              {#if feedbackWindowEndDate}
                <div class="timeline-marker" style="left: 80%">
                  <div class="marker-label">Feedback Ends</div>
                </div>
              {/if}
              {#if publicationTargetDate}
                <div class="timeline-marker" style="left: 100%">
                  <div class="marker-label">Publication</div>
                </div>
              {/if}
            </div>
          </section>
        {/if}
        
        <!-- Step 4: Milestones -->
        {#if currentStep === 4}
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
            
            <div class="field-help">
              <p>Create milestones to track your project's progress. Milestones help artists and supporters understand the project timeline and current status.</p>
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
                          value={milestone.due_date}
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
            
            <div class="milestone-examples">
              <h3>Example Milestones</h3>
              <div class="examples-grid">
                <div class="example-card">
                  <h4>Artist Selection</h4>
                  <p>Review applications and select artists for the project</p>
                  <button 
                    type="button" 
                    class="use-example-btn"
                    on:click={() => {
                      milestones = [...milestones, {
                        title: 'Artist Selection',
                        description: 'Review applications and select artists for the project',
                        completed: false
                      }];
                    }}
                  >
                    Use This
                  </button>
                </div>
                
                <div class="example-card">
                  <h4>Initial Drafts</h4>
                  <p>Artists submit initial drafts for review and feedback</p>
                  <button 
                    type="button" 
                    class="use-example-btn"
                    on:click={() => {
                      milestones = [...milestones, {
                        title: 'Initial Drafts',
                        description: 'Artists submit initial drafts for review and feedback',
                        completed: false
                      }];
                    }}
                  >
                    Use This
                  </button>
                </div>
                
                <div class="example-card">
                  <h4>Final Submissions</h4>
                  <p>Artists submit final versions of their contributions</p>
                  <button 
                    type="button" 
                    class="use-example-btn"
                    on:click={() => {
                      milestones = [...milestones, {
                        title: 'Final Submissions',
                        description: 'Artists submit final versions of their contributions',
                        completed: false
                      }];
                    }}
                  >
                    Use This
                  </button>
                </div>
                
                <div class="example-card">
                  <h4>Project Publication</h4>
                  <p>Final piece is published and shared with the community</p>
                  <button 
                    type="button" 
                    class="use-example-btn"
                    on:click={() => {
                      milestones = [...milestones, {
                        title: 'Project Publication',
                        description: 'Final piece is published and shared with the community',
                        completed: false
                      }];
                    }}
                  >
                    Use This
                  </button>
                </div>
              </div>
            </div>
          </section>
        {/if}

        <!-- Step 5: Funding -->
        {#if currentStep === 5}
          <section class="form-section">
            <h2>Funding & Support</h2>
            
            <div class="form-group">
              <label>Compensation Details</label>
              <div class="radio-options">
                {#each compensationOptions as option}
                  <label class="radio-card">
                    <input 
                      type="radio" 
                      name="compensation" 
                      value={option.value}
                      bind:group={compensationDetails}
                    />
                    <div class="radio-card-content">
                      <div class="radio-card-title">{option.label}</div>
                      <div class="radio-card-description">{option.description}</div>
                    </div>
                  </label>
                {/each}
              </div>
            </div>
            
            <div class="form-group">
              <label>Donation CTA Type</label>
              <div class="radio-options">
                {#each donationCtaOptions as option}
                  {#if option.value !== 'both_cta' || compensationDetails === 'artist_fee_and_equal_share'}
                    <label class="radio-card" class:disabled={
                      (option.value === 'cause' && disableDonationCtaCause) || 
                      (option.value === 'project' && disableDonationCtaProject) ||
                      (option.value === 'both_cta' && disableDonationCtaBoth)
                    }>
                      <input 
                        type="radio" 
                        name="donationCta" 
                        value={option.value}
                        bind:group={donationCtaType}
                        disabled={
                          (option.value === 'cause' && disableDonationCtaCause) || 
                          (option.value === 'project' && disableDonationCtaProject) ||
                          (option.value === 'both_cta' && disableDonationCtaBoth)
                        }
                      />
                      <div class="radio-card-content">
                        <div class="radio-card-title">{option.label}</div>
                        {#if option.value === 'cause' && disableDonationCtaCause}
                          <div class="radio-card-description disabled-message">Not available with selected compensation model</div>
                        {/if}
                        {#if option.value === 'project' && disableDonationCtaProject}
                          <div class="radio-card-description disabled-message">Not available with selected compensation model</div>
                        {/if}
                        {#if option.value === 'both_cta' && compensationDetails === 'artist_fee_and_equal_share'}
                          <div class="radio-card-description">Required for Artist Fee + Equal Share compensation</div>
                        {/if}
                      </div>
                    </label>
                  {/if}
                {/each}
              </div>
            </div>

            <div class="form-group">
              <label for="fundingGoal">Funding Goal (USD, optional)</label>
              <input
                type="number"
                id="fundingGoal"
                bind:value={fundingGoal}
                min="0"
                step="100"
                disabled={loading}
                placeholder="e.g., 1000"
              />
            </div>
            
            <!-- Sponsor Section -->
            <div class="form-group">
              <div class="section-header">
                <label>Sponsor Information</label>
              </div>
              
              <div class="sponsor-options">
                {#if sponsors.length > 0}
                  <label class="radio-option">
                    <input
                      type="radio"
                      name="sponsor-type"
                      checked={!creatingNewSponsor}
                      on:change={() => creatingNewSponsor = false}
                      disabled={loading}
                    />
                    <span>Select Existing Sponsor</span>
                  </label>
                {/if}
                
                <label class="radio-option">
                  <input
                    type="radio"
                    name="sponsor-type"
                    checked={creatingNewSponsor}
                    on:change={() => creatingNewSponsor = true}
                    disabled={loading}
                  />
                  <span>Create New Sponsor</span>
                </label>
              </div>

              {#if creatingNewSponsor}
                <div class="nested-fields" in:fly={{ y: 10, duration: 200 }}>
                  <div class="form-group">
                    <label for="newSponsorName">Sponsor Name</label>
                    <input
                      type="text"
                      id="newSponsorName"
                      bind:value={newSponsorName}
                      disabled={loading}
                      placeholder="Enter sponsor organization name"
                    />
                  </div>
                  
                  <div class="form-group">
                    <label for="newSponsorLogoUrl">Logo URL</label>
                    <input
                      type="url"
                      id="newSponsorLogoUrl"
                      bind:value={newSponsorLogoUrl}
                      disabled={loading}
                      placeholder="https://example.com/logo.png"
                    />
                  </div>
                  
                  <div class="form-group">
                    <label for="newSponsorWebsite">Website</label>
                    <input
                      type="url"
                      id="newSponsorWebsite"
                      bind:value={newSponsorWebsite}
                      disabled={loading}
                      placeholder="https://example.com"
                    />
                  </div>
                  
                  <div class="form-group">
                    <label for="newSponsorBio">Bio/Description</label>
                    <textarea
                      id="newSponsorBio"
                      bind:value={newSponsorBio}
                      rows="3"
                      disabled={loading}
                      placeholder="Describe the sponsor organization"
                    ></textarea>
                  </div>
                  
                  <div class="form-group">
                    <label>Additional Links</label>
                    {#each newSponsorAdditionalLinks as link, index}
                      <div class="link-row">
                        <input
                          type="text"
                          bind:value={link.name}
                          placeholder="Link name (e.g., Twitter)"
                          disabled={loading}
                          class="link-name-input"
                        />
                        <input
                          type="url"
                          bind:value={link.url}
                          placeholder="URL (e.g., https://twitter.com/sponsor)"
                          disabled={loading}
                          class="link-url-input"
                        />
                        <button 
                          type="button" 
                          class="remove-link-btn" 
                          on:click={() => removeSponsorLink(index)}
                          disabled={loading || newSponsorAdditionalLinks.length === 1}
                          title="Remove link"
                        >
                          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                          </svg>
                        </button>
                      </div>
                    {/each}
                    <button 
                      type="button" 
                      class="add-link-btn" 
                      on:click={addSponsorLink}
                      disabled={loading}
                    >
                      <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                        <line x1="12" y1="5" x2="12" y2="19"></line>
                        <line x1="5" y1="12" x2="19" y2="12"></line>
                      </svg>
                      Add Another Link
                    </button>
                  </div>
                </div>
              {:else if sponsors.length > 0}
                <div class="form-group" in:fly={{ y: 10, duration: 200 }}>
                  <select
                    bind:value={selectedSponsorId}
                    disabled={loading}
                  >
                    <option value="">Select a sponsor (optional)</option>
                    {#each sponsors as sponsor}
                      <option value={sponsor.id}>{sponsor.name}</option>
                    {/each}
                  </select>
                </div>
              {/if}
              
              {#if (creatingNewSponsor && newSponsorName) || (!creatingNewSponsor && selectedSponsorId)}
                <div class="form-group" in:fly={{ y: 10, duration: 200 }}>
                  <label for="newSponsorAmount">Sponsorship Amount (USD)</label>
                  <input
                    type="number"
                    id="newSponsorAmount"
                    bind:value={newSponsorAmount}
                    min="0"
                    step="100"
                    disabled={loading}
                    placeholder="e.g., 1000"
                  />
                </div>
              {/if}
            </div>
            
            <div class="form-group">
              <label for="preliminarySponsorInfo">Additional Sponsor Information</label>
              <textarea
                id="preliminarySponsorInfo"
                bind:value={preliminarySponsorInfo}
                rows="3"
                disabled={loading}
                placeholder="List any additional sponsors or potential sponsors you've already identified"
              ></textarea>
            </div>
          </section>
        {/if}

        <!-- Form Navigation -->
        <div class="form-navigation">
          {#if currentStep > 1}
            <button type="button" class="secondary" on:click={prevStep} disabled={loading}>
              Previous
            </button>
          {:else}
            <button type="button" class="secondary" on:click={() => push('/dashboard')} disabled={loading}>
              Cancel
            </button>
          {/if}
          
          {#if currentStep < totalSteps}
            <button type="button" class="primary" on:click={nextStep} disabled={loading}>
              Next
            </button>
          {:else}
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
          {/if}
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

  .progress-container {
    margin-bottom: var(--space-4);
  }

  .progress-bar {
    height: 8px;
    background-color: var(--color-neutral-100);
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: var(--space-4);
  }

  .progress-fill {
    height: 100%;
    background-color: var(--color-primary-500);
    transition: width 0.3s ease;
  }

  .progress-steps {
    display: flex;
    justify-content: space-between;
  }

  .progress-step {
    display: flex;
    flex-direction: column;
    align-items: center;
    position: relative;
    flex: 1;
  }

  .progress-step::before {
    content: '';
    position: absolute;
    top: 12px;
    left: -50%;
    width: 100%;
    height: 2px;
    background-color: var(--color-neutral-200);
    z-index: 1;
  }

  .progress-step:first-child::before {
    display: none;
  }

  .progress-step.active::before,
  .progress-step.completed::before {
    background-color: var(--color-primary-600);
  }

  .step-number {
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background-color: var(--color-neutral-200);
    color: var(--text-muted);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.875rem;
    font-weight: 600;
    margin-bottom: var(--space-2);
    position: relative;
    z-index: 2;
  }

  .progress-step.active .step-number {
    background-color: var(--color-primary-600);
    color: white;
  }

  .progress-step.completed .step-number {
    background-color: var(--color-success-600);
    color: white;
  }

  .step-label {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-align: center;
  }

  .progress-step.active .step-label {
    color: var(--color-primary-500);
    font-weight: 500;
  }

  .progress-step.completed .step-label {
    color: var(--color-success-500);
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
    margin-bottom: var(--space-6);
  }

  .form-section h2 {
    margin: 0 0 var(--space-4) 0;
    color: var(--text-color);
  }

  .form-group {
    margin-bottom: var(--space-4);
  }

  .form-group label {
    display: block;
    font-weight: 500;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .nested-fields {
    margin-top: var(--space-3);
    padding: var(--space-3);
    background: var(--bg-color);
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
  }
  
  .field-help {
    background: transparent;
    border-radius: var(--radius-md);
    padding: var(--space-3);
    margin-bottom: var(--space-4);
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

  .field-note {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-top: var(--space-2);
  }

  .media-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-4);
  }

  .file-input {
    padding: var(--space-3);
    border: 2px dashed var(--border-color);
    border-radius: var(--radius-md);
    background-color: var(--color-neutral-50);
    cursor: pointer;
    transition: all 0.2s;
  }

  .file-input:hover {
    border-color: var(--color-primary-400);
    background-color: var(--color-primary-50);
  }

  .file-preview {
    margin-top: var(--space-2);
    font-size: 0.875rem;
  }

  .preview-label {
    font-weight: 500;
    color: var(--color-primary-600);
  }

  .file-name {
    color: var(--text-muted);
    word-break: break-all;
  }

  .tags-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: var(--space-2);
  }

  .tag-option {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: all 0.2s;
  }

  .tag-option:hover {
    background: var(--bg-color);
  }

  .tag-option input {
    margin: 0;
    width: fit-content;
    margin-right: 7px;
  }

  .organizer-options,
  .sponsor-options {
    display: flex;
    gap: var(--space-4);
    margin-bottom: var(--space-3);
  }

  .radio-option {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    cursor: pointer;
  }

  .radio-option input[type="radio"] {
    width: fit-content;
  }

  .radio-options {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: var(--space-3);
  }

  .radio-card {
    position: relative;
    cursor: pointer;
  }

  .radio-card.disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .radio-card input {
    position: absolute;
    opacity: 0;
    cursor: pointer;
  }

  .radio-card-content {
    padding: var(--space-3);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    transition: all 0.2s;
  }

  .radio-card input:checked + .radio-card-content {
    border-color: var(--color-primary-600);
    background: var(--bg-color);
  }

  .radio-card-title {
    font-weight: 500;
    color: var(--text-color);
    margin-bottom: var(--space-1);
  }

  .radio-card-description {
    font-size: 0.875rem;
    color: var(--text-muted);
    line-height: 1.4;
  }

  .disabled-message {
    color: var(--color-error-600);
    font-style: italic;
  }

  .date-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: var(--space-4);
  }

  .timeline-visualization {
    position: relative;
    height: 100px;
    margin: var(--space-6) 0;
  }

  .timeline-line {
    position: absolute;
    top: 50%;
    left: 0;
    right: 0;
    height: 4px;
    background-color: var(--color-neutral-200);
    transform: translateY(-50%);
  }

  .timeline-marker {
    position: absolute;
    top: 50%;
    transform: translate(-50%, -50%);
    width: 16px;
    height: 16px;
    background-color: var(--color-primary-600);
    border-radius: 50%;
  }

  .marker-label {
    position: absolute;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    white-space: nowrap;
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-3);
  }
  
  /* Milestones styles */
  .milestones-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
    margin-bottom: var(--space-6);
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
    margin-bottom: var(--space-6);
  }
  
  .milestone-examples {
    background-color: var(--color-primary-50);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    border: 1px solid var(--color-primary-100);
  }
  
  .milestone-examples h3 {
    font-size: 1rem;
    font-weight: 600;
    margin: 0 0 var(--space-3) 0;
    color: var(--color-primary-700);
  }
  
  .examples-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: var(--space-3);
  }
  
  .example-card {
    background-color: white;
    border-radius: var(--radius-md);
    padding: var(--space-3);
    border: 1px solid var(--color-primary-200);
  }
  
  .example-card h4 {
    font-size: 0.875rem;
    font-weight: 600;
    margin: 0 0 var(--space-1) 0;
    color: var(--color-primary-700);
  }
  
  .example-card p {
    font-size: 0.75rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-2) 0;
    line-height: 1.4;
  }
  
  .use-example-btn {
    font-size: 0.75rem;
    padding: var(--space-1) var(--space-2);
    background: var(--color-primary-100);
    color: var(--color-primary-700);
    border: 1px solid var(--color-primary-200);
    border-radius: var(--radius-sm);
    cursor: pointer;
    transition: all 0.2s;
  }
  
  .use-example-btn:hover {
    background: var(--color-primary-200);
  }

  .link-row {
    display: flex;
    gap: var(--space-2);
    margin-bottom: var(--space-2);
    align-items: center;
  }

  .link-name-input {
    flex: 1;
  }

  .link-url-input {
    flex: 2;
  }

  .remove-link-btn {
    background-color: var(--color-error-50);
    color: var(--color-error-600);
    border: 1px solid var(--color-error-100);
    border-radius: var(--radius-md);
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s;
    flex-shrink: 0;
    padding: 0;
  }

  .remove-link-btn:hover:not(:disabled) {
    background-color: var(--color-error-100);
  }

  .remove-link-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .add-link-btn {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background: var(--color-primary-50);
    color: var(--color-primary-600);
    border: 1px solid var(--color-primary-100);
    border-radius: var(--radius-md);
    padding: var(--space-2) var(--space-3);
    font-size: 0.875rem;
    cursor: pointer;
    transition: all 0.2s;
    margin-top: var(--space-2);
  }

  .add-link-btn:hover:not(:disabled) {
    background-color: var(--color-primary-100);
  }
  
  .add-button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background-color: var(--color-primary-100);
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
  
  .remove-button {
    background-color: var(--color-error-50);
    color: var(--color-error-600);
    border: 1px solid var(--color-error-100);
    border-radius: var(--radius-md);
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s;
    flex-shrink: 0;
    padding: 0;
  }

  .remove-button:hover:not(:disabled) {
    background-color: var(--color-error-100);
  }

  .form-navigation {
    display: flex;
    justify-content: space-between;
    margin-top: var(--space-6);
    padding-top: var(--space-6);
    border-top: 1px solid var(--border-color);
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

    .media-grid,
    .date-grid {
      grid-template-columns: 1fr;
    }

    .tags-grid {
      grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    }

    .step-label {
      display: none;
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
    
    .examples-grid {
      grid-template-columns: 1fr;
    }
  }
</style>