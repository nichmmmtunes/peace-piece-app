<script lang="ts">
  import { fade, fly } from 'svelte/transition';
</script>

<div class="community-container">
  <div class="community-header" in:fade>
    <h1>Community Policies</h1>
    <p>Guidelines for creating a safe, inclusive, and inspiring community</p>
  </div>

  <div class="community-content">
    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 100 }}>
      <h2>Our Mission</h2>
      <p>Peace Piece exists to foster creativity, collaboration, and positive change through art. We believe in the power of artistic expression to bring people together, promote understanding, and create a more peaceful world.</p>
    </section>

    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 200 }}>
      <h2>Community Values</h2>
      <div class="values-grid">
        <div class="value-card">
          <div class="value-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
            </svg>
          </div>
          <h3>Respect</h3>
          <p>Treat all community members with dignity and kindness, regardless of their background, beliefs, or artistic style.</p>
        </div>

        <div class="value-card">
          <div class="value-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
              <circle cx="9" cy="7" r="4"></circle>
              <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
            </svg>
          </div>
          <h3>Inclusivity</h3>
          <p>Welcome artists and supporters from all walks of life. Diversity strengthens our community and enriches our collective creativity.</p>
        </div>

        <div class="value-card">
          <div class="value-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"></path>
            </svg>
          </div>
          <h3>Authenticity</h3>
          <p>Share genuine artistic expression and honest feedback. Authentic connections create meaningful collaborations.</p>
        </div>

        <div class="value-card">
          <div class="value-icon">
            <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
              <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
          </div>
          <h3>Growth</h3>
          <p>Support each other's artistic journey. Constructive feedback and encouragement help everyone improve and flourish.</p>
        </div>
      </div>
    </section>

    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 300 }}>
      <h2>Content Guidelines</h2>
      
      <h3>✅ Encouraged Content</h3>
      <ul class="encouraged-list">
        <li>Original artistic works (poetry, visual art, music, multimedia)</li>
        <li>Collaborative pieces that bring people together</li>
        <li>Content that promotes peace, understanding, and positive change</li>
        <li>Constructive feedback and supportive comments</li>
        <li>Educational content about art, social causes, and community building</li>
      </ul>

      <h3>❌ Prohibited Content</h3>
      <ul class="prohibited-list">
        <li>Hate speech, discrimination, or harassment of any kind</li>
        <li>Content that promotes violence, harm, or illegal activities</li>
        <li>Spam, misleading information, or fraudulent content</li>
        <li>Copyright infringement or plagiarism</li>
        <li>Explicit sexual content or inappropriate material</li>
        <li>Personal attacks or bullying behavior</li>
      </ul>
    </section>

    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 400 }}>
      <h2>Collaboration Guidelines</h2>
      <p>Peace Piece thrives on collaboration. When working with others:</p>
      <ul>
        <li><strong>Communicate clearly:</strong> Set expectations and boundaries from the start</li>
        <li><strong>Give credit:</strong> Always acknowledge contributors and their roles</li>
        <li><strong>Respect ownership:</strong> Discuss and agree on intellectual property rights</li>
        <li><strong>Be reliable:</strong> Follow through on commitments and communicate if plans change</li>
        <li><strong>Stay open:</strong> Be receptive to different perspectives and creative approaches</li>
      </ul>
    </section>

    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 500 }}>
      <h2>Reporting and Moderation</h2>
      
      <h3>How to Report</h3>
      <p>If you encounter content or behavior that violates our community policies:</p>
      <ul>
        <li>Contact us immediately at <a href="mailto:community@peacepiece.org">community@peacepiece.org</a></li>
        <li>Include specific details about the violation</li>
        <li>Provide links or screenshots when possible</li>
      </ul>

      <h3>Our Response</h3>
      <p>We take all reports seriously and will:</p>
      <ul>
        <li>Review reports within 24 hours</li>
        <li>Investigate thoroughly and fairly</li>
        <li>Take appropriate action based on our policies</li>
        <li>Follow up with the reporter when possible</li>
      </ul>

      <h3>Consequences</h3>
      <p>Violations may result in:</p>
      <ul>
        <li>Content removal</li>
        <li>Warning or temporary suspension</li>
        <li>Permanent account termination for severe or repeated violations</li>
      </ul>
    </section>

    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 600 }}>
      <h2>Intellectual Property</h2>
      <p>We respect intellectual property rights and expect our community to do the same:</p>
      <ul>
        <li><strong>Original work:</strong> Only share content you have created or have permission to use</li>
        <li><strong>Attribution:</strong> Give proper credit when using others' work with permission</li>
        <li><strong>Fair use:</strong> Understand and respect fair use guidelines</li>
        <li><strong>DMCA compliance:</strong> We respond to valid copyright claims promptly</li>
      </ul>
    </section>

    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 700 }}>
      <h2>Privacy and Safety</h2>
      <p>Protecting our community's privacy and safety is paramount:</p>
      <ul>
        <li><strong>Personal information:</strong> Don't share others' private information without consent</li>
        <li><strong>Safe interactions:</strong> Keep conversations respectful and appropriate</li>
        <li><strong>Report concerns:</strong> Alert us to any safety issues immediately</li>
        <li><strong>Block and report:</strong> Use platform tools to manage unwanted interactions</li>
      </ul>
    </section>

    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 800 }}>
      <h2>Appeals Process</h2>
      <p>If you believe a moderation decision was made in error:</p>
      <ol>
        <li>Email us at <a href="mailto:appeals@peacepiece.org">appeals@peacepiece.org</a> within 30 days</li>
        <li>Include your account information and details about the decision</li>
        <li>Explain why you believe the decision was incorrect</li>
        <li>We'll review your appeal and respond within 7 business days</li>
      </ol>
    </section>

    <section class="policy-section" in:fly={{ y: 20, duration: 300, delay: 900 }}>
      <h2>Policy Updates</h2>
      <p>These community policies may be updated to reflect changes in our platform, legal requirements, or community needs. We will:</p>
      <ul>
        <li>Notify the community of significant changes</li>
        <li>Provide a reasonable transition period when possible</li>
        <li>Consider community feedback on proposed changes</li>
        <li>Maintain transparency about our moderation practices</li>
      </ul>
    </section>

    <section class="policy-section contact-section" in:fly={{ y: 20, duration: 300, delay: 1000 }}>
      <h2>Get Involved</h2>
      <p>Help us build a better community:</p>
      <div class="contact-grid">
        <div class="contact-card">
          <h3>Community Feedback</h3>
          <p>Share suggestions for improving our policies</p>
          <a href="mailto:feedback@peacepiece.org">feedback@peacepiece.org</a>
        </div>
        <div class="contact-card">
          <h3>Volunteer Moderation</h3>
          <p>Help us maintain a positive environment</p>
          <a href="mailto:volunteer@peacepiece.org">volunteer@peacepiece.org</a>
        </div>
        <div class="contact-card">
          <h3>Community Events</h3>
          <p>Organize or participate in community activities</p>
          <a href="mailto:events@peacepiece.org">events@peacepiece.org</a>
        </div>
      </div>
    </section>
  </div>
