import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/**
 * Not an app and not packaged: the sites compile src/lib directly through
 * their own `personal-reusables` alias. SvelteKit is only here so that
 * `svelte-kit sync` can generate the $app/* types svelte-check needs.
 *
 * @type {import('@sveltejs/kit').Config}
 */
const config = {
	preprocess: vitePreprocess()
};

export default config;
