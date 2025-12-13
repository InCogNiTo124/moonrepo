import { sveltekit } from '@sveltejs/kit/vite';
import {nodePolyfills} from 'vite-plugin-node-polyfills';
import path from 'path';

// import * from '@personal-reusables';

/** @type {import('vite').UserConfig} */
const config = {
  plugins: [sveltekit(), nodePolyfills({
    // this solves these errors:
    // "Readable" is not exported by "__vite-browser-external", imported by "node_modules/axios/lib/helpers/formDataToStream.js".
    // "TextEncoder" is not exported by "__vite-browser-external", imported by "node_modules/axios/lib/helpers/formDataToStream.js".
    // I suppose this can be rid of once in future
    include: ['path', 'http', 'https', 'zlib', 'stream', 'path', 'fs', 'os', 'tty', 'util'],
    globals: {
      global: false,
    },
  })],
  resolve: {
    alias: {
      // $slib: path.resolve('../personal-reusables/lib'),
      // $f: path.resolve('../personal-reusables/static/favicon'),
    },
  },
  server: {
    port: 3000,
    fs: {
      allow: [
        './src',
        './static',
        './submodule/lib',
        './node_modules',
        './.svelte-kit',
      ],
    },
  },
};

export default config;
