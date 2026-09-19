<script lang="ts">
  import type { Snippet } from 'svelte';
  import { AppShell, BLANK, Nav } from 'personal-reusables';
  import Header from '$lib/components/Header.svelte';
  import favicon from '$lib/assets/favicon.ico';

  let { children }: { children?: Snippet } = $props();
</script>

<AppShell>
  {#snippet nav()}
    <Nav
      links={[
        { href: '/', label: 'About' },
        { href: '/projects', label: 'Projects' },
        { href: '/ilpc', label: 'ILPC' },
      ]}
      menu={[
        { href: 'https://terra-incognita.blog', label: 'Blog', target: BLANK, divider: true },
        { href: '/Marijan-Smetko-CV.pdf', label: 'My CV', target: BLANK, divider: true },
      ]}
    />
  {/snippet}
  <Header />
  {@render children?.()}
</AppShell>

<svelte:head>
  <link rel="icon" type="image/x-icon" href={favicon} />
  <link rel="manifest" href="/manifest.webmanifest" />
</svelte:head>
