import adapter from '@sveltejs/adapter-bun';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import path from 'path';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [
		sveltekit({
			// Consult https://svelte.dev/docs/kit/integrations
			// for more information about preprocessors
			preprocess: vitePreprocess(),
			adapter: adapter(),
			// personal-reusables is a source-only library: compile it straight from
			// src/lib. The plugin `alias` option reaches both Vite (build) and TypeScript
			// (svelte-check).
			alias: {
				'personal-reusables': path.resolve('../../personal-reusables/src/lib/index.ts')
			},
		})
	],
	// todo try to remove
	server: {
		fs: {
			allow: ['../../']
		}
	}
});
