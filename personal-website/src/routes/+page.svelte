<script lang="ts">
  import dayjs from 'dayjs';
  import SectionGroup from '$lib/components/SectionGroup.svelte';
  import {
    FER_LINK_EN,
    TARGET_BLANK,
    INLINE_CLASS,
    BIRTHDATE,
  } from 'personal-reusables';

  const age: number = dayjs().diff(dayjs(BIRTHDATE), 'y');

  let sections: TSection[] = [
    {
      title: 'Who I am',
      texts: [
        `Marijan Smetko, ${age}, SWE @ Google`,
        `Ms of Science in Computing from <a class=${INLINE_CLASS} href=${FER_LINK_EN} ${TARGET_BLANK}>FER, University of Zagreb</a>, Croatia.`,
      ],
    },
    {
      title: 'My interests (professional)',
      texts: [
        'My primary interests are machine (and deep) learning and computer vision. Other interests include: physics, math (especially statistics), chemistry, chaos theory, and quantum computing.',
        "I'm also deeply married to the idea of computers as tools for automating redundant tasks, so I write a lot of Python and bash scripts.",
        "Recently I started dabbling with Rust, and I'm loving it.",
      ],
    },
  ];
</script>

<svelte:head>
  <title>About</title>
</svelte:head>

<div class="about">
  <SectionGroup {sections} />
</div>
