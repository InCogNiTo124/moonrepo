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
  sections={posts.map((post) => ({ post, id: post.id }))}
  noSections={noPosts}
  {lastPage}
  {page}
  Section={PostListView}
>
  <!-- @migration-task: migrate this slot by hand, `empty-list` is an invalid identifier -->
  <p slot="empty-list">No posts found!</p>
</SectionGroup>
