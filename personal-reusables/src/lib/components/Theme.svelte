<script>
	import { onMount } from 'svelte';
	import { browser } from '$app/environment';
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

<img onclick={toggleTheme} src={val === LIGHT ? dark : light} alt="Toggle theme" />

<style scoped>
	img {
		cursor: pointer;
		height: 2rem;
	}
</style>
