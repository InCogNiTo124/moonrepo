# Brachistochrone Visualizer

Interactive visualization tool for the Brachistochrone problem (the curve of
fastest descent), built with
[SvelteKit](https://svelte.dev/docs/kit/introduction) and Rust (WebAssembly).

## Architecture

The project follows a hybrid architecture combining a modern frontend framework
with high-performance systems programming logic:

- **Frontend**: SvelteKit application using `@sveltejs/adapter-static`.
- **Computation**: The core solver logic resides in a Rust crate located in
  `crates/brachistochrone_solver`. This is compiled to WebAssembly (WASM) using
  `wasm-pack` and consumed by the frontend.
- **Math**: Python scripts (`py/`) use `sympy` and `scipy` for symbolic
  derivation and formula verification.
- **Dependencies**: The project is part of the `moonrepo` workspace and depends
  on the `brachistochrone-solver` task.

## Prerequisites

- [Bun](https://bun.sh) (Runtime & Package Manager)
- [moon](https://moonrepo.dev) (Task Runner)
- **Rust** & **wasm-pack** (for compiling the solver)

## Running Locally

1.  **Install dependencies**:

    ```bash
    bun install
    ```

    Note: The project depends on the local `crates/brachistochrone_solver/pkg`.
    Moon handles the build order, but `bun install` requires the package
    directory to exist. If it's missing, run the solver build first:
    `moon run brachi:build`

2.  **Start the development server**:

    Use the moon task to ensure the WASM dependency is built and available:

    ```bash
    moon run brachi:dev
    ```

    Or directly with bun (if WASM is already built):

    ```bash
    bun run dev
    ```

    The application will act as a static site generator in development mode.

## Building

To create the production build:

```bash
moon run brachi:build
```

This task defines a dependency on `brachistochrone-solver:build`, ensuring the
latest WASM binary is compiled and copied into the package before the SvelteKit
build occurs. The output will be located in the `build/` directory.

## Staging (Docker)

To build and serve the application as a local Docker image:

```bash
moon run brachi:staging
```

## Python Environment (Optional)

If you wish to run the mathematical derivation scripts in `py/`:

```bash
cd py
uv sync
uv run main.py
```
