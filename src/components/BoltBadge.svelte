<script>

</script>

<a class="bolt-badge" href="https://bolt.new" target="_blank">
</a>

<style>
    .bolt-badge {
        position: fixed;
        bottom: clamp(15px, 6vw, 20px);
        right: clamp(12px, 6vw, 18px);
        width: max(6vw, 60px);
        height: max(6vw, 60px);
        z-index: 2000;
        transition: opacity .3s ease;
        opacity: 1;
    }

    .bolt-badge:hover {
        opacity: .6;
    }

    :global(.light-mode) .bolt-badge {
        background: url('/bolt-black_circle_360x360.png');
        background-size: contain;
        background-repeat: no-repeat;
        border: solid 2px var(--bg-color);
        border-radius: 100px;
    }

    :global(.dark-mode) .bolt-badge {
        background: url('/bolt-white_circle_360x360.png');
        background-size: contain;
        background-repeat: no-repeat;
        border: solid 2px var(--bg-color);
        border-radius: 100px;
    }
</style>