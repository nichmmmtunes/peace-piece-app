<script>

</script>

<a class="bolt-badge" href="https://bolt.new" target="_blank">
</a>

<style>
    .bolt-badge {
        position: fixed;
        bottom: 2vw;
        right: 2vw;
        width: 6vw;
        height: 6vw;
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
    }

    :global(.dark-mode) .bolt-badge {
        background: url('/bolt-white_circle_360x360.png');
        background-size: contain;
        background-repeat: no-repeat;
    }
</style>