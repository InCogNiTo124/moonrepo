<script lang="ts">
  import { browser } from '$app/environment';
  import { page } from '$app/stores';
  import { Theme } from 'personal-reusables';

  let segment = $state('');

  if (browser) {
    page.subscribe((newval) => {
      segment = newval.url.pathname;
    });
  }
</script>

<div id="top">
  <div id="nav">
    <Theme />
    <hr />
    <a class={`button ${segment === '/' ? 'router-link-active' : ''}`} href="/"
      >Most recent posts</a
    >
    <hr />
    <!-- <a class={`button ${segment === "projects" ? "router-link-active" : ""}`} href="/projects">Projects</a>
    <a class={`button ${segment === "ilpc" ? "router-link-active" : ""}`} href="/ilpc">ILPC</a> -->
  </div>
</div>

<style scoped>
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
  }

  #nav {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    position: sticky;
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
  }
</style>
