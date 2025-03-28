import { sveltekit } from '@sveltejs/kit/vite';

/** @type {import('vite').UserConfig} */
const config = {
  plugins: [sveltekit()],
  server: {
    port: 3000,
    fs: {
      allow: [
        './src',
        './static',
        './node_modules',
        './.svelte-kit',
      ],
    },
  },
};

export default config;
