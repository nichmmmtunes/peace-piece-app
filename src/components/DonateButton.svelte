<script lang="ts">
  import { onMount } from 'svelte';
  import { loadStripe } from '@stripe/stripe-js';
  import { supabase } from '../lib/supabase';
  import { user } from '../stores/authStore';
  import { products } from '../stripe-config';

  export let pieceId: string;
  export let pieceName: string = '';
  export let buttonText: string = 'Donate';
  export let buttonClass: string = 'primary';
  export let amount: number = 0; // Custom amount in dollars
  export let showAmount: boolean = false;
  export let disabled: boolean = false;

  let loading = false;
  let error = '';
  let stripePromise: Promise<any>;

  onMount(() => {
    // Initialize Stripe with your publishable key
    const stripeKey = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY;
    if (stripeKey) {
      stripePromise = loadStripe(stripeKey);
    } else {
      console.error('Stripe publishable key not found in environment variables');
    }
  });

  async function handleDonation() {
    if (!$user) {
      error = 'Please sign in to donate';
      return;
    }

    if (loading) return;

    try {
      loading = true;
      error = '';

      // Get the current URL for success and cancel redirects
      const origin = window.location.origin;
      const path = window.location.pathname;
      const successUrl = `${origin}/#/piece/${pieceId}?donation=success`;
      const cancelUrl = `${origin}/#/piece/${pieceId}?donation=canceled`;

      // Get the session and extract the access token
      const { data: sessionData } = await supabase.auth.getSession();
      const accessToken = sessionData.session?.access_token;
      
      if (!accessToken) {
        throw new Error('Failed to authenticate user');
      }

      // Call the Stripe checkout edge function with the proper access token
      const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/stripe-checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`
        },
        body: JSON.stringify({
          price_id: products.donation.priceId,
          success_url: successUrl,
          cancel_url: cancelUrl,
          mode: 'payment',
          piece_id: pieceId
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to create checkout session');
      }

      const { url } = await response.json();

      // Redirect to Stripe Checkout
      window.location.href = url;
    } catch (err: any) {
      console.error('Donation error:', err);
      error = err.message || 'An error occurred during donation';
    } finally {
      loading = false;
    }
  }
</script>

<button 
  class={buttonClass} 
  on:click={handleDonation} 
  disabled={disabled || loading}
  title="Support this piece with a donation"
>
  {#if loading}
    <svg class="spinner" viewBox="0 0 24 24" width="16" height="16">
      <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="60" stroke-dashoffset="60" stroke-linecap="round">
        <animate attributeName="stroke-dashoffset" dur="2s" values="60;0" repeatCount="indefinite"/>
      </circle>
    </svg>
    Processing...
  {:else}
    {buttonText} {#if showAmount && amount > 0}(${amount}){/if}
  {/if}
</button>

{#if error}
  <div class="error-message">{error}</div>
{/if}

<style>
  .spinner {
    animation: spin 1s linear infinite;
    margin-right: var(--space-2);
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .error-message {
    color: var(--color-error-600);
    font-size: 0.875rem;
    margin-top: var(--space-2);
  }
</style>