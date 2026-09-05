<script lang="ts">
  import { browser } from '$app/environment';
  import { page } from '$app/stores';
  import { BLANK, Theme } from 'personal-reusables';

  let segment = $state('');
  let menuOpen = $state(false);
  let menu: HTMLDivElement | undefined = $state();

  if (browser) {
    page.subscribe((newval) => {
      segment = newval.url.pathname.slice(1);
    });
  }

  function closeMenu() {
    menuOpen = false;
  }

  function onPointerDown(event: PointerEvent) {
    if (menuOpen && menu && !menu.contains(event.target as Node)) {
      closeMenu();
    }
  }

  function onKeyDown(event: KeyboardEvent) {
    if (event.key === 'Escape') {
      closeMenu();
    }
  }
</script>

<svelte:window onpointerdown={onPointerDown} onkeydown={onKeyDown} />

<div id="top">
  <div id="nav">
    <Theme />
    <hr />
    <a class={`button ${!segment ? 'router-link-active' : ''}`} href="."
      >About</a
    >
    <a
      class={`button ${segment === 'projects' ? 'router-link-active' : ''}`}
      href="/projects">Projects</a
    >
    <a
      class={`button ${segment === 'ilpc' ? 'router-link-active' : ''}`}
      href="/ilpc">ILPC</a
    >
  </div>

  <div id="extra" bind:this={menu}>
    <button
      id="hamburger"
      type="button"
      aria-label="Menu"
      aria-expanded={menuOpen}
      aria-controls="extra-links"
      onclick={() => (menuOpen = !menuOpen)}
    >
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <line x1="3" y1="6" x2="21" y2="6" />
        <line x1="3" y1="12" x2="21" y2="12" />
        <line x1="3" y1="18" x2="21" y2="18" />
      </svg>
    </button>

    <div id="extra-links" class:open={menuOpen}>
      <hr />
      <a
        class="button"
        href="https://terra-incognita.blog"
        target={BLANK}
        onclick={closeMenu}>Blog</a
      >
      <hr />
      <a
        class="button"
        href="Marijan-Smetko-CV.pdf"
        target={BLANK}
        onclick={closeMenu}>My CV</a
      >
    </div>
  </div>
</div>

<style scoped lang="css">
  a.router-link-active {
    color: var(--main-red);
  }

  #top {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    font-weight: bold;
    position: sticky;
    top: 0px;
    padding: 20px;
    border-bottom: 1px solid var(--main-red);
    background-color: var(--background-color);
    z-index: 5;
  }

  #nav {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    position: sticky;
  }

  /* Below 650px the Blog and CV links live behind the hamburger, so the
     header stays readable on narrow screens. */
  #extra {
    display: flex;
    align-items: center;
  }

  #hamburger {
    display: flex;
    align-items: center;
    padding: 5px 10px;
    background: none;
    border: none;
    color: inherit;
    cursor: pointer;
  }

  #hamburger svg {
    height: 1.5rem;
    width: 1.5rem;
    stroke: var(--text-color);
    stroke-width: 2;
    stroke-linecap: round;
    fill: none;
  }

  #hamburger:hover svg {
    stroke: var(--main-red);
  }

  #extra-links {
    display: none;
  }

  /* Anchored to #top, not #extra, so the panel spans the full header width.
     top is offset by 1px because an absolutely positioned child is placed
     against the padding box, which sits *inside* #top's border-bottom --
     at a flat 100% the panel would paint over that border. */
  #extra-links.open {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    position: absolute;
    top: calc(100% + 1px);
    left: 0;
    right: 0;
    padding: 10px 20px;
    background-color: var(--background-color);
    border-bottom: 1px solid var(--main-red);
    z-index: 10;
  }

  #extra-links hr {
    display: none;
  }

  @media screen and (min-width: 650px) {
    #top {
      height: 100%;
      padding-top: 100px;
      flex-direction: column;
      justify-content: start;
      border: none;
    }
    #nav {
      display: flex;
      flex-direction: column;
    }
    #hamburger {
      display: none;
    }
    #extra {
      display: contents;
    }
    #extra-links,
    #extra-links.open {
      display: flex;
      flex-direction: column;
      align-items: stretch;
      position: static;
      padding: 0;
      background: none;
      border: none;
    }
    #extra-links hr {
      display: block;
    }
  }
</style>
