<script lang="ts">
  import type { Snippet } from 'svelte';
  import { AppShell, Nav } from 'personal-reusables';
  import Header from '$lib/components/Header.svelte';

  let { children }: { children?: Snippet } = $props();
</script>

{#snippet rss()}
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width="24"
    height="24"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
    class="feather feather-rss"
    ><path d="M4 11a9 9 0 0 1 9 9"></path><path d="M4 4a16 16 0 0 1 16 16"
    ></path><circle cx="5" cy="19" r="1"></circle></svg
  >
{/snippet}

<Header />
<AppShell>
  {#snippet nav()}
    <!-- pins below the sticky site title, whose height Header.svelte publishes -->
    <Nav
      stickyTop="var(--blog-header-height, 0px)"
      links={[
        { href: '/', label: 'Most recent posts' },
        { href: '/feed.rss', title: 'RSS Feed', icon: rss, divider: true },
      ]}
    />
  {/snippet}
  {@render children?.()}
</AppShell>
