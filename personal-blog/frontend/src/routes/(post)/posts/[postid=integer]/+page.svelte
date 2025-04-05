<script lang="ts">
  import PostFullView from '$lib/components/PostViews/PostFullView.svelte';

  interface Props {
    data: {
    post: Post;
  };
  }

  let { data }: Props = $props();
</script>

<PostFullView {...data} />
