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

<div class="donate-button">
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
      <svg width="13" height="19" viewBox="0 0 13 19" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M11.6729 9.5C11.0043 8.9208 10.1542 8.61336 9.28187 8.63524H3.67478C3.41913 8.64191 3.16481 8.59521 2.92703 8.49793C2.68926 8.40065 2.47292 8.2548 2.29098 8.0691C2.10904 7.8834 1.96523 7.66168 1.86816 7.4172C1.77109 7.17273 1.72275 6.91052 1.72605 6.64629C1.71982 6.54345 1.71982 6.4403 1.72605 6.33745C1.80144 5.8653 2.04103 5.43782 2.39985 5.13529C2.75867 4.83276 3.21202 4.67599 3.67478 4.69441H9.19818C9.64873 4.694 10.0848 4.85897 10.4286 5.1599C10.7723 5.46083 11.0015 5.87815 11.0752 6.33745H12.8685C12.7934 5.3849 12.3742 4.49642 11.6942 3.84866C11.0141 3.2009 10.1231 2.8413 9.19818 2.84135H7.30923V0H5.8148V2.84135H3.67478C2.74989 2.8413 1.85885 3.2009 1.17881 3.84866C0.498775 4.49642 0.0795453 5.3849 0.00447298 6.33745C-0.00149099 6.44031 -0.00149099 6.54344 0.00447298 6.64629C0.00447298 7.14434 0.0994083 7.63752 0.283859 8.09765C0.468309 8.55779 0.738662 8.97588 1.07948 9.32806C1.7678 10.0393 2.70136 10.4389 3.67478 10.4389H9.34164C9.59527 10.4323 9.84761 10.4782 10.0838 10.574C10.32 10.6697 10.5352 10.8134 10.7168 10.9964C10.8984 11.1795 11.0427 11.3983 11.1412 11.6398C11.2397 11.8814 11.2905 12.141 11.2904 12.4031C11.3028 12.5428 11.3028 12.6834 11.2904 12.8231C11.1955 13.2578 10.9603 13.6462 10.6236 13.9246C10.2868 14.2029 9.86852 14.3547 9.43729 14.355H3.81825C3.38702 14.3547 2.96869 14.2029 2.63195 13.9246C2.29522 13.6462 2.06008 13.2578 1.96516 12.8231H0.159893C0.262636 13.7513 0.69227 14.608 1.36693 15.23C2.04159 15.852 2.91412 16.1957 3.81825 16.1957H5.8148V19H7.30923V16.1957H9.34164C10.2458 16.1957 11.1183 15.852 11.793 15.23C12.4676 14.608 12.8973 13.7513 13 12.8231V12.4031C12.9986 11.8482 12.8789 11.3005 12.6496 10.7987C12.4202 10.297 12.0868 9.8536 11.6729 9.5Z" fill="currentColor"/>
      </svg>
      {buttonText} {#if showAmount && amount > 0}(${amount}){/if}
    {/if}
  </button>
</div>

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

  .donate-button .button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
  }
  
</style>