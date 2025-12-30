<script lang="ts">
  import { fade } from "svelte/transition";
  import { cubicInOut as cubic } from "svelte/easing";

  import Loader from "../Loader.svelte";
  import Pager from "../Filters/Pager.svelte";

  interface Props {
    sections?: Array<any>;
    noSections?: boolean;
    lastPage?: boolean;
    page?: number;
    Section: any;
    emptyList?: import('svelte').Snippet;
  }

  let { 
    sections = [], 
    noSections = true, 
    lastPage = false, 
    page = 1, 
    Section,
    emptyList 
  }: Props = $props();
</script>

<div>
  {#each sections as { id, ...section }, i (id)}
    <div in:fade={{ easing: cubic, duration: 700, delay: i * 75 }}>
      <Section {...section} />
    </div>
  {:else}
    {#if noSections}
      <div class="empty-message">
        {#if emptyList}
          {@render emptyList()}
        {:else}
          No sections to display!
        {/if}
      </div>
    {:else}
      <Loader />
    {/if}
  {/each}

  {#if page}
    <Pager {page} showNext={!lastPage} />
  {/if}
</div>

<style>
  .empty-message {
    padding-left: 1rem;
    padding-top: 2rem;
  }
</style>
