import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import path from 'path';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  // Consult https://svelte.dev/docs/kit/integrations
  // for more information about preprocessors
  preprocess: vitePreprocess(),

  kit: {
    adapter: adapter(),
    // Resolve personal-reusables directly from source, bypassing node_modules.
    // Bun's file: protocol creates per-file symlinks at install time, so the
    // dist/ directory never appears in node_modules/personal-reusables/ if it
    // didn't exist during `bun install` (which runs before personal-reusables:build).
    // kit.alias syncs to both Vite (build) and TypeScript (svelte-check).
    alias: {
      'personal-reusables': path.resolve('../personal-reusables/src/lib/index.ts')
    }
  }
};

export default config;
