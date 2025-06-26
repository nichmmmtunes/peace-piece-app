<script lang="ts">
  import { push } from 'svelte-spa-router';
  import { slide } from 'svelte/transition';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';

  let expandedItem: string | null = null;

  const onboardingSteps = [
    {
      id: 'settings',
      title: 'Update your settings',
      description: 'Complete your profile to help others know you better',
      action: '/settings'
    },
    {
      id: 'explore',
      title: 'Explore featured pieces',
      description: 'Discover amazing artworks from independent artists',
      action: '/explore'
    },
    {
      id: 'support',
      title: 'Support a peace piece',
      description: 'Help artists continue their creative journey',
      supportOptions: [
        {
          title: 'Find your favorite piece',
          description: 'Explore through our collection and find artwork that speaks to you'
        },
        {
          title: 'Share the peace piece',
          description: 'Spread the word about your favorite artists on social media'
        },
        {
          title: 'Donate to the organizer\'s cause',
          description: 'Support artists directly through donations'
        }
      ]
    }
  ];

  async function completeOnboarding() {
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ onboarding_completed: true })
        .eq('id', $user?.id);

      if (error) throw error;
      push('/dashboard');
    } catch (error) {
      console.error('Error completing onboarding:', error);
    }
  }

  function toggleItem(id: string) {
    expandedItem = expandedItem === id ? null : id;
  }

  function handleAction(action: string) {
    if (action) {
      push(action);
    }
  }
</script>

<div class="onboarding-container">
  <div class="onboarding-content">
    <div class="intro">
      <h1>Welcome to Peace Piece</h1>
      <p>Let's get you started with these simple steps</p>
    </div>
    
    <div class="onboarding-section">
      {#each onboardingSteps as step}
        <div class="onboarding-item">
          <button 
            class="item-header" 
            on:click={() => toggleItem(step.id)}
            aria-expanded={expandedItem === step.id}
          >
            <span class="item-title">{step.title}</span>
            <span class="expand-icon">{expandedItem === step.id ? '−' : '+'}</span>
          </button>
          
          {#if expandedItem === step.id}
            <div class="item-content" transition:slide>
              <p class="item-description">{step.description}</p>
              
              {#if step.supportOptions}
                <div class="support-options">
                  {#each step.supportOptions as option}
                    <div class="support-option">
                      <h4>{option.title}</h4>
                      <p>{option.description}</p>
                    </div>
                  {/each}
                </div>
              {:else}
                <button 
                  class="primary action-button" 
                  on:click={() => handleAction(step.action)}
                >
                  Get Started
                </button>
              {/if}
            </div>
          {/if}
        </div>
      {/each}
      
      <div class="actions">
        <button class="primary" on:click={completeOnboarding}>
          Complete Onboarding
        </button>
      </div>
    </div>
  </div>
</div>

<style>
  .onboarding-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--space-6);
    background: var(--bg-color);
  }

  .onboarding-content {
    width: 100%;
    max-width: 800px;
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  }
  
  .intro {
    text-align: center;
    margin-bottom: var(--space-8);
  }
  
  .intro h1 {
    font-weight: 700;
    margin-bottom: var(--space-2);
    font-size: 2.5rem;
    color: var(--text-color);
  }
  
  .intro p {
    color: var(--text-muted);
    font-size: 1.125rem;
    max-width: 500px;
    margin: 0 auto;
  }
  
  .onboarding-section {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .onboarding-item {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    overflow: hidden;
    transition: box-shadow 0.2s;
  }

  .onboarding-item:hover {
    box-shadow: 0 4px 8px var(--shadow-color);
  }

  .item-header {
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--space-4);
    background: none;
    border: none;
    cursor: pointer;
    font-size: 1.1rem;
    font-weight: 500;
    color: var(--text-color);
    transition: background-color 0.2s;
    border-radius: unset;
  }

  .item-header:focus {
    outline-offset: 0px;
    outline: none;
  }

  .expand-icon {
    font-size: 22px;
    color: var(--text-muted);
    transition: transform 0.2s;
  }

  .item-content {
    padding: 0 var(--space-4) var(--space-4) var(--space-4);
  }

  .item-description {
    color: var(--text-muted);
    margin-bottom: var(--space-1);
    line-height: 1.5;
  }

  .support-options {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .support-option {
    padding: 0px;
    background: transparent;
    border-radius: 0px;
    border: none;
  }

  .support-option h4 {
    margin-bottom: var(--space-2);
    color: var(--text-color);
    font-weight: 500;
  }

  .support-option p {
    color: var(--text-muted);
    font-size: 0.9rem;
    margin: 0;
    line-height: 1.4;
  }

  .action-button {
    margin-top: var(--space-2);
  }

  .actions {
    display: flex;
    justify-content: center;
    margin-top: var(--space-6);
    padding-top: var(--space-6);
    border-top: 1px solid var(--border-color);
  }
  
  @media (max-width: 640px) {
    .onboarding-container {
      padding: var(--space-4);
    }

    .onboarding-content {
      padding: var(--space-6);
    }
    
    .intro {
      margin-bottom: var(--space-6);
    }
    
    .intro h1 {
      font-size: 2rem;
    }
    
    .intro p {
      font-size: 1rem;
    }
  }
</style>