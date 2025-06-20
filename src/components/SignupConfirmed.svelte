<script lang="ts">
  import { push } from 'svelte-spa-router';
  import { fade } from 'svelte/transition';
</script>

<div class="confirmed-container">
  <div class="confirmed-content" in:fade>
    <div class="success-icon">
      <svg viewBox="0 0 24 24" width="48" height="48" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
        <polyline points="22 4 12 14.01 9 11.01"></polyline>
      </svg>
    </div>

    <h1>Email Verified!</h1>
    
    <div class="confirmation-message">
      <p>Your email has been successfully verified. You can now sign in to your Peace Piece account and start exploring amazing artworks from independent artists.</p>
    </div>
    
    <div class="confirmed-actions">
      <button class="primary" on:click={() => push('/auth')}>
        Sign In to Your Account
      </button>
    </div>
  </div>
</div>

<style>
  .confirmed-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--space-6);
    background: linear-gradient(135deg, var(--color-success-50), var(--color-primary-50));
  }

  .confirmed-content {
    width: 100%;
    max-width: 500px;
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  }

  .success-icon {
    display: flex;
    justify-content: center;
    margin-bottom: var(--space-6);
    color: var(--color-success-600);
  }

  h1 {
    font-size: 1.75rem;
    font-weight: 700;
    margin: 0 0 var(--space-6) 0;
    color: var(--text-color);
  }
  
  .confirmation-message {
    margin-bottom: var(--space-8);
  }

  .confirmation-message p {
    color: var(--text-muted);
    line-height: 1.6;
    margin: 0;
  }

  .confirmed-actions {
    display: flex;
    justify-content: center;
  }

  @media (max-width: 640px) {
    .confirmed-container {
      padding: var(--space-4);
    }

    .confirmed-content {
      padding: var(--space-6);
    }

    h1 {
      font-size: 22px;
    }
  }
</style>