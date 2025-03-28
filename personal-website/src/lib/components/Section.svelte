<script lang="ts">
  import { Section, BLANK } from '../../../../personal-reusables/dist';

  export let url: TSection['url'] = '';
  export let title: TSection['title'];
  export let texts: TSection['texts'];
</script>

<Section {url} {title} urlTarget={BLANK}>
  {#snippet body()}
    {#each texts as paragraph (paragraph)}
      <p>
        {@html paragraph}
      </p>
    {/each}
  {/snippet}
</Section>
