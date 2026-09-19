import adapter from 'svelte-adapter-bun';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import path from 'path';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://svelte.dev/docs/kit/integrations
	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		adapter: adapter(),
		// personal-reusables is a source-only library: compile it straight from
		// src/lib. kit.alias reaches both Vite (build) and TypeScript
		// (svelte-check).
		alias: {
			'personal-reusables': path.resolve('../../personal-reusables/src/lib/index.ts')
		},
		typescript: {
			// The lib's sources would otherwise type-check against the svelte in
			// personal-reusables/node_modules, and its Snippet/Component types
			// are unrelated to ours as soon as the two lockfiles drift apart.
			// Types only: at runtime vite-plugin-svelte already dedupes svelte.
			config(tsconfig) {
				tsconfig.compilerOptions.paths ??= {};
				tsconfig.compilerOptions.paths['svelte'] = ['../node_modules/svelte'];
				tsconfig.compilerOptions.paths['svelte/*'] = ['../node_modules/svelte/*'];
			}
		}
	}
};

export default config;
