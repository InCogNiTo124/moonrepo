<script lang="ts">
  let height = $state(0);

  // The nav sticks directly below this header. Publish the measured height
  // instead of hardcoding an offset -- the title wraps on narrow screens and
  // the font-size changes at 650px.
  $effect(() => {
    document.documentElement.style.setProperty('--blog-header-height', `${height}px`);
  });
</script>

<div bind:clientHeight={height}>
  <a href="/">msmetko's blog</a>
  <p class="subtitle">A healthy dose of Dunning-Kruger</p>
</div>

<style scoped lang="css">
  div {
    position: sticky;
    top: 0;
    z-index: 5;
    background: var(--background-color);
    
    padding: 1rem;
    border-bottom: 1px solid var(--main-red);

    font-size: 2.5rem;
    font-weight: 600;
    text-align: center;
  }

  .subtitle {
    font-size: 1rem;
    font-weight: 400;
    margin: 0;
    margin-top: 0.25rem;
    font-style: italic;
    opacity: 0.8;
  }

  @media screen and (min-width: 650px) {
    div {
      font-size: 3rem;
    }
  }
</style>
