import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import wasm from "vite-plugin-wasm";
import topLevelAwait from "vite-plugin-top-level-await";


const config = {
	preprocess: vitePreprocess(),
	kit: { adapter: adapter() },
	plugins: [
		wasm(),
	topLevelAwait()],
};

export default config;
