# Personal Reusables

The [Svelte](https://svelte.dev/) UI kit shared by `personal-website` and
`personal-blog-frontend`.

## What belongs here

Only what **both** sites use. Anything with a single consumer (a site's photo
and favicons, personal links, blog-only components like `Tags`) lives in that
site instead.

- **Shell**: `AppShell` (page skeleton + theme bootstrap) and `Nav` (sidebar
  with theme toggle, active-link highlighting, and optional hamburger `menu`).
- **Sections**: `Section`, `TextSection`, `SectionGroup`, plus `Loader` and
  `Pager`. The `TSection` type describes a `TextSection`.
- **Theme**: the `theme` store (`theme.init()`, `theme.toggle()`) and the
  `Theme` toggle button.
- **Styles**: global CSS, CSS variables and the Lato font faces, pulled in by
  importing anything from the package.
- **Constants**: `BLANK`, `SELF`, `TARGET_BLANK`, `INLINE_CLASS`.

`src/lib/index.ts` is the full public surface.

## How it is consumed

It is source-only: there is no build step and no `dist/`. Each site aliases
`personal-reusables` to `src/lib/index.ts` in its `svelte.config.js`
(`kit.alias`, which covers both Vite and svelte-check) and compiles the
sources itself, so `$app/*` imports work here as they would in the site.

```svelte
<script>
  import { AppShell, Nav, SectionGroup } from 'personal-reusables';
</script>
```

The sites also remap `svelte` types to their own install
(`kit.typescript.config`), so the lib is type-checked against the same svelte
the site compiles it with, even when the lockfiles drift.

## Tasks

```bash
moon run personal-reusables:check
```

The sites' `check` and `build` depend on this task and list `src/**` as
inputs, so a change here re-checks and rebuilds both of them.
