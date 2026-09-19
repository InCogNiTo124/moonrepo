<script lang="ts">
  import { Section, SELF } from 'personal-reusables';
  import Tags from '$lib/components/Tags.svelte';

  interface Props {
    post: Post;
  }

  let { post }: Props = $props();
</script>

<Section url={`/posts/${post.slug}`} urlTarget={SELF} title={post.title}>
  {#snippet body()}
    <div>
      <p class="subtitle">
        {@html post.subtitle}
      </p>
      <p class="date">
        {post.date}
      </p>
      <Tags tags={post.tags} />
    </div>
  {/snippet}
</Section>

<style scoped lang="css">
  .date {
    font-style: oblique;
    font-size: 0.875rem;

    padding-bottom: 0.375rem;
  }

  .subtitle {
    padding-bottom: 0.75rem;
  }
</style>
