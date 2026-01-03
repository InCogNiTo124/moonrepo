# Personal Reusables

This is a shared [Svelte](https://svelte.dev/) library containing reusable
components, stores, assets, and utility functions used across the `moonrepo`
workspace projects (for now `personal-website` and `personal-blog-frontend`).

## Architecture

This project is a SvelteKit library packaged using
[`@sveltejs/package`](https://kit.svelte.dev/docs/packaging).

- **Components**: Located in `src/lib/components/`. Includes structural elements
  like `Section`, `SectionGroup`, and UI controls like `Theme`, `Loader`,
  `Tags`, and `Pager`.
- **Stores**: Shared state, such as `theme_store` for managing light/dark mode.
- **Assets**: Shared static assets like favicons and theme icons.
- **Styles**: Global CSS variables and styles in `src/lib/assets/_styles.css`.
- **Preview App**: The `src/routes/` directory contains a test application to
  preview components during development.

## Prerequisites

- [Bun](https://bun.sh) (Runtime & Package Manager)
- [moon](https://moonrepo.dev) (Task Runner)

## Usage in Other Projects

This library is essentially a local npm package. Other projects in the workspace
reference it via file dependency or path aliases.

Projects import components directly:

```svelte
<script>
  import { Section, Theme, theme } from 'personal-reusables';
</script>
```

And ensuring the styles are loaded (often via the layout):

```javascript
import "personal-reusables/dist/style.css"; // Path may vary depending on packaging
```

_(Note: Refer to `src/lib/index.ts` for strictly exported members)_

## Building

To package the library for consumption by other applications:

```bash
moon run personal-reusables:build
```

This will run `svelte-package` and output the generated type definitions and
JavaScript files to the `dist/` directory.
