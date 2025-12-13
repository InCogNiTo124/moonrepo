---
date: 2022-01-09
title: "Hello, world!"
subtitle: "Description of what this is, how's it made and what it's supposed to be"
tags:
  - tech
  - writing
  - test
grammarly_score_start: 67
grammarly_score_end: 84
---

# Hello, world

:rocket:

## What is this?

I've decided I want a blog. And I made it!

What you see here is custom-made blogging software. The reason I went building this thing myself is I wanted a blog that is themed just like my homepage https://msmetko.xyz. At the time it seemed easier to build a simple blogging system than customize an existing one.

I also kinda like challenges. I bet that had a _minor_ role in my decision.

## How it works?

### In the beginning there was a file

This blog post you're reading right now started its life as a Markdown `*.md` document. I was writing it in my living room in Kate text editor on my Asus notebook as a sort of a preview of what my blog may look like. After I finish my writing about anything, I commit the file to the git repository hosted (at the moment) on Github. (This may change in the future.)

### Devops paradise

At the moment of this writing, I haven't really built it yet, but at the moment of your reading, the blog itself was produced by a CI/CD pipeline. It's got two parts:

1. The Github part, which is triggered on a push. It doesn't do much: it simply connects to my server, goes into the GitHub repo on the server, and pulls all the latest changes. Then it spawns a second part.
2. The second part, running on my server, does a few things:
  - It builds a frontend, written in the Svelte framework by [@amalija-ramljak](https://github.com/amalija-ramljak). It boils down to `yarn install && yarn build` inside a docker container.
  - It compiles all my markdown blog posts into an `sqlite3` database. Interesting!
    - First, it reads the markdown file and converts it to HTML using the `markdown` library using a bunch of extensions, such as `katex` for math rendering, table of contents, emojis, and all sorts of interesting things
    - While reading a blog post, it also builds an RSS `.xml` file for the RSS clients. While not many people use RSS nowadays, quite a few computers do, such as [dev.to](https://dev.to) which pulls my blogposts and publishes them there. If you are reading this from dev.to now you know why :))
  - After everything is built, the old deployment is torn down and the new is deployed. This is what you read.

I'd say miraculous but you wouldn't hear me as we're in different parts of the world.

## What's it supposed to be?

First and foremost, this is my creative outlet space. I'll write about topics I find interesting: Python, programming in general, Linux, my projects and project ideas, math, machine and deep learning, physics, astronomy, to name a few.  I'll try to write at least once a week, however, if I'm trying to really dive deep into my next blog post topic it may last longer. Or I may fill the time up with lower-quality, "filler", blogposts. IDK ATM

Thank you for your time and until next time,
Marijan Smetko
QED
