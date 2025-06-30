Here's the fixed script with added closing brackets:

<script lang="ts">
  import { onMount } from 'svelte';
  import { push, link } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { fade, fly } from 'svelte/transition';
  import RichTextEditor from './RichTextEditor.svelte';

  export let params = { id: '' };

  let title = '';
  let projectMission = '';
  let pieceDescription = '';
  let piecePoem = '';
  let imageFile: File | null = null;
  let audioFile: File | null = null;
  let videoFile: File | null = null;
  let currentImageUrl = '';
  let currentAudioUrl = '';
  let currentVideoUrl = '';
  let loading = false;
  let loadingPiece = true;
  let message = '';
  let messageTimeout: number;
  let organizerId = '';
  let organizers: any[] = [];
  let artists: any[] = [];
  let selectedArtists: { id: string, role: string }[] = [];
  let piece: any = null;
  
  // Project status and milestones
  let projectStatus: 'open_to_applications' | 'seeking_funding' | 'published' = 'open_to_applications';
  let milestones: { title: string, description: string, completed: boolean, due_date?: string }[] = [];
  
  // Cause tags and accepted mediums
  let causeTags: string[] = [];
  let acceptedMediums: string[] = [];
  let newCauseTag = '';
  let newAcceptedMedium = '';
  
  // Additional project fields
  let fullProjectOverview = '';
  let collaborationStructure: 'interwoven' | 'collaborative' = 'interwoven';
  let deliverableFormat: 'video' | 'image_with_audio' | 'image_only' = 'video';
  let artistFees: number | null = null;
  let fundingGoal: number | null = null;

  // Project status options
  const projectStatusOptions = [
    { value: 'open_to_applications', label: 'Open to Applications' },
    { value: 'seeking_funding', label: 'Seeking Funding' },
    { value: 'published', label: 'Published' }
  ];

  // Collaboration structure options
  const collaborationStructureOptions = [
    { value: 'interwoven', label: 'Interwoven', description: 'Artists work together on a single cohesive piece' },
    { value: 'collaborative', label: 'Collaborative', description: 'Artists create separate pieces that are combined' }
  ];

  // Deliverable format options
  const deliverableFormatOptions = [
    { value: 'video', label: 'Video', description: 'A video with optional audio' },
    { value: 'image_with_audio', label: 'Image with Audio', description: 'A static image with accompanying audio' },
    { value: 'image_only', label: 'Image Only', description: 'A static image without audio' }
  ];

  async function loadPiece() {
    try {
      loadingPiece = true;
      
      const { data, error } = await supabase
        .from('piece_details')
        .select('*')
        .eq('id', params.id)
        .single();
        
      if (error) throw error;
      
      piece = data;
      title = piece.title;
      projectMission = piece.mission || '';
      pieceDescription = piece.piece_description || '';
      piecePoem = piece.piece_poem || '';
      organizerId = piece.organizer_id;
      currentImageUrl = piece.image_url || '';
      currentAudioUrl = piece.audio_url || '';
      currentVideoUrl = piece.video_url || '';
      
      // Load project status and milestones
      projectStatus = piece.project_status || 'open_to_applications';
      milestones = piece.milestones || [];
      
      // Load cause tags and accepted mediums
      causeTags = piece.cause_tags || [];
      acceptedMediums = piece.accepted_mediums || [];
      
      // Load additional project fields
      fullProjectOverview = piece.full_project_overview || '';
      collaborationStructure = piece.collaboration_structure === 'interwoven' || piece.collaboration_structure === 'collaborative' 
        ? piece.collaboration_structure 
        : 'interwoven';
      
      // Parse deliverable format from string
      if (piece.deliverable_format === 'video' || 
          piece.deliverable_format === 'image_with_audio' || 
          piece.deliverable_format === 'image_only') {
        deliverableFormat = piece.deliverable_format;
      } else if (piece.deliverable_format && piece.deliverable_format.toLowerCase().includes('video')) {
        deliverableFormat = 'video';
      } else if (piece.deliverable_format && piece.deliverable_format.toLowerCase().includes('audio')) {
        deliverableFormat = 'image_with_audio';
      } else {
        deliverableFormat = 'image_only';
      }
      
      artistFees = piece.artist_fees || null;
      fundingGoal = piece.funding_goal || null;
      
      // Ensure milestones is an array
      if (!Array.isArray(milestones)) {
        milestones = [];
      }
      
      // Load existing contributors
      if (piece.contributors && Array.isArray(piece.contributors)) {
        selectedArtists = piece.contributors.map((contributor: any) => ({
          id: contributor.id,
          role: contributor.role
        }));
      }
      
    } catch (error: any) {
      message = `Error loading piece: ${error.message}`;
    } finally {
      loadingPiece = false;
    }
  }

  async function loadOrganizers() {
    const { data } = await supabase
      .from('organizers')
      .select('id, name');
    
    if (data) {
      organizers = data;
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

      let imageUrl = currentImageUrl;
      let audioUrl = currentAudioUrl;
      let videoUrl = currentVideoUrl;

      if (imageFile) {
        imageUrl = await uploadFile(imageFile, 'pieces');
      }

      if (audioFile) {
        audioUrl = await uploadFile(audioFile, 'audio');
      }

      if (videoFile) {
        videoUrl = await uploadFile(videoFile, 'videos');
      }

      const { error: pieceError } = await supabase
        .from('pieces')
        .update({
          title,
          mission: projectMission,
          piece_description: pieceDescription,
          piece_poem: piecePoem,
          image_url: imageUrl,
          audio_url: audioUrl,
          video_url: videoUrl,
          organizer_id: organizerId,
          project_status: projectStatus,
          milestones: milestones,
          cause_tags: causeTags,
          accepted_mediums: acceptedMediums,
          full_project_overview: fullProjectOverview,
          collaboration_structure: collaborationStructure,
          deliverable_format: deliverableFormat,
          artist_fees: artistFees,
          funding_goal: fundingGoal,
          updated_at: new Date().toISOString()
        })
        .eq('id', params.id);

      if (pieceError) throw pieceError;

      // Update contributors - first delete existing ones
      const { error: deleteError } = await supabase
        .from('piece_artists')
        .delete()
        .eq('piece_id', params.id);

      if (deleteError) throw deleteError;

      // Then insert new ones
      if (selectedArtists.length > 0) {
        const artistInserts = selectedArtists
          .filter(artist => artist.id && artist.role)
          .map(artist => ({
            piece_id: params.id,
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

      message = 'Piece updated successfully!';
      
      if (messageTimeout) clearTimeout(messageTimeout);
      messageTimeout = setTimeout(() => {
        push(`/piece/${params.id}`);
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
    if (params.id) {
      loadPiece();
      loadOrganizers();
      loadArtists();
    }
  });
</script>