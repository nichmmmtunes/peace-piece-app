<script lang="ts">
  import { signIn, signUp } from '../stores/authStore';
  import { push, link } from 'svelte-spa-router';
  import { fade, fly } from 'svelte/transition';

  let email = '';
  let password = '';
  let isSignUp = true;
  let loading = false;
  let error = '';
  
  async function handleSubmit() {
    loading = true;
    error = '';
    
    if (isSignUp) {
      const { error: authError } = await signUp(email, password);
      if (authError) {
        error = authError.message;
      } else {
        push('/confirm-signup');
      }
    } else {
      const { error: authError } = await signIn(email, password);
      if (authError) {
        error = authError.message;
      } else {
        push('/dashboard');
      }
    }
    
    loading = false;
  }
</script>

<div class="auth-container">
  <div class="auth-content">
    <div class="auth-header" in:fade>
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
      
      <div class="auth-title">
        <h1>{isSignUp ? 'Create Account' : 'Welcome Back'}</h1>
        <p>{isSignUp ? 'Join our community of artists and supporters' : 'Sign in to your Peace Piece account'}</p>
      </div>
    </div>

    <div class="auth-form" in:fly={{ y: 20, duration: 300 }}>
      <form on:submit|preventDefault={handleSubmit}>
        {#if error}
          <div class="error-message" transition:fade>
            <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
              <circle cx="12" cy="12" r="10"></circle>
              <line x1="15" y1="9" x2="9" y2="15"></line>
              <line x1="9" y1="9" x2="15" y2="15"></line>
            </svg>
            {error}
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
            placeholder="Enter your email"
            autocomplete="email"
          />
        </div>
        
        <div class="form-group">
          <label for="password">Password</label>
          <input
            type="password"
            id="password"
            bind:value={password}
            required
            disabled={loading}
            placeholder="Enter your password"
            autocomplete={isSignUp ? "new-password" : "current-password"}
          />
        </div>
        
        {#if !isSignUp}
          <div class="forgot-password-link">
            <a href="/forgot-password" use:link class="forgot-link">
              Forgot your password?
            </a>
          </div>
        {/if}
        
        <button type="submit" class="primary auth-button" disabled={loading}>
          {#if loading}
            <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
              <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
              </circle>
            </svg>
            {isSignUp ? 'Creating Account...' : 'Signing In...'}
          {:else}
            {isSignUp ? 'Create Account' : 'Sign In'}
          {/if}
        </button>
      </form>
      
      <div class="auth-toggle">
        <p>
          {isSignUp ? 'Already have an account?' : "Don't have an account?"}
          <button class="link-button" on:click={() => isSignUp = !isSignUp}>
            {isSignUp ? 'Sign In' : 'Sign Up'}
          </button>
        </p>
      </div>
    </div>
  </div>
</div>

<style>
  .auth-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--space-6);
    background: var(--bg-color);
  }

  .auth-content {
    width: 100%;
    max-width: 400px;
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  }

  .auth-header {
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
    font-weight: 500;
    font-size: 1.5rem;
    color: var(--text-color);
    font-family: var(--font-instrument-sans);
  }

  .auth-title h1 {
    font-size: 2.7rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .auth-title p {
    color: var(--text-muted);
    margin: 0 auto;
    max-width: 20ch;
  }

  .auth-form {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }
  
  .form-group {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
    margin-bottom: 12px;
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

  .forgot-password-link {
    text-align: center;
    margin: var(--space-2) 0;
  }

  .forgot-link {
    color: var(--text-color);
    text-decoration: none;
    font-size: 0.875rem;
    font-weight: 500;
    transition: color 0.2s;
  }

  .forgot-link:hover {
    color: var(--text-muted);
    text-decoration: underline;
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

  .auth-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3) var(--space-6);
    font-size: 1rem;
    font-weight: 500;
    margin: var(--space-2) auto 0;
    background: var(--bg-color);
    color: var(--text-color);
  }

  .spinner {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  .auth-toggle {
    text-align: center;
    padding-top: var(--space-4);
    border-top: 1px solid var(--border-color);
  }

  .auth-toggle p {
    color: var(--text-muted);
    margin: 0;
  }
  
  .link-button {
    background: none;
    border: none;
    color: var(--text-color);
    padding: 0;
    font: inherit;
    cursor: pointer;
    text-decoration: underline;
    margin-left: var(--space-1);
    border-radius: 0px;
  }
  
  .link-button:hover {
    color: var(--color-primary-400);
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
    .auth-container {
      padding: var(--space-4);
    }

    .auth-content {
      padding: var(--space-6);
    }

    .auth-title h1 {
      font-size: 33px;
    }
  }
</style>