/// <reference types="@sveltejs/kit" />

// See https://kit.svelte.dev/docs/types#the-app-namespace
// for information about these interfaces
declare namespace App {
	// interface Locals {}
	// interface Platform {}
	// interface Session {}
	// interface Stuff {}
}

type Tag = string;

interface Post {
  date: string;
  title: string;
  subtitle: string;
  content: string;
  tags: Tag[];
  slug: string;
}
