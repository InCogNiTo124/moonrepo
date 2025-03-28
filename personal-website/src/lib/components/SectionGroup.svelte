<script lang="ts">
  import { SectionGroup } from 'personal-reusables';
  import Section from '$lib/components/Section.svelte';

  export let sections: Array<TSection> = [];
</script>

<SectionGroup
  sections={sections.map((section, idx) => ({ ...section, id: idx }))}
  noSections={false}
  page={null}
  {Section}
/>
