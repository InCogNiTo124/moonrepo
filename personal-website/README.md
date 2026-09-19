# Personal Website

This is the source code for my personal website. It is a
[SvelteKit](https://svelte.dev/docs/kit/introduction) project configured as a
static site.

## Architecture

The project is structured as a static SvelteKit application using
`@sveltejs/adapter-static`.

- **Pages**:
  - `/`: Home page
  - `/ilpc`: ILPC related content
  - `/projects`: Portfolio/Projects listing
- **Shared UI**: the shell, nav, sections, theme and global styles come from
  `personal-reusables`, compiled from source (see its README).
- **Site-only**: `src/lib/components/` (Header), `src/lib/assets/` (photo and
  favicons) and `src/lib/constants.ts` (personal links).

## Prerequisites

- [Bun](https://bun.sh) (Runtime & Package Manager)
- [moon](https://moonrepo.dev) (Task Runner)

## Running Locally

1.  **Install dependencies**:

    ```bash
    bun install
    ```

2.  **Start the development server**: You can use the moon task:

    ```bash
    moon run personal-website:dev
    ```

    Or directly with bun:

    ```bash
    bun run dev
    ```

    The site will run at `http://localhost:5173`.

## Building

To build the static site (output to `build/`):

```bash
moon run personal-website:build
```

This task type-checks `personal-reusables` first.

## Staging (Docker)

To build and serve the application as a local Docker image:

```bash
moon run personal-website:staging
```
