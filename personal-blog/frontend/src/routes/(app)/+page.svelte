<script lang="ts">
  import PostListViewGroup from '$lib/components/PostViews/PostListViewGroup.svelte';
  interface Props {
    data: {
    posts: Post[];
    page: number;
    noPosts: boolean;
    lastPage: boolean;
  };
  }

  let { data }: Props = $props();
</script>

<PostListViewGroup {...data} />
