# Personal Blog

This repository contains the source code for my personal blogging platform. It
is a custom-built system designed to fit my specific workflow, involving writing
in Obsidian, processing with Python, serving with Rust, and displaying with
SvelteKit.

## Architecture Overview

The system consists of three main components: a processing pipeline, a backend
server, and a frontend application.

### 1. Content Authoring (Obsidian)

- **Writing**: Blogs are written as standard Markdown files using
  [Obsidian](https://obsidian.md/).
- **Structure**: Each blog post resides in its own folder within
  `database/posts/<slug>/`.
- **Assets**: Images and other assets are stored locally within the post's
  folder, keeping content self-contained.

### 2. Processing Pipeline (Python)

Located in `database/compile.py`, this script handles the transformation of raw
Markdown into a structured format for validity and storage.

- **Markdown Parsing**: Uses the `markdown` Python library.
- **KaTeX Support**: Mathematical equations are rendered using the
  `markdown-katex` extension, allowing for high-quality math typesetting
  directly from Markdown.
- **Image Handling**: A custom `ImgUrlRewriter` processes image paths to ensure
  they satisfy the backend serving logic (rewriting relative paths to include
  the post slug).
- **Storage**: Processed content, metadata (like tags, title, date), and HTML
  are is stored in a SQLite database (`db.sqlite3`).
- **RSS Feed**: Automatically generates a `feed.rss` file for subscribers.

### 3. Backend (Rust)

The server logic resides in `database/src`. It is a high-performance backend
serving content and assets.

- **Framework**: Built with [Rocket](https://rocket.rs/).
- **Database**: Uses [Diesel](https://diesel.rs/) ORM to query the SQLite
  database.
- **Endpoints**:
  - `/post/<slug>`: Returns the blog post content and metadata tag-enriched
    JSON.
  - `/post/<slug>/<image>`: Serves images specific to a blog post.
  - `/feed.rss`: Serves the RSS feed.
- **Dockerized**: The backend is compiled into a static binary (using `musl`)
  and deployed in a scratch container for minimal footprint.

### 4. Frontend (SvelteKit)

The user interface is a SvelteKit application located in the `frontend/`
directory.

- **Framework**: [SvelteKit](https://kit.svelte.dev/) (using Svelte 5).
- **Language**: TypeScript.
- **Rendering**: Fetches content from the Rust backend API. The raw HTML content
  (including pre-rendered KaTeX) is injected securely into the page.
- **Styling**: Custom CSS and syntax highlighting for code blocks.

## Workflow

1.  Write a new post in Obsidian.
2.  Run the `compile.py` script to parse Markdown, render equations, and
    populate the SQLite database.
3.  The Rust backend serves the `db.sqlite3` content and static assets.
4.  The SvelteKit frontend consumes the API to render the blog for readers.
