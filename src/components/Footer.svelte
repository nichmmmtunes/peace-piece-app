<script lang="ts">
  import { link } from 'svelte-spa-router';
  // Footer component for legal statement
</script>

<footer class="footer">
  <div class="footer-content">
    <div class="footer-links">
      <a href="/terms" use:link>Terms of Use</a>
      <a href="/privacy" use:link>Privacy Policy</a>
      <a href="/payment-policy" use:link>Payment Policy</a>
      <a href="/community" use:link>Community Guidelines</a>
    </div>
    <p class="copyright">
      Copyright &copy; 2025 Peace Piece. All&nbsp;Rights&nbsp;Reserved.
    </p>
  </div>
</footer>

<style>
  .footer {
    background: var(--bg-color);
    border-top: 1px solid var(--border-color);
    padding: 12.2px 0;
    margin-top: auto;
  }

  :global(.light-mode) .footer {
    background: transparent;
    width: 100%;
  } 

  .footer-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 var(--space-4);
    text-align: center;
  }

  .footer-links {
    display: flex;
    justify-content: center;
    gap: var(--space-4);
    margin-bottom: var(--space-3);
    flex-wrap: wrap;
  }

  .footer-links a {
    color: var(--text-muted);
    text-decoration: none;
    font-size: 0.875rem;
    transition: color 0.2s;
  }

  .footer-links a:hover {
    color: var(--text-color);
    text-decoration: underline;
  }

  .copyright {
    color: var(--text-muted);
    font-size: 0.875rem;
    margin: 0;
    line-height: 1.4;
  }

  @media (max-width: 768px) {
    .footer {
      padding: var(--space-3) 0;
    }

    .footer-content {
      padding: 0 var(--space-3);
    }

    .footer-links {
      gap: var(--space-3);
      flex-direction: column;
    }

    .footer-links a {
      font-size: 0.8rem;
    }

    .copyright {
      font-size: 0.8rem;
    }
  }
</style>