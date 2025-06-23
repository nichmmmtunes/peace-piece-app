<script lang="ts">
  import { fade, fly } from 'svelte/transition';
</script>

<div class="privacy-container">
  <div class="privacy-header" in:fade>
    <h1>Privacy Policy</h1>
    <p>Last updated: January 2025</p>
  </div>

  <div class="privacy-content">
    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 100 }}>
      <h2>1. Information We Collect</h2>
      <h3>Personal Information</h3>
      <p>When you create an account, we collect:</p>
      <ul>
        <li>Email address</li>
        <li>Username (optional)</li>
        <li>Profile photo (optional)</li>
        <li>Website URL (optional)</li>
      </ul>
      
      <h3>Content Information</h3>
      <p>When you use our platform, we collect:</p>
      <ul>
        <li>Peace pieces you create (text, images, audio)</li>
        <li>Comments and interactions</li>
        <li>Pieces you follow or support</li>
      </ul>

      <h3>Usage Information</h3>
      <p>We automatically collect:</p>
      <ul>
        <li>Device and browser information</li>
        <li>IP address and location data</li>
        <li>Usage patterns and preferences</li>
        <li>Performance and error data</li>
      </ul>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 200 }}>
      <h2>2. How We Use Your Information</h2>
      <p>We use your information to:</p>
      <ul>
        <li>Provide and improve our services</li>
        <li>Personalize your experience</li>
        <li>Communicate with you about updates and features</li>
        <li>Ensure platform security and prevent abuse</li>
        <li>Analyze usage patterns to improve functionality</li>
        <li>Comply with legal obligations</li>
      </ul>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
      <h2>3. Information Sharing</h2>
      <p>We do not sell your personal information. We may share information in these situations:</p>
      
      <h3>Public Content</h3>
      <p>Content you choose to make public (peace pieces, comments, profile information) is visible to other users and may be indexed by search engines.</p>
      
      <h3>Service Providers</h3>
      <p>We share information with trusted service providers who help us operate the platform, including:</p>
      <ul>
        <li>Cloud hosting services</li>
        <li>Analytics providers</li>
        <li>Email service providers</li>
        <li>Payment processors (for donations)</li>
      </ul>

      <h3>Legal Requirements</h3>
      <p>We may disclose information when required by law or to protect our rights and the safety of our users.</p>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
      <h2>4. Data Security</h2>
      <p>We implement appropriate security measures to protect your information:</p>
      <ul>
        <li>Encryption of data in transit and at rest</li>
        <li>Regular security audits and updates</li>
        <li>Access controls and authentication</li>
        <li>Secure data centers and infrastructure</li>
      </ul>
      <p>However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.</p>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 500 }}>
      <h2>5. Your Rights and Choices</h2>
      <h3>Account Management</h3>
      <p>You can:</p>
      <ul>
        <li>Update your profile information at any time</li>
        <li>Control the visibility of your content</li>
        <li>Delete your account and associated data</li>
      </ul>

      <h3>Communication Preferences</h3>
      <p>You can opt out of non-essential communications through your account settings.</p>

      <h3>Data Access and Portability</h3>
      <p>You can request a copy of your data or ask us to transfer it to another service.</p>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 600 }}>
      <h2>6. Cookies and Tracking</h2>
      <p>We use cookies and similar technologies to:</p>
      <ul>
        <li>Remember your preferences and settings</li>
        <li>Analyze how you use our platform</li>
        <li>Improve performance and functionality</li>
      </ul>
      <p>You can control cookie settings through your browser, but some features may not work properly if cookies are disabled.</p>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 700 }}>
      <h2>7. Children's Privacy</h2>
      <p>Peace Piece is not intended for children under 13. We do not knowingly collect personal information from children under 13. If we become aware that we have collected such information, we will delete it promptly.</p>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 800 }}>
      <h2>8. International Users</h2>
      <p>Peace Piece is operated from the United States. If you are accessing our service from outside the US, your information may be transferred to, stored, and processed in the US where our servers are located.</p>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 900 }}>
      <h2>9. Changes to This Policy</h2>
      <p>We may update this Privacy Policy from time to time. We will notify you of significant changes by:</p>
      <ul>
        <li>Posting the updated policy on our platform</li>
        <li>Sending an email notification</li>
        <li>Displaying a prominent notice on the platform</li>
      </ul>
      <p>Your continued use of Peace Piece after changes become effective constitutes acceptance of the updated policy.</p>
    </section>

    <section class="privacy-section" in:fly={{ y: 20, duration: 300, delay: 1000 }}>
      <h2>10. Contact Us</h2>
      <p>If you have questions about this Privacy Policy or our data practices, please contact us:</p>
      <div class="contact-info">
        <p>Email: <a href="mailto:privacy@peacepiece.org">privacy@peacepiece.org</a></p>
        <p>Address: Peace Piece Privacy Team<br>
        123 Harmony Street<br>
        Unity City, UC 12345</p>
      </div>
    </section>
  </div>
</div>

<style>
  .privacy-container {
    padding: var(--space-6);
    max-width: 800px;
    margin: 0 auto;
  }

  .privacy-header {
    text-align: center;
    margin-bottom: var(--space-8);
    padding-bottom: var(--space-6);
    border-bottom: 1px solid var(--border-color);
  }

  .privacy-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .privacy-header p {
    color: var(--text-muted);
    font-size: 0.875rem;
  }

  .privacy-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .privacy-section {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .privacy-section h2 {
    font-size: 1.25rem;
    font-weight: 500;
    margin-bottom: var(--space-3);
    color: var(--color-primary-700);
  }

  .privacy-section h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: var(--space-4) 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .privacy-section h3:first-of-type {
    margin-top: var(--space-3);
  }

  .privacy-section p {
    color: var(--text-color);
    line-height: 1.6;
    margin-bottom: var(--space-3);
  }

  .privacy-section p:last-child {
    margin-bottom: 0;
  }

  .privacy-section ul {
    margin: var(--space-3) 0;
    padding-left: var(--space-4);
  }

  .privacy-section li {
    color: var(--text-color);
    line-height: 1.6;
    margin-bottom: var(--space-2);
  }

  .privacy-section li:last-child {
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
    .privacy-container {
      padding: var(--space-4);
    }

    .privacy-header h1 {
      font-size: 2rem;
    }

    .privacy-section {
      padding: var(--space-4);
    }
  }
</style>