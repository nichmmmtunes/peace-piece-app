<script lang="ts">
  import TaskList from './TaskList.svelte';
  import TaskForm from './TaskForm.svelte';
  import { tasks, addTask, toggleTask, removeTask, reorderTasks } from '../stores/taskStore';
  import type { Task } from '../types/Task';

  function handleAddTask(event: CustomEvent<Task>) {
    addTask(event.detail);
  }

  function handleToggleTask(event: CustomEvent<string>) {
    toggleTask(event.detail);
  }

  function handleRemoveTask(event: CustomEvent<string>) {
    removeTask(event.detail);
  }

  function handleReorderTasks(event: CustomEvent<{ fromIndex: number, toIndex: number }>) {
    const { fromIndex, toIndex } = event.detail;
    reorderTasks(fromIndex, toIndex);
  }
</script>

<div class="app-content">
  <div class="intro">
    <h1>Task Manager</h1>
    <p>A simple, beautiful way to organize your tasks</p>
  </div>
  
  <div class="task-section">
    <TaskForm on:addTask={handleAddTask} />
    
    <TaskList 
      on:toggleTask={handleToggleTask}
      on:removeTask={handleRemoveTask}
      on:reorderTasks={handleReorderTasks}
    />
  </div>
</div>

<style>
  .app-content {
    display: flex;
    flex-direction: column;
    padding: var(--space-6) 0;
    max-width: 800px;
    margin: 0 auto;
    width: 100%;
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
  
  .task-section {
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }
  
  @media (max-width: 640px) {
    .app-content {
      padding: var(--space-4) 0;
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