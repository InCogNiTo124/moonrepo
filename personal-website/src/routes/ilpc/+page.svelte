<script lang="ts">
  import { TARGET_BLANK, INLINE_CLASS } from 'personal-reusables';
  import SectionGroup from '$lib/components/SectionGroup.svelte';

  let sections: TSection[] = [
    {
      title: 'What it is',
      texts: [
        'In 2021 I held a Python programming language course <i>pro bono</i>. I named it "InCogNiTo124\'s Little Python Course", for my online username at a number of websites. Although intended primarily for the students of my faculty, it was watched by numerous other people from all around the region, from Vienna, Austria to Belgrade, Serbia. It was very well recieved, with numerous good reviews and thanks for my teaching style, interesting examples and homework assignments',
      ],
    },
    {
      title: 'Why I did it',
      texts: [
        "I did it primarily because there aren't enough materials for Python at my faculty, and especially in my native language, and secondarily, because I wanted to try myself at teaching, to push myself out of the comfort zone. It was an excellent creative experience, as I had to deal with a lot of problems, such as teaching infrastructure, interesting but useful-in-real-world examples, and making and organizing curriculum and lectures themselves.",
      ],
    },
    {
      title: 'Materials',
      texts: [
        `The course's official repository, including the lecture recordings and homeworks (both in Croatian) can be found <a class=${INLINE_CLASS} ${TARGET_BLANK} href="https://github.com/InCogNiTo124/ILPC">here</a>.`,
      ],
    },
  ];
</script>

<svelte:head>
  <title>ILPC</title>
</svelte:head>

<div class="about">
  <SectionGroup {sections} />
</div>
