# Personal Blog Frontend

This is the frontend application for "Terra Incognita", my personal blog. It is
a [SvelteKit](https://svelte.dev/docs/kit/introduction) project designed to run
with the Bun runtime.

## Architecture

The project is structured as a dynamic SvelteKit application using
`svelte-adapter-bun`.

- **Framework**: SvelteKit (Svelte 5)
- **Runtime**: Bun
- **Dependencies**:
  - `personal-reusables`: Shared logic and components, managed via the moon
    workspace.
  - `js-cookie`: For client-side cookie handling.
- **Output**: Generates a Bun-compatible server build in `build/`.

## Prerequisites

- [Bun](https://bun.sh) (Runtime & Package Manager)
- [moon](https://moonrepo.dev) (Task Runner)

## Running Locally

1.  **Install dependencies**:

    ```bash
    bun install
    ```

    Note: This project relies on the workspace dependency `personal-reusables`.

2.  **Start the development server**:

    Use the moon task:

    ```bash
    moon run personal-blog-frontend:dev
    ```

    Or directly with bun:

    ```bash
    bun run dev
    ```

    The application will run at `http://localhost:5173`.

## Building

To create the production build:

```bash
moon run personal-blog-frontend:build
```

This task ensures that `personal-reusables:build` is executed first. The output
is a standalone Bun server located in the `build/` directory.

To run the built server:

```bash
bun run build/index.js
```

## Staging (Docker)

To build and serve the application as a local Docker image (mimicking
production):

```bash
moon run personal-blog-frontend:staging
```
