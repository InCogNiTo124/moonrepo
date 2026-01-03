import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
	plugins: [sveltekit()],
	resolve: {
		alias: {
			'personal-reusables': path.resolve(__dirname, '../../personal-reusables/src/lib/index.ts')
		}
	},
	// todo try to remove
	server: {
		fs: {
			allow: ['../../']
		}
	}
});