</div>

<style>
  .community-container {
    padding: var(--space-6);
    max-width: 900px;
    margin: 0 auto;
  }

  .community-header {
    text-align: center;
    margin-bottom: var(--space-8);
  }

  .community-header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: var(--space-2);
    color: var(--text-color);
  }

  .community-header p {
    color: var(--text-muted);
    font-size: 1.125rem;
  }

  .community-content {
    display: flex;
    flex-direction: column;
    gap: var(--space-6);
  }

  .policy-section {
    background: var(--card-bg);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
  }

  .policy-section h2 {
    margin-bottom: var(--space-4);
    color: var(--text-color);
  }

  .policy-section h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: var(--space-4) 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .policy-section h3:first-of-type {
    margin-top: var(--space-3);
  }

  .policy-section p {
    color: var(--text-color);
    line-height: 1.6;
    margin-bottom: var(--space-3);
  }

  .policy-section p:last-child {
    margin-bottom: 0;
  }

  .policy-section ul, .policy-section ol {
    margin: var(--space-3) 0;
    padding-left: var(--space-4);
  }

  .policy-section li {
    color: var(--text-color);
    line-height: 1.6;
    margin-bottom: var(--space-2);
  }

  .policy-section li:last-child {
    margin-bottom: 0;
  }

  .values-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(250px, 1fr));
    gap: var(--space-4);
    margin-top: var(--space-4);
  }

  .value-card {
    background-color: var(--bg-color);
    border-radius: var(--radius-lg);
    padding: var(--space-4);
    text-align: center;
  }

  .value-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 48px;
    height: 48px;
    background-color: var(--color-primary-100);
    color: var(--color-primary-600);
    border-radius: var(--radius-lg);
    margin: 0 auto var(--space-3) auto;
  }

  .value-card h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .value-card p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0;
  }

  .encouraged-list li {
    color: var(--color-success-600);
  }

  .prohibited-list li {
    color: var(--color-error-600);
  }

  .contact-section {
    background: var(--card-bg);
  }

  .contact-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: var(--space-4);
    margin-top: var(--space-4);
  }

  .contact-card {
    background: var(--card-bg);
    border-radius: var(--radius-lg);
    padding: var(--space-4);
    text-align: center;
    border: 1px solid var(--border-color);
  }

  .contact-card h3 {
    font-size: 1.125rem;
    font-weight: 500;
    margin: 0 0 var(--space-2) 0;
    color: var(--text-color);
  }

  .contact-card p {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin: 0 0 var(--space-3) 0;
  }

  .contact-card a, .policy-section a {
    color: var(--text-color);
    text-decoration: underline;
    text-underline-offset: 5px;
    font-weight: 500;
  }

  .contact-card a:hover, .policy-section a:hover {
    text-decoration: underline;
  }

  @media (max-width: 768px) {
    .community-container {
      padding: var(--space-4);
    }

    .community-header h1 {
      font-size: 2rem;
    }

    .policy-section {
      padding: var(--space-4);
    }

    .values-grid, .contact-grid {
      grid-template-columns: 1fr;
    }
  }
</style>