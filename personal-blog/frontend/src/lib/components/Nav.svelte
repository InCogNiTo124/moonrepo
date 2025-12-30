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
    <a class="button" href="/feed.rss" title="RSS Feed">
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
        ><path d="M4 11a9 9 0 0 1 9 9"></path><path
          d="M4 4a16 16 0 0 1 16 16"
        ></path><circle cx="5" cy="19" r="1"></circle></svg
      >
    </a>
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
