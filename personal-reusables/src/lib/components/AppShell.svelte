<script lang="ts">
  import type { Snippet } from 'svelte';
  import { theme } from '../stores/theme_store.js';

  interface Props {
    nav?: Snippet;
    children?: Snippet;
  }

  let { nav, children }: Props = $props();

  $effect(() => theme.init());
</script>

<div id="app">
  {@render nav?.()}
  <div id="content">
    <div id="main">
      {@render children?.()}
    </div>
  </div>
</div>
