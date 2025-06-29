<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { fade, fly } from 'svelte/transition';
  import DonateButton from './DonateButton.svelte';

  export let pieceId: string;
  export let pieceName: string = '';
  export let show: boolean = false;

  const dispatch = createEventDispatcher();
  
  let selectedAmount: number = 25;
  let customAmount: number = 0;
  let isCustomAmount: boolean = false;

  const predefinedAmounts = [10, 25, 50, 100];

  function closeModal() {
    dispatch('close');
  }

  function handleBackdropClick(event: MouseEvent) {
    if (event.target === event.currentTarget) {
      closeModal();
    }
  }

  function selectAmount(amount: number) {
    selectedAmount = amount;
    isCustomAmount = false;
  }

  function enableCustomAmount() {
    isCustomAmount = true;
    customAmount = selectedAmount;
  }

  $: donationAmount = isCustomAmount ? customAmount : selectedAmount;
</script>

{#if show}
  <div class="modal-backdrop" on:click={handleBackdropClick} transition:fade={{ duration: 200 }}>
    <div class="modal-content" in:fly={{ y: 20, duration: 300 }}>
      <button class="close-button" on:click={closeModal}>×</button>
      
      <div class="modal-header">
        <h2>Support this Peace Piece</h2>
        <p>Your donation helps bring this project to life and supports the artists involved.</p>
      </div>
      
      <div class="modal-body">
        <div class="amount-selection">
          <h3>Select donation amount</h3>
          
          <div class="amount-options">
            {#each predefinedAmounts as amount}
              <button 
                class="amount-option" 
                class:selected={selectedAmount === amount && !isCustomAmount}
                on:click={() => selectAmount(amount)}
              >
                ${amount}
              </button>
            {/each}
            
            <button 
              class="amount-option custom-option" 
              class:selected={isCustomAmount}
              on:click={enableCustomAmount}
            >
              Custom
            </button>
          </div>
          
          {#if isCustomAmount}
            <div class="custom-amount-input">
              <label for="custom-amount">Enter amount ($)</label>
              <input 
                type="number" 
                id="custom-amount" 
                bind:value={customAmount} 
                min="1" 
                step="1"
                placeholder="Enter amount"
              />
            </div>
          {/if}
        </div>
        
        <div class="donation-summary">
          <div class="summary-row">
            <span>Donation amount:</span>
            <span class="amount">${donationAmount}</span>
          </div>
          <div class="summary-row">
            <span>Processing fee:</span>
            <span>Covered by Peace Piece</span>
          </div>
          <div class="summary-row total">
            <span>Total:</span>
            <span class="amount">${donationAmount}</span>
          </div>
        </div>
        
        <div class="donation-message">
          <p>100% of your donation goes directly to supporting this project and its artists.</p>
        </div>
      </div>
      
      <div class="modal-footer">
        <button class="secondary" on:click={closeModal}>Cancel</button>
        <DonateButton 
          {pieceId} 
          {pieceName} 
          buttonText="Donate Now" 
          buttonClass="primary donate-button" 
          amount={donationAmount}
          disabled={isCustomAmount && (customAmount <= 0 || isNaN(customAmount))}
        />
      </div>
    </div>
  </div>
{/if}

<style>
  .modal-backdrop {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: var(--space-4);
    backdrop-filter: blur(4px);
  }
  
  .modal-content {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    width: 100%;
    max-width: 500px;
    max-height: 90vh;
    overflow-y: auto;
    position: relative;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
  }
  
  .close-button {
    position: absolute;
    top: var(--space-4);
    right: var(--space-4);
    background: none;
    border: none;
    font-size: 1.5rem;
    color: var(--text-muted);
    cursor: pointer;
    padding: 0;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: background-color 0.2s;
  }
  
  .close-button:hover {
    background-color: var(--border-color);
    color: var(--text-color);
  }
  
  .modal-header {
    padding: var(--space-6) var(--space-6) var(--space-4);
    border-bottom: 1px solid var(--border-color);
    text-align: center;
  }
  
  .modal-header h2 {
    margin: 0 0 var(--space-2) 0;
    font-size: 1.5rem;
    font-weight: 600;
    color: var(--text-color);
  }
  
  .modal-header p {
    margin: 0;
    color: var(--text-muted);
    font-size: 0.9rem;
  }
  
  .modal-body {
    padding: var(--space-6);
  }
  
  .amount-selection {
    margin-bottom: var(--space-6);
  }
  
  .amount-selection h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-3) 0;
    color: var(--text-color);
  }
  
  .amount-options {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(80px, 1fr));
    gap: var(--space-2);
  }
  
  .amount-option {
    padding: var(--space-2) var(--space-3);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    background: var(--bg-color);
    color: var(--text-color);
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }
  
  .amount-option:hover {
    border-color: var(--color-primary-400);
  }
  
  .amount-option.selected {
    background-color: var(--color-primary-600);
    color: white;
    border-color: var(--color-primary-600);
  }
  
  .custom-amount-input {
    margin-top: var(--space-4);
  }
  
  .custom-amount-input label {
    display: block;
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-bottom: var(--space-2);
  }
  
  .custom-amount-input input {
    width: 100%;
    padding: var(--space-2) var(--space-3);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    font-size: 1rem;
  }
  
  .donation-summary {
    background-color: var(--bg-color);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    margin-bottom: var(--space-4);
  }
  
  .summary-row {
    display: flex;
    justify-content: space-between;
    margin-bottom: var(--space-2);
    font-size: 0.9rem;
    color: var(--text-muted);
  }
  
  .summary-row:last-child {
    margin-bottom: 0;
  }
  
  .summary-row.total {
    margin-top: var(--space-3);
    padding-top: var(--space-3);
    border-top: 1px solid var(--border-color);
    font-weight: 500;
    color: var(--text-color);
  }
  
  .amount {
    font-weight: 500;
    color: var(--text-color);
  }
  
  .donation-message {
    text-align: center;
    font-size: 0.875rem;
    color: var(--text-muted);
  }
  
  .modal-footer {
    padding: var(--space-4) var(--space-6) var(--space-6);
    display: flex;
    justify-content: space-between;
    gap: var(--space-3);
  }
  
  .modal-footer button {
    flex: 1;
  }
  
  .donate-button {
    background-color: var(--color-success-600);
  }
  
  .donate-button:hover {
    background-color: var(--color-success-700);
  }
  
  @media (max-width: 480px) {
    .amount-options {
      grid-template-columns: repeat(2, 1fr);
    }
    
    .modal-footer {
      flex-direction: column;
    }
  }
</style>