<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  
  export let darkMode: boolean;
  
  const dispatch = createEventDispatcher();
  
  function toggle() {
    dispatch('toggle');
  }
</script>

<button class="theme-toggle" on:click={toggle} aria-label="Toggle dark mode">
  {#if darkMode}
    <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="12" cy="12" r="5"></circle>
      <line x1="12" y1="1" x2="12" y2="3"></line>
      <line x1="12" y1="21" x2="12" y2="23"></line>
      <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
      <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
      <line x1="1" y1="12" x2="3" y2="12"></line>
      <line x1="21" y1="12" x2="23" y2="12"></line>
      <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
      <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
    </svg>
  {:else}
    <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
    </svg>
  {/if}
</button>

<style>
  .theme-toggle {
    background: none;
    border: none;
    color: var(--text-color);
    cursor: pointer;
    padding: var(--space-2);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background-color 0.2s, transform 0.2s;
  }
  
  .theme-toggle:hover {
    background-color: var(--border-color);
  }
  
  .theme-toggle:active {
    transform: scale(0.9);
  }
</style>