<script lang="ts">
  import { fade, fly } from 'svelte/transition';
</script>

<div class="help-container">
  <div class="help-header" in:fade>
    <h1>Help & FAQ</h1>
    <p>Find answers to common questions and get help with Peace Piece</p>
  </div>

  <div class="help-content">
    <!-- Quick Links -->
    <section class="quick-links" in:fly={{ y: 20, duration: 300, delay: 100 }}>
      <h2>Quick Links</h2>
      <div class="links-grid">
        <a href="#getting-started" class="link-card">
          <div class="link-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
              <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
          </div>
          <div class="link-content">
            <h3>Getting Started</h3>
            <p>Learn the basics of Peace Piece</p>
          </div>
        </a>

        <a href="#account" class="link-card">
          <div class="link-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
              <circle cx="12" cy="7" r="4"></circle>
            </svg>
          </div>
          <div class="link-content">
            <h3>Account & Profile</h3>
            <p>Manage your account settings</p>
          </div>
        </a>

        <a href="#pieces" class="link-card">
          <div class="link-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M9 12l2 2 4-4"></path>
              <path d="M21 12c-1 0-3-1-3-3s2-3 3-3 3 1 3 3-2 3-3 3"></path>
              <path d="M3 12c1 0 3-1 3-3s-2-3-3-3-3 1-3 3 2 3 3 3"></path>
            </svg>
          </div>
          <div class="link-content">
            <h3>Peace Pieces</h3>
            <p>Creating and managing pieces</p>
          </div>
        </a>

        <a href="#support" class="link-card">
          <div class="link-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
          </div>
          <div class="link-content">
            <h3>Contact Support</h3>
            <p>Get help from our team</p>
          </div>
        </a>
      </div>
    </section>

    <!-- FAQ Sections -->
    <section class="faq-section" in:fly={{ y: 20, duration: 300, delay: 200 }}>
      <h2 id="getting-started">Getting Started</h2>
      <div class="faq-list">
        <div class="faq-item">
          <h3>What is Peace Piece?</h3>
          <p>Peace Piece is a platform that connects artists, organizers, and supporters to create collaborative artworks that promote peace, social causes, and positive change in the world.</p>
        </div>

        <div class="faq-item">
          <h3>How do I create an account?</h3>
          <p>Click the "Sign Up" button on the homepage, enter your email and password, then verify your email address. Once verified, you can complete your profile and start exploring.</p>
        </div>

        <div class="faq-item">
          <h3>Is Peace Piece free to use?</h3>
          <p>Yes! Creating an account, browsing pieces, and following artists is completely free. You can also support pieces through donations if you choose to.</p>
        </div>
      </div>
    </section>

    <section class="faq-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
      <h2 id="account">Account & Profile</h2>
      <div class="faq-list">
        <div class="faq-item">
          <h3>How do I update my profile?</h3>
          <p>Go to Settings from the sidebar menu. You can update your username, website, and profile photo. Changes are saved automatically.</p>
        </div>

        <div class="faq-item">
          <h3>Can I change my email address?</h3>
          <p>Currently, email addresses cannot be changed after account creation. If you need to change your email, please contact our support team.</p>
        </div>

        <div class="faq-item">
          <h3>How do I delete my account?</h3>
          <p>Account deletion can be requested through the Settings page under the "Danger Zone" section. This action is permanent and cannot be undone.</p>
        </div>
      </div>
    </section>

    <section class="faq-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
      <h2 id="pieces">Peace Pieces</h2>
      <div class="faq-list">
        <div class="faq-item">
          <h3>What types of content can I share?</h3>
          <p>You can share various forms of artistic expression including poetry, visual art, music, and multimedia pieces that promote peace and positive social change.</p>
        </div>

        <div class="faq-item">
          <h3>How do I follow a piece?</h3>
          <p>Click the heart icon on any piece detail page to follow it. You'll receive notifications about updates and can easily find followed pieces in your dashboard.</p>
        </div>

        <div class="faq-item">
          <h3>Can I collaborate with other artists?</h3>
          <p>Yes! Peace Piece encourages collaboration. You can add contributors to your pieces and work together with other artists and organizers.</p>
        </div>
      </div>
    </section>

    <section class="faq-section" in:fly={{ y: 20, duration: 300, delay: 500 }}>
      <h2 id="support">Support & Contact</h2>
      <div class="faq-list">
        <div class="faq-item">
          <h3>How can I contact support?</h3>
          <p>You can reach our support team at <a href="mailto:support@peacepiece.org">support@peacepiece.org</a>. We typically respond within 24 hours during business days.</p>
        </div>

        <div class="faq-item">
          <h3>How do I report inappropriate content?</h3>
          <p>If you encounter content that violates our community guidelines, please contact us immediately with details about the specific piece or user.</p>
        </div>

        <div class="faq-item">
          <h3>Can I suggest new features?</h3>
          <p>Absolutely! We love hearing from our community. Send your feature suggestions to <a href="mailto:feedback@peacepiece.org">feedback@peacepiece.org</a>.</p>
        </div>
      </div>
    </section>
  </div>
</div>

<style>
  .help-container {
    padding: var(--space-6);
    max-width: 900px;
    margin: 0 auto;
  }

  .help-header {
    text-align: center;
    margin-bottom: var(--space-8);
  }

  .help-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .help-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
  }

  .help-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-8);
  }

  .quick-links h2,
  .faq-section h2 {
    margin-bottom: var(--space-4);
    color: var(--text-color);
  }

  .links-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: var(--space-4);
  }

  .link-card {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    padding: var(--space-4);
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    text-decoration: none;
    color: inherit;
    transition: all 0.2s;
  }

  .link-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px var(--shadow-color);
    border-color: var(--color-primary-300);
  }

  .link-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 48px;
    height: 48px;
    background-color: var(--color-primary-100);
    color: var(--color-primary-600);
    border-radius: var(--radius-lg);
    flex-shrink: 0;
  }

  .link-content h3 {
    font-size: 1rem;
    font-weight: 500;
    margin: 0 0 var(--space-1) 0;
    color: var(--text-color);
  }

  .link-content p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
  }

  .faq-section {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .faq-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .faq-item {
    padding-bottom: var(--space-4);
    border-bottom: 1px solid var(--border-color);
  }

  .faq-item:last-child {
    border-bottom: none;
    padding-bottom: 0;
  }

  .faq-item h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .faq-item p {
    color: var(--text-muted);
    line-height: 1.6;
    margin: 0;
  }

  .faq-item a {
    color: var(--text-color);
    text-decoration: underline;
    text-underline-offset: 3px;
  }

  .faq-item a:hover {
    text-decoration: underline;
  }

  @media (max-width: 768px) {
    .help-container {
      padding: var(--space-4);
    }

    .help-header h1 {
      font-size: 2rem;
    }

    .links-grid {
      grid-template-columns: 1fr;
    }

    .link-card {
      flex-direction: column;
      text-align: center;
    }
  }
</style>