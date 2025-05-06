<script lang="ts">
  import Canvas from "$lib/Canvas.svelte";
  let canvasComponent: Canvas | null = null;
</script>

<div
  style="width: 100%; height: 100%; border: 1px dashed blue; margin-bottom: 10px; overflow: hidden;"
>
  <Canvas bind:this={canvasComponent} style="border:1px solid #000; width: 100%; height: 100%; display: block; cursor: default;"   />
</div>

<style>
  /* Ensure containing elements can provide height */
  :global(html, body, #svelte) {
    height: 100%;
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  :global(#svelte) {
    display: flex;
    flex-direction: column;
  }
</style>
