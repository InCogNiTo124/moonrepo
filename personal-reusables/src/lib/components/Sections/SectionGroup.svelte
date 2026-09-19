<script lang="ts" generics="T extends Record<string, any> = TSection">
  import type { Component, Snippet } from 'svelte';
  import { fade } from 'svelte/transition';
  import { cubicInOut as cubic } from 'svelte/easing';

  import Loader from '../Loader.svelte';
  import Pager from '../Filters/Pager.svelte';
  import TextSection, { type TSection } from './TextSection.svelte';

  interface Props {
    sections?: T[];
    /** Component each entry's fields are spread into. */
    Section?: Component<T>;
    /** Stable identity per entry; defaults to its index. */
    key?: (section: T, index: number) => unknown;
    /** Empty list is final (show emptyList) rather than still loading. */
    noSections?: boolean;
    lastPage?: boolean;
    page?: number;
    emptyList?: Snippet;
  }

  let {
    sections = [],
    Section = TextSection as unknown as Component<T>,
    key = (_, index) => index,
    noSections = false,
    lastPage = false,
    page,
    emptyList,
  }: Props = $props();
</script>

<div>
  {#each sections as section, i (key(section, i))}
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
