<script lang="ts">
  import { onMount, onDestroy, createEventDispatcher } from 'svelte';
  import { Editor } from '@tiptap/core';
  import StarterKit from '@tiptap/starter-kit';
  import Link from '@tiptap/extension-link';

  export let content = '';
  export let placeholder = 'Start typing...';
  export let minHeight = '200px';

  let element: HTMLElement;
  let editor: Editor;
  
  const dispatch = createEventDispatcher();

  onMount(() => {
    editor = new Editor({
      element,
      extensions: [
        StarterKit,
        Link.configure({
          openOnClick: false,
          HTMLAttributes: {
            class: 'rich-text-link',
          },
        }),
      ],
      content,
      editorProps: {
        attributes: {
          class: 'rich-text-content',
          style: `min-height: ${minHeight}; height: 100%;`,
        },
      },
      onUpdate: ({ editor }) => {
        content = editor.getHTML();
        dispatch('update', content);
      },
    });
  });

  onDestroy(() => {
    if (editor) {
      editor.destroy();
    }
  });

  function toggleBold() {
    editor.chain().focus().toggleBold().run();
  }

  function toggleItalic() {
    editor.chain().focus().toggleItalic().run();
  }

  function toggleBulletList() {
    editor.chain().focus().toggleBulletList().run();
  }

  function toggleOrderedList() {
    editor.chain().focus().toggleOrderedList().run();
  }

  function setLink() {
    const previousUrl = editor.getAttributes('link').href;
    const url = window.prompt('URL', previousUrl);

    // cancelled
    if (url === null) {
      return;
    }

    // empty
    if (url === '') {
      editor.chain().focus().extendMarkRange('link').unsetLink().run();
      return;
    }

    // update link
    editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run();
  }

  function isActive(type: string, options = {}) {
    if (!editor) return false;
    return editor.isActive(type, options);
  }
</script>

<div class="rich-text-editor">
  <div class="toolbar">
    <button 
      type="button" 
      class="toolbar-button" 
      class:active={isActive('bold')} 
      on:click={toggleBold} 
      title="Bold"
    >
      <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M6 4h8a4 4 0 0 1 4 4 4 4 0 0 1-4 4H6z"></path>
        <path d="M6 12h9a4 4 0 0 1 4 4 4 4 0 0 1-4 4H6z"></path>
      </svg>
    </button>
    
    <button 
      type="button" 
      class="toolbar-button" 
      class:active={isActive('italic')} 
      on:click={toggleItalic} 
      title="Italic"
    >
      <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <line x1="19" y1="4" x2="10" y2="4"></line>
        <line x1="14" y1="20" x2="5" y2="20"></line>
        <line x1="15" y1="4" x2="9" y2="20"></line>
      </svg>
    </button>
    
    <div class="toolbar-divider"></div>
    
    <button 
      type="button" 
      class="toolbar-button" 
      class:active={isActive('bulletList')} 
      on:click={toggleBulletList} 
      title="Bullet List"
    >
      <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <line x1="8" y1="6" x2="21" y2="6"></line>
        <line x1="8" y1="12" x2="21" y2="12"></line>
        <line x1="8" y1="18" x2="21" y2="18"></line>
        <line x1="3" y1="6" x2="3.01" y2="6"></line>
        <line x1="3" y1="12" x2="3.01" y2="12"></line>
        <line x1="3" y1="18" x2="3.01" y2="18"></line>
      </svg>
    </button>
    
    <button 
      type="button" 
      class="toolbar-button" 
      class:active={isActive('orderedList')} 
      on:click={toggleOrderedList} 
      title="Numbered List"
    >
      <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <line x1="10" y1="6" x2="21" y2="6"></line>
        <line x1="10" y1="12" x2="21" y2="12"></line>
        <line x1="10" y1="18" x2="21" y2="18"></line>
        <path d="M4 6h1v4"></path>
        <path d="M4 10h2"></path>
        <path d="M6 18H4c0-1 2-2 2-3s-1-1.5-2-1"></path>
      </svg>
    </button>
    
    <div class="toolbar-divider"></div>
    
    <button 
      type="button" 
      class="toolbar-button" 
      class:active={isActive('link')} 
      on:click={setLink} 
      title="Link"
    >
      <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path>
        <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path>
      </svg>
    </button>
  </div>
  
  <div bind:this={element} class="editor-content"></div>
</div>

<style>
  .rich-text-editor {
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    overflow: hidden;
    display: flex;
    flex-direction: column;
    background: var(--bg-color);
  }
  
  .toolbar {
    display: flex;
    padding: 0.5rem;
    border-bottom: 1px solid var(--border-color);
    background: var(--bg-color);
    flex-wrap: wrap;
    gap: 0.25rem;
  }
  
  .toolbar-button {
    background: none;
    border: none;
    padding: 0.5rem;
    border-radius: var(--radius-sm);
    cursor: pointer;
    color: var(--text-muted);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
  }
  
  .toolbar-button:hover {
    background: var(--bg-color);
    color: var(--text-color);
  }
  
  .toolbar-button.active {
    background-color: var(--color-primary-100);
    color: var(--color-primary-700);
  }
  
  .toolbar-divider {
    width: 1px;
    height: 24px;
    background-color: var(--border-color);
    margin: 0 0.25rem;
  }
  
  .editor-content {
    padding: 1rem;
    overflow-y: auto;
    flex: 1;
  }
  
  :global(.rich-text-content) {
    outline: none;
  }
  
  :global(.rich-text-content p) {
    margin: 0.75rem 0;
  }
  
  :global(.rich-text-content p:first-child) {
    margin-top: 0;
  }
  
  :global(.rich-text-content p:last-child) {
    margin-bottom: 0;
  }
  
  :global(.rich-text-content ul, .rich-text-content ol) {
    padding-left: 1.5rem;
    margin: 0.75rem 0;
  }
  
  :global(.rich-text-content li) {
    margin: 0.25rem 0;
  }
  
  :global(.rich-text-link) {
    color: var(--color-primary-600);
    text-decoration: none;
  }
  
  :global(.rich-text-link:hover) {
    text-decoration: underline;
  }
  
  :global(.ProseMirror-focused) {
    outline: none;
  }
  
  :global(.ProseMirror p.is-editor-empty:first-child::before) {
    content: attr(data-placeholder);
    float: left;
    color: var(--text-muted);
    pointer-events: none;
    height: 0;
  }
</style>