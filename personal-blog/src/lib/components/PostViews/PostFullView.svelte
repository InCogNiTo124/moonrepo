<script lang="ts">
  import { INLINE_CLASS, Tags } from 'personal-reusables';
  import DisqusSnippet from './DisqusSnippet.svelte';

  interface Props {
    post: Post;
  }

  let { post = $bindable() }: Props = $props();
</script>

<div class="post">
  <a class={INLINE_CLASS} href="/" data-sveltekit-prefetch>Back to main page</a>

  <div class="post-title">
    <h1>{post.title}</h1>
    <p class="subtitle">{post.subtitle}</p>
    <div class="post-meta">
      <Tags tags={post.tags} />
      <p>{post.date}</p>
    </div>
  </div>

  <div
    class="post-content"
    bind:innerHTML={post.content}
    contenteditable="false"
  ></div>

  <br />
  <br />

  <DisqusSnippet />

  <br />
  <hr />

  <a class={INLINE_CLASS} href="/" data-sveltekit-prefetch>Back to main page</a>
</div>

<style scoped lang="css">
  .post-title {
    padding: 2rem 0;
    width: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .post-title .subtitle {
    color: var(--caption-grey);
    font-style: oblique;
  }

  .post-meta {
    width: 100%;
    display: flex;
    justify-content: space-between;

    font-size: 0.875rem;

    padding-top: 1.5rem;
  }

  .post-content :global(h2) {
    padding: 1.5rem 0;
  }
  .post-content :global(h3) {
    padding: 1rem 0;
  }
  .post-content :global(h4) {
    padding: 0.5rem 0;
  }

  .post-content :global(ul),
  .post-content :global(ol) {
    padding-left: 2rem;
  }

  .post-content :global(li) {
    padding: 0.5rem;
  }

  .post-content :global(.toc) {
    padding-bottom: 1rem;
    border-bottom: 1px solid var(--main-red);
    margin-bottom: 1rem;
  }

  .post-content :global(.toc li) {
    padding: 0.25rem;
  }

  .post-content :global(.footnote) {
    font-size: 0.875rem;
  }

  @media screen and (min-width: 650px) {
    .post-content :global(.footnote) {
      font-size: 1rem;
    }
  }

  :global(figure) {
    width: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;

    padding: 1.5rem 0;
  }

  :global(figure img) {
    width: 100%;
  }

  :global(figcaption) {
    font-size: 0.875rem;
    color: var(--caption-grey);
    padding-top: 0.5rem;
  }
</style>
