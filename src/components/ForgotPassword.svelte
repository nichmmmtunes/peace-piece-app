<script lang="ts">
  import { push } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { fade, fly } from 'svelte/transition';
  
  let email = '';
  let loading = false;
  let message = '';
  let success = false;
  
  async function handleSubmit() {
    loading = true;
    message = '';
    
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });
      
      if (error) throw error;
      
      success = true;
      message = 'Password reset email sent! Please check your inbox.';
    } catch (error: any) {
      message = error.message;
    } finally {
      loading = false;
    }
  }
</script>

<div class="forgot-password-container">
  <div class="forgot-password-content" in:fade>
    <div class="forgot-password-header">
      <div class="logo">
        <div class="logo-icon">
          <svg viewBox="0 0 597 933" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M295.474 730.578C296.983 727.764 301.017 727.764 302.526 730.578L402.365 916.86C403.793 919.525 401.862 922.75 398.839 922.75H199.161C196.138 922.75 194.207 919.525 195.635 916.86L295.474 730.578Z" fill="currentColor" stroke="currentColor" stroke-width="20"/>
            <path d="M294.854 181.425C296.249 178.22 300.794 178.22 302.189 181.425L382.606 366.153C383.756 368.795 381.82 371.75 378.938 371.75H218.104C215.222 371.75 213.286 368.795 214.436 366.153L294.854 181.425Z" fill="currentColor" stroke="currentColor" stroke-width="20"/>
            <path d="M302.554 761.123C301.063 764.008 296.937 764.008 295.446 761.123L132.275 445.336C130.899 442.674 132.832 439.5 135.828 439.5L462.172 439.5C465.168 439.5 467.101 442.674 465.725 445.336L302.554 761.123Z" fill="currentColor" stroke="currentColor" stroke-width="20"/>
            <path d="M176 14C176 11.7909 177.791 10 180 10H362C395.137 10 422 36.8629 422 70V170C422 172.209 420.209 174 418 174H236C202.863 174 176 147.137 176 114V14Z" fill="currentColor" stroke="currentColor" stroke-width="20"/>
            <path d="M314.513 536.553C249.178 450.905 291.655 326.35 395.709 298.469C499.762 270.588 598.825 357.217 585.068 464.059L539.249 819.876C538.793 823.421 534.27 824.633 532.102 821.791L314.513 536.553Z" fill="currentColor"/>
            <path d="M282.702 536.553C348.038 450.905 305.56 326.35 201.507 298.469C97.4538 270.588 -1.60994 357.217 12.148 464.059L57.9663 819.876C58.4228 823.421 62.9459 824.633 65.1139 821.791L282.702 536.553Z" fill="currentColor"/>
            <path d="M314.513 536.553C249.178 450.905 291.655 326.35 395.709 298.469C499.762 270.588 598.825 357.217 585.068 464.059L539.249 819.876C538.793 823.421 534.27 824.633 532.102 821.791L314.513 536.553Z" stroke="currentColor" stroke-width="20"/>
            <path d="M282.702 536.553C348.038 450.905 305.56 326.35 201.507 298.469C97.4538 270.588 -1.60994 357.217 12.148 464.059L57.9663 819.876C58.4228 823.421 62.9459 824.633 65.1139 821.791L282.702 536.553Z" stroke="currentColor" stroke-width="20"/>
          </svg>
        </div>
        <span class="logo-text">Peace Piece</span>
      </div>
      
      <div class="forgot-password-title">
        <h1>Reset Your Password</h1>
        <p>Enter your email address and we'll send you a link to reset your password</p>
      </div>
    </div>

    <div class="forgot-password-form" in:fly={{ y: 20, duration: 300 }}>
      {#if success}
        <div class="success-message" transition:fade>
          <div class="success-icon">
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
              <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
          </div>
          <div class="success-content">
            <h3>Email Sent!</h3>
            <p>{message}</p>
            <div class="success-instructions">
              <p><strong>Next steps:</strong></p>
              <ol>
                <li>Check your email inbox (and spam folder)</li>
                <li>Click the reset link in the email</li>
                <li>Create a new password</li>
              </ol>
            </div>
          </div>
        </div>
      {:else}
        <form on:submit|preventDefault={handleSubmit}>
          {#if message && !success}
            <div class="error-message" transition:fade>
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="15" y1="9" x2="9" y2="15"></line>
                <line x1="9" y1="9" x2="15" y2="15"></line>
              </svg>
              {message}
            </div>
          {/if}
          
          <div class="form-group">
            <label for="email">Email Address</label>
            <input
              type="email"
              id="email"
              bind:value={email}
              required
              disabled={loading}
              placeholder="Enter your email address"
              autocomplete="email"
            />
          </div>
          
          <button type="submit" class="primary reset-button" disabled={loading || !email.trim()}>
            {#if loading}
              <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                  <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                </circle>
              </svg>
              Sending Reset Link...
            {:else}
              Send Reset Link
            {/if}
          </button>
        </form>
      {/if}
      
      <div class="back-to-signin">
        <p>
          Remember your password?
          <button class="link-button" on:click={() => push('/auth')}>
            Back to Sign In
          </button>
        </p>
      </div>
    </div>
  </div>
</div>

<style>
  .forgot-password-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--space-6);
    background: var(--bg-color);
  }

  .forgot-password-content {
    width: 100%;
    max-width: 450px;
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  }

  .forgot-password-header {
    text-align: center;
    margin-bottom: var(--space-8);
  }

  .logo {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-3);
    margin-bottom: var(--space-6);
  }

  .logo-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    color: var(--color-primary-600);
  }

  .logo-icon svg {
    width: 100%;
    height: 100%;
  }

  .logo-text {
    font-weight: 700;
    font-size: 22px;
    color: var(--text-color);
  }

  .forgot-password-title h1 {
    font-size: 1.75rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .forgot-password-title p {
    color: var(--text-muted);
    margin: 0;
    line-height: 1.5;
  }

  .forgot-password-form {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }
  
  .form-group {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .form-group label {
    font-weight: 500;
    color: var(--text-color);
  }

  .form-group input {
    padding: var(--space-3);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    background: var(--card-bg);
    color: var(--text-color);
    font-size: 1rem;
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  .form-group input:focus {
    outline: none;
    border-color: var(--color-primary-500);
    box-shadow: 0 0 0 3px var(--color-primary-100);
  }

  .form-group input:disabled {
    background-color: var(--color-neutral-50);
    color: var(--text-muted);
    cursor: not-allowed;
  }
  
  .error-message {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    background-color: var(--color-error-50);
    color: var(--color-error-700);
    padding: var(--space-3);
    border-radius: var(--radius-md);
    border: 1px solid var(--color-error-200);
    font-size: 0.875rem;
  }

  .success-message {
    background-color: var(--color-success-50);
    border: 1px solid var(--color-success-200);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    text-align: center;
  }

  .success-icon {
    display: flex;
    justify-content: center;
    margin-bottom: var(--space-4);
  }

  .success-icon svg {
    width: 48px;
    height: 48px;
    color: var(--color-success-600);
    background-color: var(--color-success-100);
    border-radius: 50%;
    padding: var(--space-3);
  }

  .success-content h3 {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--color-success-800);
    margin: 0 0 var(--space-2) 0;
  }

  .success-content p {
    color: var(--color-success-700);
    margin: 0 0 var(--space-4) 0;
  }

  .success-instructions {
    text-align: left;
    background-color: var(--color-success-25);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    margin-top: var(--space-4);
  }

  .success-instructions p {
    font-weight: 600;
    margin-bottom: var(--space-2);
  }

  .success-instructions ol {
    margin: 0;
    padding-left: var(--space-4);
  }

  .success-instructions li {
    color: var(--color-success-700);
    margin-bottom: var(--space-1);
    line-height: 1.4;
  }

  .success-instructions li:last-child {
    margin-bottom: 0;
  }

  .reset-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3);
    font-size: 1rem;
    font-weight: 500;
    margin-top: var(--space-2);
  }

  .spinner {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  .back-to-signin {
    text-align: center;
    padding-top: var(--space-4);
    border-top: 1px solid var(--border-color);
  }

  .back-to-signin p {
    color: var(--text-muted);
    margin: 0;
  }
  
  .link-button {
    background: none;
    border: none;
    color: var(--color-primary-600);
    padding: 0;
    font: inherit;
    cursor: pointer;
    text-decoration: underline;
    margin-left: var(--space-1);
  }
  
  .link-button:hover {
    color: var(--color-primary-500);
  }

  /* Dark mode adjustments */
  @media (prefers-color-scheme: dark) {
    .logo-icon {
      color: var(--color-primary-400);
    }
  }

  :global(.dark-mode) .logo-icon {
    color: var(--color-primary-400);
  }

  @media (max-width: 640px) {
    .forgot-password-container {
      padding: var(--space-4);
    }

    .forgot-password-content {
      padding: var(--space-6);
    }

    .forgot-password-title h1 {
      font-size: 22px;
    }
  }
</style>