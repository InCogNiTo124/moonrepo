<script lang="ts">
	import { LIGHT } from '../utils.js';
	import { theme } from '../stores/theme_store.js';
	import dark from '../images/dark.png';
	import light from '../images/light.png';
</script>

<button onclick={theme.toggle} type="button" class="theme-toggle">
	<img src={$theme === LIGHT ? dark : light} alt="Toggle theme" />
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
