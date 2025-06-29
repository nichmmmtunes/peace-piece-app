<script lang="ts">
  import { fade, fly } from 'svelte/transition';
</script>

<div class="payment-policy-container">
  <div class="payment-policy-header" in:fade>
    <h1>Payment Policy</h1>
    <p>Last updated: January 2025</p>
  </div>

  <div class="payment-policy-content">
    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 100 }}>
      <h2>1. Payment Processing</h2>
      <p>Peace Piece uses Stripe, a secure third-party payment processor, to handle all financial transactions. When you make a donation or payment through our platform, you are subject to both our policies and Stripe's terms of service.</p>
      
      <h3>Payment Methods</h3>
      <p>We accept the following payment methods:</p>
      <ul>
        <li>Credit cards (Visa, Mastercard, American Express, Discover)</li>
        <li>Debit cards</li>
        <li>Other payment methods supported by Stripe in your region</li>
      </ul>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 200 }}>
      <h2>2. Donation Policy</h2>
      <p>When you make a donation to a Peace Piece project:</p>
      <ul>
        <li>100% of your donation goes directly to supporting the project and its artists</li>
        <li>Peace Piece covers all payment processing fees</li>
        <li>Your donation helps bring creative projects to life and supports independent artists</li>
      </ul>
      
      <h3>Donation Distribution</h3>
      <p>Donations are distributed according to the following guidelines:</p>
      <ul>
        <li>Project organizers receive funds to cover production costs</li>
        <li>Contributing artists receive compensation as specified in the project details</li>
        <li>A portion may be allocated to the cause supported by the project, if applicable</li>
      </ul>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
      <h2>3. Refund Policy</h2>
      <p><strong>All donations are final and non-refundable.</strong> Due to the nature of our platform and the immediate allocation of funds to artists and projects, we cannot offer refunds for donations once they have been processed.</p>
      
      <p>In exceptional circumstances, such as technical errors resulting in duplicate charges, please contact our support team at <a href="mailto:payments@peacepiece.art">payments@peacepiece.art</a> within 7 days of the transaction.</p>
      
      <h3>Canceled Projects</h3>
      <p>In the rare event that a project is canceled after receiving funding:</p>
      <ul>
        <li>Organizers are required to provide a detailed explanation to all supporters</li>
        <li>Funds already distributed to artists for work completed will not be refunded</li>
        <li>Remaining funds may be redirected to similar projects or returned to donors at Peace Piece's discretion</li>
      </ul>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
      <h2>4. Payment Security</h2>
      <p>We take the security of your payment information seriously:</p>
      <ul>
        <li>All payment information is encrypted using industry-standard protocols</li>
        <li>Peace Piece does not store your full credit card details</li>
        <li>All transactions are processed through Stripe's secure payment infrastructure</li>
        <li>We comply with applicable data protection regulations</li>
      </ul>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 500 }}>
      <h2>5. Subscription Payments</h2>
      <p>For recurring subscription payments:</p>
      <ul>
        <li>You will be charged automatically according to the subscription terms you select</li>
        <li>You may cancel your subscription at any time through your account settings</li>
        <li>Cancellation will take effect at the end of your current billing period</li>
        <li>No partial refunds are provided for unused portions of a billing period</li>
      </ul>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 600 }}>
      <h2>6. Currency and Fees</h2>
      <p>All transactions on Peace Piece are processed in US Dollars (USD). If your payment method is in a different currency, your bank or card issuer will convert the amount using their exchange rate and may charge additional fees.</p>
      
      <p>Peace Piece covers standard payment processing fees for donations. However, additional fees may apply for:</p>
      <ul>
        <li>International transactions</li>
        <li>Currency conversion</li>
        <li>Chargebacks or disputed transactions</li>
      </ul>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 700 }}>
      <h2>7. Tax Considerations</h2>
      <p>Peace Piece is not a registered charitable organization. Donations made through our platform:</p>
      <ul>
        <li>Are generally not tax-deductible</li>
        <li>Should not be claimed as charitable contributions for tax purposes</li>
        <li>May be considered business expenses in some circumstances (consult your tax advisor)</li>
      </ul>
      
      <p>We do not provide tax receipts or documentation for donations. If you require documentation for a specific purpose, please contact us directly.</p>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 800 }}>
      <h2>8. Disputes and Chargebacks</h2>
      <p>If you believe you have been charged incorrectly, please contact us before initiating a chargeback with your payment provider. Unauthorized chargebacks may result in:</p>
      <ul>
        <li>Restriction of your account</li>
        <li>Additional fees</li>
        <li>Permanent ban from the platform in cases of abuse</li>
      </ul>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 900 }}>
      <h2>9. Changes to Payment Policy</h2>
      <p>We may update this Payment Policy from time to time. We will notify users of significant changes by:</p>
      <ul>
        <li>Posting the updated policy on our platform</li>
        <li>Sending an email notification to registered users</li>
        <li>Displaying a notice on the payment page</li>
      </ul>
      
      <p>Your continued use of Peace Piece after changes to the Payment Policy constitutes acceptance of the updated terms.</p>
    </section>

    <section class="payment-policy-section" in:fly={{ y: 20, duration: 300, delay: 1000 }}>
      <h2>10. Contact Information</h2>
      <p>If you have questions about our Payment Policy or need assistance with a transaction, please contact us:</p>
      <div class="contact-info">
        <p>Email: <a href="mailto:payments@peacepiece.art">payments@peacepiece.art</a></p>
        <p>Response time: Within 2 business days</p>
      </div>
    </section>
  </div>
