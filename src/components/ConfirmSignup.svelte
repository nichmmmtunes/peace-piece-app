<script lang="ts">
  import { push } from 'svelte-spa-router';
  import { fade } from 'svelte/transition';
</script>

<div class="confirm-container">
  <div class="confirm-content" in:fade>
    <div class="confirm-icon">
      <svg viewBox="0 0 24 24" width="48" height="48" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path>
        <polyline points="22,6 12,13 2,6"></polyline>
      </svg>
    </div>

    <h1>Check Your Email</h1>
    
    <div class="confirmation-message">
      <p>We've sent you a confirmation email. Please check your inbox and follow the instructions to verify your account.</p>
      
      <div class="email-tips">
        <h3>Don't see the email?</h3>
        <ul>
          <li>Check your spam or junk folder</li>
          <li>Make sure you entered the correct email address</li>
          <li>Wait a few minutes for the email to arrive</li>
        </ul>
      </div>
    </div>
    
    <div class="confirm-actions">
      <button class="primary" on:click={() => push('/auth')}>
        Return to Sign In
      </button>
    </div>
  </div>
</div>

<style>
  .confirm-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--space-6);
    background: var(--bg-color);
  }

  .confirm-content {
    width: 100%;
    max-width: 500px;
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  }

  .confirm-icon {
    display: flex;
    justify-content: center;
    margin-bottom: var(--space-6);
    color: var(--color-primary-600);
  }

  h1 {
    font-size: 1.75rem;
    font-weight: 700;
    margin: 0 0 var(--space-6) 0;
    color: var(--text-color);
  }
  
  .confirmation-message {
    margin-bottom: var(--space-8);
    text-align: left;
  }

  .confirmation-message p {
    color: var(--text-muted);
    line-height: 1.6;
    margin-bottom: var(--space-6);
  }

  .email-tips {
    background-color: var(--color-neutral-50);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    border: 1px solid var(--border-color);
  }

  .email-tips h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }

  .email-tips ul {
    margin: 0;
    padding-left: var(--space-4);
    color: var(--text-muted);
  }

  .email-tips li {
    margin-bottom: var(--space-1);
    line-height: 1.4;
  }

  .email-tips li:last-child {
    margin-bottom: 0;
  }

  .confirm-actions {
    display: flex;
    justify-content: center;
  }

  @media (max-width: 640px) {
    .confirm-container {
      padding: var(--space-4);
    }

    .confirm-content {
      padding: var(--space-6);
    }

    h1 {
      font-size: 22px;
    }
  }
</style>