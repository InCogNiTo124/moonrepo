/// <reference types="@sveltejs/kit" />

// See https://kit.svelte.dev/docs/types#the-app-namespace
// for information about these interfaces
declare namespace App {
  // interface Locals {}
  // interface Platform {}
  // interface Session {}
  // interface Stuff {}
}

type TSection = {
  title: string;
  texts: string[];
  url?: string;
  urlTarget?: string;
};

type TProject = TSection & {
  updated: string;
};

type TGitHubProjectResponse = {
  data: TGitHubProject[];
};

type TGitHubProject = {
  name: string;
  html_url: string;
  description: string;
  updated_at: string;
};
