<script lang="ts">
  import PostListViewGroup from '$lib/components/PostViews/PostListViewGroup.svelte';

  interface Props {
    data: {
    posts: Post[];
    tagName: string;
    noPosts: boolean;
    page: number;
    lastPage: boolean;
  };
  }

  let { data }: Props = $props();
</script>

<div class="tag-title">
  Filtered by tag: <span>{data.tagName}</span>
</div>

<PostListViewGroup {...data} />

<style scoped>
  div.tag-title {
    font-style: oblique;
    padding: 2rem 0 1rem 1rem;
  }

  .tag-title span {
    font-style: normal;
    font-weight: 600;
  }
</style>
