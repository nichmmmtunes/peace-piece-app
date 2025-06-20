<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import type { Task } from '../types/Task';
  
  const dispatch = createEventDispatcher();
  
  let taskText = '';
  let taskCategory = '';
  
  const categories = [
    { id: 'work', label: 'Work', color: 'var(--color-primary-500)' },
    { id: 'personal', label: 'Personal', color: 'var(--color-accent-500)' },
    { id: 'shopping', label: 'Shopping', color: 'var(--color-warning-500)' },
    { id: 'health', label: 'Health', color: 'var(--color-success-500)' }
  ];
  
  function handleSubmit() {
    if (!taskText.trim()) return;
    
    const newTask: Task = {
      id: crypto.randomUUID(),
      text: taskText.trim(),
      completed: false,
      category: taskCategory || 'work',
      createdAt: new Date().toISOString()
    };
    
    dispatch('addTask', newTask);
    
    // Reset form
    taskText = '';
  }
</script>

<div class="task-form card">
  <h2>Add New Task</h2>
  
  <form on:submit|preventDefault={handleSubmit}>
    <div class="form-group">
      <label for="taskText">Task description</label>
      <input 
        type="text" 
        id="taskText" 
        bind:value={taskText} 
        placeholder="What needs to be done?"
        autocomplete="off"
      />
    </div>
    
    <div class="form-group">
      <label for="taskCategory">Category</label>
      <div class="category-options">
        {#each categories as category}
          <label 
            class="category-option" 
            style="--category-color: {category.color}"
            class:selected={taskCategory === category.id}
          >
            <input 
              type="radio" 
              name="category" 
              value={category.id} 
              bind:group={taskCategory}
            />
            <span class="category-name">{category.label}</span>
          </label>
        {/each}
      </div>
    </div>
    
    <button type="submit" class="primary">Add Task</button>
  </form>
</div>

<style>
  .task-form {
    margin-bottom: var(--space-6);
  }
  
  form {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }
  
  .form-group {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }
  
  label {
    font-weight: 500;
    font-size: 0.875rem;
    color: var(--text-muted);
  }
  
  .category-options {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }
  
  .category-option {
    position: relative;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background: var(--card-bg);
  }
  
  .category-option input {
    position: absolute;
    opacity: 0;
    width: 0;
    height: 0;
  }
  
  .category-option.selected {
    border-color: var(--category-color);
    background-color: color-mix(in srgb, var(--category-color) 10%, transparent);
  }
  
  .category-option:hover {
    border-color: var(--category-color);
  }
  
  .category-name {
    font-size: 0.875rem;
    font-weight: 500;
  }
  
  button[type="submit"] {
    align-self: flex-start;
    margin-top: var(--space-2);
  }
  
  @media (max-width: 640px) {
    .category-options {
      grid-template-columns: repeat(2, 1fr);
    }
  }
</style>