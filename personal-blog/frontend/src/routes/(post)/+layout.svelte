<script lang="ts">
  import type { Snippet } from 'svelte';
  import { AppShell } from 'personal-reusables';
  import Header from '$lib/components/Header.svelte';

  let { children }: { children?: Snippet } = $props();
</script>

<Header />
<AppShell>
  {@render children?.()}
</AppShell>
