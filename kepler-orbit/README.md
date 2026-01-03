# Kepler Orbit

Keplerian orbit visualization using Three.js.

## Architecture

The project is a standard Vite application configured for TypeScript.

- **Rendering**: [Three.js](https://threejs.org/) is used for 3D visualization of orbital mechanics.
- **Controls**: [lil-gui](https://lil-gui.georgealways.com/) provides the interface for adjusting orbital parameters (semi-major axis, eccentricity, inclination, etc.).
- **Build Tool**: [Vite](https://vitejs.dev/) handles bundling and the development server.

## Prerequisites

- [Bun](https://bun.sh) (Runtime & Package Manager)
- [moon](https://moonrepo.dev) (Task Runner)

## Running Locally

1.  **Install dependencies**:

    ```bash
    bun install
    ```

2.  **Start the development server**:

    Using the moon task (recommended):

    ```bash
    moon run kepler-orbit:dev
    ```

    Or directly with bun:

    ```bash
    bun run dev
    ```

    The application will be available at `http://localhost:5173`.

## Building

To build the project for production (output to `dist/`):

```bash
moon run kepler-orbit:build
```

Or using bun directly:

```bash
bun run build
```
