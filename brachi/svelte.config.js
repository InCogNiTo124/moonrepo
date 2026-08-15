import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import path from 'path';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://svelte.dev/docs/kit/integrations	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		adapter: adapter(),
		// Resolve the wasm-pack output directly, bypassing node_modules - same
		// approach personal-website uses for personal-reusables.
		//
		// This used to be a "wasm": "file:../crates/brachistochrone_solver/pkg"
		// dependency in package.json, but moon installs JS dependencies for every
		// project as a toolchain action *before* any user task runs, so bun
		// install would look for pkg/ before brachistochrone-solver:build had
		// generated it. That's what the CI "stub wasm package" step existed for.
		// kit.alias matches both the exact value and subpaths, and syncs to both
		// Vite (build) and TypeScript (svelte-check).
		alias: {
			wasm: path.resolve('../crates/brachistochrone_solver/pkg')
		}
	},
};

export default config;
