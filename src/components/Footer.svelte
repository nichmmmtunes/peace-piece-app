<script lang="ts">
  // Footer component for legal statement
</script>

<footer class="footer">
  <div class="footer-content">
    <p class="copyright">
      Copyright © 2025 Go Arts Productions LLC - All Rights Reserved
    </p>
  </div>
</footer>

<style>
  .footer {
    background: var(--bg-color);
    border-top: 1px solid var(--border-color);
    padding: 28.8px 0;
    margin-top: auto;
  }

  .footer-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 var(--space-4);
    text-align: center;
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

    .copyright {
      font-size: 0.8rem;
    }
  }
</style>