</div>

<style>
  .payment-policy-container {
    padding: var(--space-6);
    max-width: 800px;
    margin: 0 auto;
  }

  .payment-policy-header {
    text-align: center;
    margin-bottom: var(--space-8);
    padding-bottom: var(--space-6);
    border-bottom: 1px solid var(--border-color);
  }

  .payment-policy-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .payment-policy-header p {
    color: var(--text-muted);
    font-size: 0.875rem;
  }

  .payment-policy-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .payment-policy-section {
    background: transparent;
    border: none;
    border-radius: 0px;
    padding: var(--space-6) 0px;
  }

  .payment-policy-section:not(:first-of-type) {
    border-top: 1px solid var(--border-color);
  }

  .payment-policy-section h2 {
    font-size: 1.25rem;
    font-weight: 500;
    margin-bottom: var(--space-3);
    color: var(--text-color);
  }

  .payment-policy-section h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: var(--space-4) 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .payment-policy-section h3:first-of-type {
    margin-top: var(--space-3);
  }

  .payment-policy-section p {
    color: var(--text-color);
    line-height: 1.6;
    margin-bottom: var(--space-3);
  }

  .payment-policy-section p:last-child {
    margin-bottom: 0;
  }

  .payment-policy-section ul {
    margin: var(--space-3) 0;
    padding-left: var(--space-4);
  }

  .payment-policy-section li {
    color: var(--text-color);
    line-height: 1.6;
    margin-bottom: var(--space-2);
  }

  .payment-policy-section li:last-child {
    margin-bottom: 0;
  }

  .contact-info {
    background: transparent;
    border-radius: var(--radius-md);
    padding: 0;
    margin-top: var(--space-3);
  }

  .contact-info p {
    margin-bottom: var(--space-2);
    font-size: 0.875rem;
  }

  .contact-info p:last-child {
    margin-bottom: 0;
  }

  .contact-info a {
    color: var(--text-color);
    text-decoration: underline;
    text-underline-offset: 3px;
  }

  .contact-info a:hover {
    text-decoration: underline;
  }

  @media (max-width: 768px) {
    .payment-policy-container {
      padding: var(--space-4);
    }

    .payment-policy-header h1 {
      font-size: 2rem;
    }

    .payment-policy-section {
      padding: var(--space-4);
    }
  }
</style>