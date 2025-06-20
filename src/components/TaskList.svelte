<script lang="ts">
  import { createEventDispatcher, onMount } from 'svelte';
  import { fly, fade } from 'svelte/transition';
  import { flip } from 'svelte/animate';
  import TaskItem from './TaskItem.svelte';
  
  export let tasks: Task[] = [];
  export let hideFilters = false;
  
  const dispatch = createEventDispatcher();
  
  let filterStatus: 'all' | 'active' | 'completed' = 'all';
  let searchQuery = '';
  
  $: filteredTasks = tasks
    .filter(task => {
      if (filterStatus === 'active') return !task.completed;
      if (filterStatus === 'completed') return task.completed;
      return true;
    })
    .filter(task => {
      if (!searchQuery) return true;
      return task.text.toLowerCase().includes(searchQuery.toLowerCase());
    });
  
  function handleToggleTask(event: CustomEvent<string>) {
    dispatch('toggleTask', event.detail);
  }
  
  function handleRemoveTask(event: CustomEvent<string>) {
    dispatch('removeTask', event.detail);
  }
</script>

<div class="task-list-container">
  {#if !hideFilters}
    <div class="task-filters">
      <div class="search-container">
        <input 
          type="text" 
          bind:value={searchQuery} 
          placeholder="Search tasks..." 
          class="search-input"
        />
        {#if searchQuery}
          <button class="clear-search" on:click={() => searchQuery = ''}>
            <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        {/if}
      </div>
      
      <div class="status-filters">
        <button 
          class:active={filterStatus === 'all'}
          on:click={() => filterStatus = 'all'}
        >
          All
        </button>
        <button 
          class:active={filterStatus === 'active'}
          on:click={() => filterStatus = 'active'}
        >
          Active
        </button>
        <button 
          class:active={filterStatus === 'completed'}
          on:click={() => filterStatus = 'completed'}
        >
          Completed
        </button>
      </div>
    </div>
  {/if}

  {#if filteredTasks.length === 0}
    <div class="empty-state" in:fade={{ duration: 200 }}>
      {#if searchQuery}
        <p>No tasks match your search</p>
      {:else if filterStatus === 'active'}
        <p>No active tasks</p>
      {:else if filterStatus === 'completed'}
        <p>No completed tasks</p>
      {:else}
        <p>No tasks yet</p>
      {/if}
    </div>
  {:else}
    <ul class="task-list">
      {#each filteredTasks as task, index (task.id)}
        <li 
          animate:flip={{ duration: 300 }}
          in:fly={{ y: 20, duration: 300 }}
          out:fade={{ duration: 200 }}
        >
          <TaskItem 
            {task} 
            on:toggleTask={handleToggleTask} 
            on:removeTask={handleRemoveTask} 
          />
        </li>
      {/each}
    </ul>
  {/if}
</div>

<style>
  .task-list-container {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }
  
  .task-filters {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
    margin-bottom: var(--space-2);
  }
  
  .search-container {
    position: relative;
  }
  
  .search-input {
    padding-right: var(--space-8);
  }
  
  .clear-search {
    position: absolute;
    right: var(--space-2);
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    padding: var(--space-1);
    display: flex;
  }
  
  .status-filters {
    display: flex;
    gap: var(--space-2);
  }
  
  .status-filters button {
    background: none;
    border: none;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    cursor: pointer;
    color: var(--text-muted);
    font-size: 0.875rem;
    transition: all 0.2s;
  }
  
  .status-filters button:hover {
    background-color: var(--border-color);
  }
  
  .status-filters button.active {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }
  
  .task-list {
    list-style: none;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }
  
  .empty-state {
    display: flex;
    justify-content: center;
    align-items: center;
    padding: var(--space-8);
    text-align: center;
    color: var(--text-muted);
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    border: 1px dashed var(--border-color);
  }
  
  @media (min-width: 640px) {
    .task-filters {
      flex-direction: row;
      justify-content: space-between;
      align-items: center;
    }
    
    .search-container {
      width: 300px;
    }
  }
</style>