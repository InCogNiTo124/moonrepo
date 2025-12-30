<script lang="ts">
  import PostListView from '$lib/components/PostViews/PostListView.svelte';
  import { SectionGroup } from 'personal-reusables';

  interface Props {
    posts?: Post[];
    noPosts: boolean;
    lastPage: boolean;
    page?: number;
  }

  let { posts = [], noPosts, lastPage, page = 1 }: Props = $props();
</script>

<SectionGroup
  sections={posts.map((post) => ({ post, id: post.slug }))}
  noSections={noPosts}
  {lastPage}
  {page}
  Section={PostListView}
>
  {#snippet emptyList()}
    <p>No posts found!</p>
  {/snippet}
</SectionGroup>
