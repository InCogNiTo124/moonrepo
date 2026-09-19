<script lang="ts" module>
  /** A titled block of HTML paragraphs. */
  export type TSection = {
    title: string;
    texts: string[];
    url?: string;
    urlTarget?: string;
  };
</script>

<script lang="ts">
  import Section from './Section.svelte';

  let { url, urlTarget, title, texts }: TSection = $props();
</script>

<Section {url} {urlTarget} {title}>
  {#snippet body()}
    {#each texts as paragraph (paragraph)}
      <p>
        {@html paragraph}
      </p>
    {/each}
  {/snippet}
</Section>
