---
date: 2025-07-03
title: "Web Summer Camp 2025: behind the scenes"
subtitle: "Honest soul-pouring about my first public speaking opportunity"
tags:
  - bts
  - speaking
---

!!!TOC!!!

In July 2025 I had my first public speaking engagement: I held an
[LLM serving workshop at Web Summer Camp 2025](https://websummercamp.com/2025/workshop/serving-llms-from-the-first-principles).

Web Summer Camp by Netgen is a long-lived web development conference primarily
focused on things that power the organization company,
[Netgen](https://netgen.io/): PHP (Symphony), JS, UX and project management.
There's a twist, though: most of the presented content aren't just talks,
they're practical workshops intended to give the best experience to the
audience. Since I'm probably as far as it gets from web development, it's an
interesting story how I ended up there.

The year before my workshop, Ivo Lukač, founder of Netgen, approached me and
shared with me that they plan to introduce a new track the next year, focused on
Python and AI, and whether I'd like to apply to hold a workshop there. I always
dreamed about having a public speaking career, and incidentally, I had an idea
and some materials about a talk i wanted to hold once re model serving. So i
said: "Sure, I'll think of something", wrote a description and sent a
submission. One day, I received the acceptance mail, and the rest is history.

A more interesting story, however, is how the workshop I held actually came to
be.

## Everything old becomes new again

I had conceived the original idea early in the history of "MLOps" how it used to
be called, back in 2022. I was supposed to present traning and serving a dog/cat
classifier. There weren't a lot of options back then, so I had prepared a simple
TorchServe script and a Triton inference server example. That was also a
different time, when we (as Deep Learning industry) had plenty of architectures
to choose from, each specialized for its usecase. Upon returning to that repo, I
learned that almost everything had changed

First, there are plenty more serving options now: Triton is still here, there's
this new (to me) kid on the block called vLLM, and there are dozens of local
model serving tools. Second, everything are LLMs now, even for multiple
modalities. I took the simple decision and stayed with what I knew the best
(Triton), and found a new use case that leveraged LLMs.

At first, I prepared the workshop with Gemma 2 in mind. I had both parts of my
workshop more or less ready, when Gemma 3 came out, which showed much better
results. Unfortunately, the serving technology lagged quite a bit behind and
Triton simply did not support that new architecture. Due to two poorly timed
releases and bugfixes on the Triton inference server repo, I had to wait until
early May to actually start working on the second part of the workshop. Fun
times :slightly_smiling_face:

Also, with a switch to Gemma 3, I had to give up multiple modalities because,
simply put, Triton Inference server still does not support image input Gemma v3.
I had to scrap my math problem solver for a simple text-only chat experience.

And to top it all off, I got sick for 3 days in June, just when I was supposed
to start developing the workshop. I suppose it was all the stress. But, I did
manage to finish and test everything out by the end of June.

## Cloud GPUs and where to find them

A whole another show was with the cloud providers. I had (what I percieve as)
simple requirements: I want the ability to create ~30 cloud instances, with GPUs
(I don't care which one, as long as it can serve LLMs), on which I could run
Docker containers. A secondary goal was not to go bankrupt, but honestly, I was
perfectly fine paying a bit more just to give my audience the experience they've
already paid for by being at the workshop.

This is an excerpt from my notes (the interesting ones):<br/>

| Provider    | why no                                                                               |
| ----------- | ------------------------------------------------------------------------------------ |
| Dataoorts   | Can't run Docker                                                                     |
| Paperspace  | I couldn't get an approval for GPUs                                                  |
| Lambda labs | They don't support debit cards??                                                     |
| puzl.cloud  | They couldn't support 30 GPUs                                                        |
| runpod      | Can't run Docker                                                                     |
| GCP         | [Appearance of impropriety](https://en.wikipedia.org/wiki/Appearance_of_impropriety) |

Eventually, I settled with [Exoscale](https://www.exoscale.com/). They allowed
me to create a machine image with all the drivers, spawn up to 30 instances of
said machine image with an adequate GPU, and the GPU clearance was "pay us
upfront". Huge shout out to Benoit and Iva from the support!

## Tech Enthusiast Playground Paradise

This workshop was actually **an excellent** opportunity for me to finally
explore some tools I've been meaning to explore:

- I finally tried out [reveal.js](https://revealjs.com/) for slides in markdown.
  I loved it, but then I had the need for more advanced functionality so I
  switched to their pro web app [slides.com](https://slides.com). I'll probably
  continue on being their user, the site is nice, the functionality is nice
  (they're really focused on developers).
- I finally tried out [`just`](https://just.systems) for command running. I did
  not used any of it advanced functionality, but it worked pretty okay. By the
  end I kinda felt more comfortable to try something more complex. I'll also
  probably use it more in the future.
- I also finally got the opportunity to work with Packer for creating instance
  templates. This one decreased instance start time by 80% (~10s of minutes ->
  minutes).
- [`astral-sh/uv`](https://github.com/astral-sh/uv) for Python package
  management. not my first time using it, but definitely the most serious
  attempt. I fell in love with it once again, because it Just Works™. For the
  workshop, I had a virtual instance that ran JupyterLab as a systemd service on
  startup. I only had to write uv run for the exec and it handled all the env
  setup (dependency installation) for me.

### jj vcs

The most useful tool I worked with during the creation of this workshop was
definitely the [`jj` VCS](https://github.com/jj-vcs/jj). I've been actually
running jj for private projects for over a year now, so it can hardly be called
exploring, but I finally had a great use case for some of the more complex
workflows:

- Frequent creation of new changes just to try something new out
- jj mega merge + jj absorb. Mega merge is when you merge many changes (10+)
  into a new child change. You can then make edits in that merged child as
  needed (making stuff build, syntax, typos), and jj absorb **distributes the
  edits back to the parent changes accordingly**. Probably the closest thing to
  magic I felt _in years_.
- moving changes in files to an earlier point in history. For example, quite
  late in the workshop development process, I realised that I needed another
  dependency. A simple `uv add` in the middle of the change chain, and
  `jj squash` to move the lock file to the first commit of the workshop branch.
  The rest of the chain gets rebased automatically. Literal chef's kiss.
- Rewriting history in general, such as splitting changes, changing the order of
  changes, their descriptions, and rebasing all the descendants automatically.
  In order to have a clean sequence of changes with git, you basically have to
  one-shot it, as it's pretty hard to retroactively fix mistakes. And I really
  cared about having every change be a self contained unit (see learned lesson
  #2 below).
- I finally conceded and started using a visual conflict resolution tool (Meld).
  I'd say it's better than vimdiff, but also, the difference in experience is
  not _that_ big. I might go back to vimdiff, or I might try something else
  (kdiff3?)

All in all, I understand that the use case of 1) a single developer 2) working
on a fixed functionality in a single repo 3) and that functionality is an
ordered sequence of changes that primarily tell a story, is not the most
representative use case for a VCS. But I truly mean it when I say that this tool
enabled the workshop to be as complex as it was. Without jj the scope would be
much smaller. If you haven't already, I recommend you try it.

## Lessons learned

### 1. Content creation is hard business

From the moment I started working on the workshop until I actually held
it, >6months of wall time have passed. Of course I didn't work during this
entire period, but I did work for a larger chunk than anticipated. I'd estimate
that if I worked on the workshop for 10h a day, 6 days per week, I'd get it done
within a ~month. This is _a huge amount_, especially with a full time job and
with [other](https://mbrizic.com/blog/receipt-scanner/) personal commitments.

### 1.b Exploration is a huge part of it

If I knew _exactly_ what I wanted to create, I'd be done in 3 days. This way,
80-90 percent of time actually went into exploring the landscape. Which model to
try out? What use case? Which model serving technology to explore? How deep do I
go with the fundamentals? All sorts of things had to be answered during the
production, multiple times, with an expensive evaluation of answers and frequent
misses. One thing in particular that I spent a lot of time on was installing and
aligning GPU types, cuda drivers and dependencies. I tried out 5 GPUs with
Exoscale alone, only to find out it's too old and it does not support something
I needed. Truly an unfortunate state of affairs.

### 2. Apparently I'm a perfectionist now??

I was always proud of myself to be the person that knew when enough is enough,
how not to let the "perfect" be enemy of the "good", and when to stop investing
effort. Also, I've never really saw myself as a detail-oriented person[^gf], I'm
definitely more of a knowledge-breadth guy than a knowledge-depth guy. But
working on this workshop woke a pedantic side of me that I never experienced
before. On my first pass through the entire thing, I ended up with a full page
worth of TODOs in my Obsidian. And by pure magic, after the second pass to solve
some of the entries, the list got even bigger. I'm not trying to do a public
introspection session here, but it's probably because I cared about this
workahop way more than the other things I did before. This realization also sort
of scares me, because it implies I'm not able to do Good Work™ without being
personally invested, and caring about something is a constrained resource. Let's
see if I can hack myself around this.

### 3. I love public speaking

There's something weird in my brain. The moment I step on the stage, it
immediately goes into a new, higher functioning state. It's like switching to a
very high gear. The brain starts working really quickly, my creativity
increases, I'm so excited, and I truly feel like home, like I belong in front of
people telling stories and making dumb contextual jokes[^mbti]. Sadly, I'm
completely alone in this in my circle of friends, so I can't relate with anyone
close. But it's true: I love public speaking and I feel at home on the stage.

## Open questions

### AI usage

Here's a confession: I hadn't use any sort of AI for developing this
workshop[^irony] up until the last day where I could not be bothered to write,
again, a Docker Compose file, which I've done more times than I can count. There
are plenty of reasons for this, and not all of which are practical, but the most
important one was that this workshop was, primarily, _a way to express myself_.
The emphasis is on me, a human, that likes exploring stuff, creating things, and
sharing knowledge. Creating this was genuinely a fun experience which I'm likely
to repeat in some form or another.

That said... I really spent a lot of time on this, and I sacrificed some other
parts of my life because I wanted everything to be accessible and clear and
nicely presented. Here's the kicker: those are conflicting goals. _The way I
like telling stories might not be the best way to explain a thing_. And this
seems to be the promise of AI, to be better at something than the humans (+
obvious time saving). The problem is, now after creating the workshop and
reflecting on what I created, I can't really think of a way where an LLM
would've helped me. And that is actually what I want answered: is there a use
out of LLMs for me developing workshops?

<hr/>

Time will tell... ... and more opportunities will help me! If you're reading
this, and would like me to host a talk somewhere, please let me know

[^gf]: And if you ask my partner if I'm detail-oriented, she'll die laughing
[^irony]: which is ironic, since the entire workshop is about AI
[^mbti]:
    For a university course, I actually had to do a Myers Briggs test (wtf, ikr)
    and I turned out to be
    [ESFP](https://www.16personalities.com/esfp-personality).
