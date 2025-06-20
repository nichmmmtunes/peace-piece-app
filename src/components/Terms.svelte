<script lang="ts">
  import { fade, fly } from 'svelte/transition';
</script>

<div class="terms-container">
  <div class="terms-header" in:fade>
    <h1>Terms of Use</h1>
    <p>Last updated: January 2025</p>
  </div>

  <div class="terms-content">
    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 100 }}>
      <h2>1. Acceptance of Terms</h2>
      <p>By accessing and using Peace Piece, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.</p>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 200 }}>
      <h2>2. Description of Service</h2>
      <p>Peace Piece is a platform that connects artists, organizers, and supporters to create collaborative artworks that promote peace, social causes, and positive change. Our service includes:</p>
      <ul>
        <li>Creating and sharing artistic content</li>
        <li>Collaborating with other users</li>
        <li>Following and supporting peace pieces</li>
        <li>Participating in community discussions</li>
      </ul>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
      <h2>3. User Accounts</h2>
      <p>To access certain features of the service, you must register for an account. You agree to:</p>
      <ul>
        <li>Provide accurate and complete information</li>
        <li>Maintain the security of your password</li>
        <li>Accept responsibility for all activities under your account</li>
        <li>Notify us immediately of any unauthorized use</li>
      </ul>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
      <h2>4. Content Guidelines</h2>
      <p>Users are responsible for the content they post. You agree not to post content that:</p>
      <ul>
        <li>Violates any laws or regulations</li>
        <li>Infringes on intellectual property rights</li>
        <li>Contains hate speech or promotes violence</li>
        <li>Is spam, misleading, or fraudulent</li>
        <li>Violates privacy or contains personal information of others</li>
      </ul>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 500 }}>
      <h2>5. Intellectual Property</h2>
      <p>You retain ownership of content you create and post on Peace Piece. By posting content, you grant us a non-exclusive, worldwide, royalty-free license to use, display, and distribute your content on the platform.</p>
      <p>The Peace Piece platform, including its design, features, and functionality, is owned by us and protected by copyright and other intellectual property laws.</p>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 600 }}>
      <h2>6. Privacy</h2>
      <p>Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the service, to understand our practices.</p>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 700 }}>
      <h2>7. Termination</h2>
      <p>We may terminate or suspend your account and access to the service immediately, without prior notice, for conduct that we believe violates these Terms of Use or is harmful to other users, us, or third parties.</p>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 800 }}>
      <h2>8. Disclaimers</h2>
      <p>The service is provided "as is" without any warranties, expressed or implied. We do not warrant that the service will be uninterrupted, error-free, or completely secure.</p>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 900 }}>
      <h2>9. Limitation of Liability</h2>
      <p>In no event shall Peace Piece be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your use of the service.</p>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 1000 }}>
      <h2>10. Changes to Terms</h2>
      <p>We reserve the right to modify these terms at any time. We will notify users of significant changes via email or through the platform. Continued use of the service after changes constitutes acceptance of the new terms.</p>
    </section>

    <section class="terms-section" in:fly={{ y: 20, duration: 300, delay: 1100 }}>
      <h2>11. Contact Information</h2>
      <p>If you have any questions about these Terms of Use, please contact us at:</p>
      <div class="contact-info">
        <p>Email: <a href="mailto:legal@peacepiece.org">legal@peacepiece.org</a></p>
        <p>Address: Peace Piece Legal Department<br>
        123 Harmony Street<br>
        Unity City, UC 12345</p>
      </div>
    </section>
  </div>
</div>

<style>
  .terms-container {
    padding: var(--space-6);
    max-width: 800px;
    margin: 0 auto;
  }

  .terms-header {
    text-align: center;
    margin-bottom: var(--space-8);
    padding-bottom: var(--space-6);
    border-bottom: 1px solid var(--border-color);
  }

  .terms-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .terms-header p {
    color: var(--text-muted);
    font-size: 0.875rem;
  }

  .terms-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .terms-section {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .terms-section h2 {
    font-size: 1.25rem;
    font-weight: 600;
    margin-bottom: var(--space-3);
    color: var(--color-primary-700);
  }

  .terms-section p {
    color: var(--text-color);
    line-height: 1.6;
    margin-bottom: var(--space-3);
  }

  .terms-section p:last-child {
    margin-bottom: 0;
  }

  .terms-section ul {
    margin: var(--space-3) 0;
    padding-left: var(--space-4);
  }

  .terms-section li {
    color: var(--text-color);
    line-height: 1.6;
    margin-bottom: var(--space-2);
  }

  .terms-section li:last-child {
    margin-bottom: 0;
  }

  .contact-info {
    background-color: var(--color-neutral-50);
    border-radius: var(--radius-md);
    padding: var(--space-4);
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
    color: var(--color-primary-600);
    text-decoration: none;
  }

  .contact-info a:hover {
    text-decoration: underline;
  }

  @media (max-width: 768px) {
    .terms-container {
      padding: var(--space-4);
    }

    .terms-header h1 {
      font-size: 2rem;
    }

    .terms-section {
      padding: var(--space-4);
    }
  }
</style>