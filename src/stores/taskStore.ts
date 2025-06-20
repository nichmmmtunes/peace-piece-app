import { writable } from 'svelte/store';
import type { Task } from '../types/Task';

// Get tasks from localStorage if available
const storedTasks = localStorage.getItem('tasks');
const initialTasks: Task[] = storedTasks ? JSON.parse(storedTasks) : [
  {
    id: '1',
    text: 'Complete project proposal',
    completed: false,
    category: 'work',
    createdAt: new Date().toISOString()
  },
  {
    id: '2',
    text: 'Buy groceries for dinner',
    completed: true,
    category: 'shopping',
    createdAt: new Date(Date.now() - 86400000).toISOString() // yesterday
  },
  {
    id: '3',
    text: 'Go for a morning run',
    completed: false,
    category: 'health',
    createdAt: new Date(Date.now() - 172800000).toISOString() // 2 days ago
  }
];

// Create the store
export const tasks = writable<Task[]>(initialTasks);

// Subscribe to changes and update localStorage
tasks.subscribe(value => {
  if (typeof localStorage !== 'undefined') {
    localStorage.setItem('tasks', JSON.stringify(value));
  }
});

// Store actions
export function addTask(task: Task) {
  tasks.update(tasks => [task, ...tasks]);
}

export function toggleTask(id: string) {
  tasks.update(tasks =>
    tasks.map(task =>
      task.id === id ? { ...task, completed: !task.completed } : task
    )
  );
}

export function removeTask(id: string) {
  tasks.update(tasks => tasks.filter(task => task.id !== id));
}

export function reorderTasks(fromIndex: number, toIndex: number) {
  tasks.update(tasks => {
    const result = [...tasks];
    const [removed] = result.splice(fromIndex, 1);
    result.splice(toIndex, 0, removed);
    return result;
  });
}