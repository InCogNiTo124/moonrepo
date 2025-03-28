<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import Cookies from 'js-cookie';

  import { LIGHT, COOKIE_KEY_THEME, theme } from 'personal-reusables';

  import Header from '$lib/components/Header.svelte';
  interface Props {
    children?: import('svelte').Snippet;
  }

  let { children }: Props = $props();

  onMount(() => {
    if (browser) {
      theme.useCookie();
      theme.subscribe((newval) => {
        document.getElementById('body').setAttribute('class', newval);
      });
      document
        .getElementById('body')
        .setAttribute('class', Cookies.get(COOKIE_KEY_THEME) || LIGHT);
    }
  });

  const children_render = $derived(children);
</script>

<Header />
<div id="app">
  <div id="content">
    <div id="main">
      {@render children_render?.()}
    </div>
  </div>
</div>
