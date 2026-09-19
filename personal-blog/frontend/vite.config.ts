import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	// todo try to remove
	server: {
		fs: {
			allow: ['../../']
		}
	}
});
