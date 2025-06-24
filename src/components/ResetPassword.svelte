<script lang="ts">
  import { onMount } from 'svelte';
  import { push } from 'svelte-spa-router';
  import { supabase } from '../lib/supabase';
  import { fade, fly } from 'svelte/transition';
  
  let password = '';
  let confirmPassword = '';
  let loading = false;
  let message = '';
  let success = false;
  let validSession = false;
  let checkingSession = true;
  
  onMount(async () => {
    // Check if we have a valid session from the reset link
    try {
      console.log('🔍 DEBUG: Starting session check');
      console.log('🔍 DEBUG: Current URL hash:', window.location.hash);
      
      // First, try to parse tokens from the URL hash manually
      const hashParams = new URLSearchParams(window.location.hash.split('#').pop() || '');
      const accessToken = hashParams.get('access_token');
      const refreshToken = hashParams.get('refresh_token');
      const tokenType = hashParams.get('type');
      
      console.log('🔍 DEBUG: Parsed tokens:', {
        accessToken: accessToken ? 'present' : 'missing',
        refreshToken: refreshToken ? 'present' : 'missing',
        tokenType
      });
      
      if (accessToken && refreshToken && tokenType === 'recovery') {
        console.log('🔍 DEBUG: Found recovery tokens, setting session');
        
        // Manually set the session with the extracted tokens
        const { data, error } = await supabase.auth.setSession({
          access_token: accessToken,
          refresh_token: refreshToken
        });
        
        console.log('🔍 DEBUG: setSession result:', { data: !!data, error });
        
        if (error) {
          console.error('🔍 DEBUG: Error setting session:', error);
          throw error;
        }
        
        if (data.session) {
          console.log('🔍 DEBUG: Session set successfully');
          validSession = true;
          
          // Clean up the URL by removing the sensitive tokens from the hash
          const cleanHash = window.location.hash.split('#')[0];
          window.history.replaceState(null, '', window.location.pathname + cleanHash);
          console.log('🔍 DEBUG: URL cleaned up');
        } else {
          console.log('🔍 DEBUG: No session data returned');
          throw new Error('No session data returned');
        }
      } else {
        console.log('🔍 DEBUG: No recovery tokens found, checking existing session');
        
        // Fallback to checking existing session
        const { data: { session }, error } = await supabase.auth.getSession();
        
        console.log('🔍 DEBUG: getSession result:', { session: !!session, error });
        
        if (error) throw error;
        
        if (session) {
          validSession = true;
          console.log('🔍 DEBUG: Valid existing session found');
        } else {
          console.log('🔍 DEBUG: No valid session found');
          message = 'Invalid or expired reset link. Please request a new password reset.';
        }
      }
    } catch (error: any) {
      console.error('🔍 DEBUG: Session check error:', error);
      message = 'Invalid or expired reset link. Please request a new password reset.';
    } finally {
      checkingSession = false;
      console.log('🔍 DEBUG: Session check complete, validSession:', validSession);
    }
  });
  
  async function handleSubmit() {
    if (password !== confirmPassword) {
      message = 'Passwords do not match';
      return;
    }
    
    if (password.length < 6) {
      message = 'Password must be at least 6 characters long';
      return;
    }
    
    loading = true;
    message = '';
    
    try {
      const { error } = await supabase.auth.updateUser({
        password: password
      });
      
      if (error) throw error;
      
      success = true;
      message = 'Password updated successfully!';
      
      // Redirect to dashboard after a short delay
      setTimeout(() => {
        push('/dashboard');
      }, 2000);
    } catch (error: any) {
      message = error.message;
    } finally {
      loading = false;
    }
  }
  
  function getPasswordStrength(password: string): { strength: number, label: string, color: string } {
    if (!password) return { strength: 0, label: '', color: '' };
    
    let score = 0;
    
    // Length check
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    
    // Character variety
    if (/[a-z]/.test(password)) score += 1;
    if (/[A-Z]/.test(password)) score += 1;
    if (/[0-9]/.test(password)) score += 1;
    if (/[^A-Za-z0-9]/.test(password)) score += 1;
    
    if (score <= 2) return { strength: score, label: 'Weak', color: 'var(--color-error-600)' };
    if (score <= 4) return { strength: score, label: 'Medium', color: 'var(--color-warning-600)' };
    return { strength: score, label: 'Strong', color: 'var(--color-success-600)' };
  }
  
  $: passwordStrength = getPasswordStrength(password);
