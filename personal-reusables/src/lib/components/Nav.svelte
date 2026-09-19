<script lang="ts" module>
  import type { Snippet } from 'svelte';

  export type NavLink = {
    href: string;
    /** Text of the link; alternatively pass `icon`. */
    label?: string;
    icon?: Snippet;
    title?: string;
    target?: string;
    /** Draw a separator above this link. */
    divider?: boolean;
  };
</script>

<script lang="ts">
  import { page } from '$app/state';
  import Theme from './Theme.svelte';

  interface Props {
    links: NavLink[];
    /** Links that fold behind a hamburger below 650px. */
    menu?: NavLink[];
    /** Sticky offset, for sites with a sticky header above the nav. */
    stickyTop?: string;
  }

  let { links, menu = [], stickyTop = '0px' }: Props = $props();

  let menuOpen = $state(false);
  let menuRoot: HTMLDivElement | undefined = $state();

  function closeMenu() {
    menuOpen = false;
  }

  function onPointerDown(event: PointerEvent) {
    if (menuOpen && menuRoot && !menuRoot.contains(event.target as Node)) {
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

{#snippet navLink(link: NavLink, onclick?: () => void)}
  {#if link.divider}
    <hr />
  {/if}
  <a
    class="button"
    class:router-link-active={!link.target && page.url.pathname === link.href}
    href={link.href}
    target={link.target}
    title={link.title}
    {onclick}
  >
    {#if link.icon}
      {@render link.icon()}
    {:else}
      {link.label}
    {/if}
  </a>
{/snippet}

<div id="top" style:top={stickyTop}>
  <div id="nav">
    <Theme />
    <hr />
    {#each links as link (link.href)}
      {@render navLink(link)}
    {/each}
  </div>

  {#if menu.length}
    <div id="extra" bind:this={menuRoot}>
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
        {#each menu as link (link.href)}
          {@render navLink(link, closeMenu)}
        {/each}
      </div>
    </div>
  {/if}
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
    padding: 20px;
    border-bottom: 1px solid var(--main-red);
    background-color: var(--background-color);
    /* below a site's own sticky header (z-index 5), if it has one */
    z-index: 4;
  }

  #nav {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    position: sticky;
  }

  /* Below 650px the menu links live behind the hamburger, so the header
     stays readable on narrow screens. */
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
      /* content-height, not stretched: a full-height sidebar can never stick */
      align-self: flex-start;
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
