<script lang="ts">
	import type { Snippet } from 'svelte';
	import { BLANK } from '../../utils.js';
	import { theme } from '../../stores/theme_store.js';

	interface Props {
		url?: string;
		urlTarget?: string;
		title: string;
		body?: Snippet;
	}

	let { url = '', urlTarget = BLANK, title, body }: Props = $props();
</script>

<div class="section {$theme}">
	<h3>
		{#if url}
			<a href={url} target={urlTarget} data-sveltekit-prefetch>
				<div>{title}</div>
			</a>
		{:else}
			<div>{title}</div>
		{/if}
	</h3>
	{@render body?.()}
</div>

<style scoped lang="css">
	.section {
		padding: 20px 0;
		margin: 10px 0;
		padding: 10px 5px;
		padding-left: 15px;
		opacity: 1;
	}

	.section h3 {
		/* fit-content, not max-content: hug the title so the underline stops at
		   the text, but clamp to the available width so long titles wrap
		   instead of running off the screen. */
		width: fit-content;
		max-width: 100%;
		overflow-wrap: break-word;
	}

	.section h3 div {
		padding: 5px;
		margin-bottom: 10px;
		border-bottom: 1px solid var(--text-color);
	}

	.dark-theme h3 div {
		border-bottom: 1px solid var(--text-color);
	}

	.section h3 div:hover {
		border-color: var(--main-red);
	}

	.section div {
		padding-left: 5px;
	}
</style>