</script>

<div class="reset-password-container">
  <div class="reset-password-content" in:fade>
    <div class="reset-password-header">
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
      
      <div class="reset-password-title">
        <h1>Create New Password</h1>
        <p>Enter a strong password for your account</p>
      </div>
    </div>

    <div class="reset-password-form" in:fly={{ y: 20, duration: 300 }}>
      {#if checkingSession}
        <div class="loading-state">
          <div class="loading-spinner"></div>
          <p>Verifying reset link...</p>
        </div>
      {:else if !validSession}
        <div class="error-state" transition:fade>
          <div class="error-icon">
            <svg viewBox="0 0 24 24" width="48" height="48" stroke="currentColor" stroke-width="2" fill="none">
              <circle cx="12" cy="12" r="10"></circle>
              <line x1="15" y1="9" x2="9" y2="15"></line>
              <line x1="9" y1="9" x2="15" y2="15"></line>
            </svg>
          </div>
          <h3>Reset Link Invalid or Expired</h3>
          <p>This password reset link is no longer valid. This can happen if:</p>
          <ul class="error-reasons">
            <li>The link has expired (links are valid for 1 hour)</li>
            <li>The link has already been used</li>
            <li>A new password reset was requested</li>
          </ul>
          <div class="error-actions">
            <button class="primary" on:click={() => push('/forgot-password')}>
              Request New Reset Link
            </button>
            <button class="secondary" on:click={() => push('/auth')}>
              Back to Sign In
            </button>
          </div>
        </div>
      {:else if success}
        <div class="success-message" transition:fade>
          <div class="success-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
              <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
          </div>
          <h3>Password Updated!</h3>
          <p>{message}</p>
          <p class="redirect-notice">Redirecting to your dashboard...</p>
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
            <label for="password">New Password</label>
            <input
              type="password"
              id="password"
              bind:value={password}
              required
              disabled={loading}
              placeholder="Enter your new password"
              autocomplete="new-password"
            />
            {#if password}
              <div class="password-strength">
                <div class="strength-bar">
                  <div 
                    class="strength-fill" 
                    style="width: {(passwordStrength.strength / 6) * 100}%; background-color: {passwordStrength.color}"
                  ></div>
                </div>
                <span class="strength-label" style="color: {passwordStrength.color}">
                  {passwordStrength.label}
                </span>
              </div>
            {/if}
          </div>
          
          <div class="form-group">
            <label for="confirmPassword">Confirm New Password</label>
            <input
              type="password"
              id="confirmPassword"
              bind:value={confirmPassword}
              required
              disabled={loading}
              placeholder="Confirm your new password"
              autocomplete="new-password"
            />
            {#if confirmPassword && password !== confirmPassword}
              <div class="password-mismatch">
                <svg viewBox="0 0 24 24" width="14" height="14" stroke="currentColor" stroke-width="2" fill="none">
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="15" y1="9" x2="9" y2="15"></line>
                  <line x1="9" y1="9" x2="15" y2="15"></line>
                </svg>
                Passwords do not match
              </div>
            {/if}
          </div>
          
          <div class="password-requirements">
            <h4>Password Requirements:</h4>
            <ul>
              <li class:met={password.length >= 6}>At least 6 characters</li>
              <li class:met={/[a-z]/.test(password)}>Lowercase letter</li>
              <li class:met={/[A-Z]/.test(password)}>Uppercase letter</li>
              <li class:met={/[0-9]/.test(password)}>Number</li>
              <li class:met={/[^A-Za-z0-9]/.test(password)}>Special character</li>
            </ul>
          </div>
          
          <button 
            type="submit" 
            class="primary reset-button" 
            disabled={loading || !password || !confirmPassword || password !== confirmPassword}
          >
            {#if loading}
              <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
                  <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
                </circle>
              </svg>
              Updating Password...
            {:else}
              Reset Password
            {/if}
          </button>
        </form>
      {/if}
    </div>
  </div>
</div>

<style>
  .reset-password-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--space-6);
    background: linear-gradient(135deg, var(--color-primary-50), var(--color-accent-50));
  }

  .reset-password-content {
    width: 100%;
    max-width: 450px;
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  }

  .reset-password-header {
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

  .reset-password-title h1 {
    font-size: 1.75rem;
    font-weight: 700;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .reset-password-title p {
    color: var(--text-muted);
    margin: 0;
  }

  .reset-password-form {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .loading-state {
    text-align: center;
    padding: var(--space-8);
  }

  .loading-spinner {
    width: 40px;
    height: 40px;
    border: 3px solid var(--border-color);
    border-top: 3px solid var(--color-primary-600);
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto var(--space-4) auto;
  }

  .error-state {
    text-align: center;
    padding: var(--space-6);
    background-color: var(--color-error-50);
    border: 1px solid var(--color-error-200);
    border-radius: var(--radius-lg);
  }

  .error-icon {
    display: flex;
    justify-content: center;
    margin-bottom: var(--space-4);
  }

  .error-icon svg {
    color: var(--color-error-600);
    background-color: var(--color-error-100);
    border-radius: 50%;
    padding: var(--space-3);
  }

  .error-state h3 {
    color: var(--color-error-800);
    margin: 0 0 var(--space-3) 0;
    font-size: 1.25rem;
    font-weight: 500;
  }

  .error-state p {
    color: var(--color-error-700);
    margin: 0 0 var(--space-3) 0;
    line-height: 1.5;
  }

  .error-reasons {
    text-align: left;
    margin: var(--space-4) 0;
    padding-left: var(--space-4);
    color: var(--color-error-700);
  }

  .error-reasons li {
    margin-bottom: var(--space-2);
    line-height: 1.4;
  }

  .error-reasons li:last-child {
    margin-bottom: 0;
  }

  .error-actions {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
    margin-top: var(--space-6);
  }

  .error-actions .secondary {
    background-color: transparent;
    color: var(--color-error-600);
    border: 1px solid var(--color-error-300);
  }

  .error-actions .secondary:hover {
    background-color: var(--color-error-50);
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

  .password-strength {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    margin-top: var(--space-1);
  }

  .strength-bar {
    flex: 1;
    height: 4px;
    background-color: var(--color-neutral-200);
    border-radius: 2px;
    overflow: hidden;
  }

  .strength-fill {
    height: 100%;
    transition: width 0.3s, background-color 0.3s;
  }

  .strength-label {
    font-size: 0.75rem;
    font-weight: 500;
  }

  .password-mismatch {
    display: flex;
    align-items: center;
    gap: var(--space-1);
    color: var(--color-error-600);
    font-size: 0.875rem;
    margin-top: var(--space-1);
  }

  .password-requirements {
    background-color: var(--color-neutral-50);
    border-radius: var(--radius-md);
    padding: var(--space-4);
  }

  .password-requirements h4 {
    font-size: 0.875rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .password-requirements ul {
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .password-requirements li {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-bottom: var(--space-1);
    position: relative;
    padding-left: var(--space-4);
  }

  .password-requirements li:last-child {
    margin-bottom: 0;
  }

  .password-requirements li::before {
    content: '○';
    position: absolute;
    left: 0;
    color: var(--color-neutral-400);
  }

  .password-requirements li.met {
    color: var(--color-success-600);
  }

  .password-requirements li.met::before {
    content: '●';
    color: var(--color-success-600);
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
    color: var(--color-success-600);
    background-color: var(--color-success-100);
    border-radius: 50%;
    padding: var(--space-3);
  }

  .success-message h3 {
    font-size: 1.25rem;
    font-weight: 500;
    color: var(--color-success-800);
    margin: 0 0 var(--space-2) 0;
  }

  .success-message p {
    color: var(--color-success-700);
    margin: 0 0 var(--space-2) 0;
  }

  .redirect-notice {
    font-size: 0.875rem;
    font-style: italic;
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
    .reset-password-container {
      padding: var(--space-4);
    }

    .reset-password-content {
      padding: var(--space-6);
    }

    .reset-password-title h1 {
      font-size: 1.5rem;
    }

    .error-actions {
      gap: var(--space-2);
    }
  }
</style>