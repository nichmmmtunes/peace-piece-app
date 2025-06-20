<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { fly, scale } from 'svelte/transition';
  import type { Task } from '../types/Task';
  
  export let task: Task;
  
  const dispatch = createEventDispatcher();
  
  const categoryColors = {
    work: 'var(--color-primary-500)',
    personal: 'var(--color-accent-500)',
    shopping: 'var(--color-warning-500)',
    health: 'var(--color-success-500)'
  };
  
  function toggleTask() {
    dispatch('toggleTask', task.id);
  }
  
  function removeTask() {
    dispatch('removeTask', task.id);
  }
  
  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }
</script>

<div 
  class="task-item card"
  class:completed={task.completed}
>
  <div class="task-item-content">
    <div class="task-checkbox-container">
      <label class="task-checkbox">
        <input type="checkbox" checked={task.completed} on:change={toggleTask}>
        <span class="checkmark"></span>
      </label>
    </div>
    
    <div class="task-details">
      <p class="task-text">{task.text}</p>
      <div class="task-meta">
        <span 
          class="task-category"
          style="--category-color: {categoryColors[task.category] || 'var(--color-primary-500)'}"
        >
          {task.category}
        </span>
        <span class="task-date">{formatDate(task.createdAt)}</span>
      </div>
    </div>
  </div>
  
  <div class="task-actions">
    <button 
      class="delete-btn" 
      on:click={removeTask} 
      aria-label="Delete task"
      title="Delete task"
    >
      <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <polyline points="3 6 5 6 21 6"></polyline>
        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
      </svg>
    </button>
  </div>
</div>

<style>
  .task-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--space-4);
    transition: all 0.3s ease;
    cursor: grab;
  }
  
  .task-item:active {
    cursor: grabbing;
  }
  
  .task-item.completed {
    opacity: 0.7;
  }
  
  .task-item-content {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    flex: 1;
  }
  
  .task-checkbox-container {
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .task-checkbox {
    position: relative;
    display: inline-block;
    width: 22px;
    height: 22px;
  }
  
  .task-checkbox input {
    opacity: 0;
    width: 0;
    height: 0;
    position: absolute;
  }
  
  .checkmark {
    position: absolute;
    top: 0;
    left: 0;
    width: 22px;
    height: 22px;
    border: 2px solid var(--border-color);
    border-radius: 50%;
    transition: all 0.2s;
  }
  
  .task-checkbox input:checked ~ .checkmark {
    background-color: var(--color-primary-600);
    border-color: var(--color-primary-600);
  }
  
  .checkmark:after {
    content: "";
    position: absolute;
    display: none;
    left: 7px;
    top: 3px;
    width: 5px;
    height: 10px;
    border: solid white;
    border-width: 0 2px 2px 0;
    transform: rotate(45deg);
  }
  
  .task-checkbox input:checked ~ .checkmark:after {
    display: block;
  }
  
  .task-details {
    flex: 1;
  }
  
  .task-text {
    margin: 0;
    transition: text-decoration 0.3s;
    word-break: break-word;
    line-height: 1.4;
  }
  
  .completed .task-text {
    text-decoration: line-through;
    color: var(--text-muted);
  }
  
  .task-meta {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    margin-top: var(--space-1);
    flex-wrap: wrap;
  }
  
  .task-category {
    font-size: 0.75rem;
    font-weight: 500;
    color: var(--category-color);
    background-color: color-mix(in srgb, var(--category-color) 15%, transparent);
    padding: 2px 6px;
    border-radius: 4px;
  }
  
  .task-date {
    font-size: 0.75rem;
    color: var(--text-muted);
  }
  
  .task-actions {
    display: flex;
    gap: var(--space-2);
  }
  
  .delete-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    background: none;
    border: none;
    color: var(--text-muted);
    padding: var(--space-1);
    border-radius: 4px;
    cursor: pointer;
    opacity: 0.5;
    transition: all 0.2s;
  }
  
  .task-item:hover .delete-btn {
    opacity: 1;
  }
  
  .delete-btn:hover {
    color: var(--color-error-600);
    background-color: var(--color-error-50);
  }
</style>