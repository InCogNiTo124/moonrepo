<script lang="ts">
  import { onMount } from "svelte";
  import { browser } from "$app/environment";
  import Cookies from "js-cookie";
  import { LIGHT, COOKIE_KEY_THEME } from "personal-reusables";
  import { theme } from "personal-reusables";
  import Nav from "$lib/components/Nav.svelte";
  import Header from "$lib/components/Header.svelte";
  import { favicon } from "personal-reusables";

  onMount(() => {
    if (browser) {
      theme.useCookie();
      theme.subscribe((newval) => {
        document.getElementById("body")?.setAttribute("class", newval);
      });
      document
        .getElementById("body")
        ?.setAttribute("class", Cookies.get(COOKIE_KEY_THEME) || LIGHT);
    }
  });
</script>

<div id="app">
  <Nav />
  <div id="content">
    <div id="main">
      <Header />
      <slot />
    </div>
  </div>
</div>

<svelte:head>
  <link rel="icon" type="image/x-icon" href={favicon} />
  <link rel="manifest" href="/manifest.webmanifest" />
</svelte:head>
