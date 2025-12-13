<script>
	import { onMount } from 'svelte';
	import { BROWSER as browser } from 'esm-env';
	import Cookies from 'js-cookie';

	import { LIGHT, DARK, COOKIE_KEY_THEME, dark, light, theme } from 'personal-reusables';

	let val = $state(LIGHT);
	onMount(() => {
		val = Cookies.get(COOKIE_KEY_THEME) || LIGHT;
	});

	function toggleTheme() {
		if (browser) {
			val = val === LIGHT ? DARK : LIGHT;
			theme.set(val);
		}
	}
</script>

<button onclick={toggleTheme} type="button" class="theme-toggle">
	<img src={val === LIGHT ? dark : light} alt="Toggle theme" />
</button>

<style scoped>
	.theme-toggle {
		background: none;
		border: none;
		padding: 0;
		cursor: pointer;
	}
	img {
		height: 2rem;
	}
</style>
