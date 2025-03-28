<script lang="ts">
  import axios from 'axios';
  import { REPO_API } from 'personal-reusables';
  import SectionGroup from '$lib/components/SectionGroup.svelte';

  let projects = [];
  axios
    .get(REPO_API)
    .then((res: TGitHubProjectResponse) => {
      const plist = [];
      const whitelist = [
        'ChaosPlotter',
        'recursive-sgd',
        'MojBlokZaBelu',
        'PASS',
        'dotfiles',
        'personal-website',
        'm-numbers',
        'BelaBot',
        'Jumper',
        'chemeq',
        'knarrow',
      ];
      res.data.forEach((project: TGitHubProject) => {
        if (whitelist.includes(project.name)) {
          let p = {
            title: project.name,
            url: project.html_url,
            texts: [project.description],
            updated: project.updated_at,
          };
          plist.push(p);
        }
      });
      plist.sort((a, b) => {
        if (a.updated > b.updated) return -1;
        return 0;
      });
      projects = plist.map((e) => {
        return { title: e.title, url: e.url, texts: e.texts };
      });
    })
    .catch(console.error);
</script>

<svelte:head>
  <title>Projects</title>
</svelte:head>

<div class="about">
  <SectionGroup sections={projects} />
</div>
