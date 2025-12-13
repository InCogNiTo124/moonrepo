---
date: 2022-05-16
title: "Average entropy of a discrete probability distribution (part 1)"
subtitle: "with respect to its dimensionality"
tags:
  - math
  - research
  - code
  - stats
---

!!!TOC!!!

In this blogpost I will present my own little research in maths: the search for
an expression of the expected value of an n-dimensional discrete probability
distribution.

## Average entropy

The story begins while I was learning
[Information Theory](https://www.fer.unizg.hr/en/course/infthe_a) at my uni. We
talked about the entropy of a binary random variable. A binary random variable
is a variable which only ever has two outcomes, 0 or 1.[^bin]. The
[pmf](https://en.wikipedia.org/wiki/Probability_mass_function) of a Bernoulli
variable is

```math
\begin{pmatrix}
0 & 1   \\
1-p & p
\end{pmatrix}
```

which reads as "_the probability of a random variable to have a value of 1 is
$`p`$ and to have a value of 0 is $`1-p`$_".

The entropy of a Bernoulli variable is then[^ln]

```math
E\left[X\right] = -p\ln\left(p\right) - \left(1-p\right)\ln\left(1-p\right)
```

which looks like this:
![Figure 1: The entropy of a Bernoulli random variable with respect to the probability parameter $`p`$. It resembles a parabola as it's symmetric around $`p=\frac12`$. ](https://rechneronline.de/function-graphs/graph.php?a0=2&a1=-x%2Aln%28x%29-%281-x%29%2Aln%281-x%29&a2=&a3=&a4=1&a5=4&a6=8&a7=1&a8=1&a9=1&b0=500&b1=500&b2=0&b3=1&b4=0&b5=1&b6=10&b7=10&b8=0&b9=0&c0=3&c1=0&c2=1&c3=1&c4=1&c5=1&c6=1&c7=0&c8=0&c9=0&d0=1&d1=20&d2=20&d3=0&d4=&d5=&d6=&d7=&d8=&d9=&e0=&e1=&e2=&e3=&e4=14&e5=14&e6=13&e7=12&e8=0&e9=0&f0=0&f1=1&f2=1&f3=0&f4=0&f5=&f6=&f7=&f8=&f9=&g0=&g1=1&g2=1&g3=0&g4=0&g5=0&g6=Y&g7=ffffff&g8=a0b0c0&g9=6080a0&h0=1&h1=&h2=&h3=&h4=0&z)

Now for the question: what is the average entropy of a Bernoulli variable? If we
were to pick a lot of random $`p`$, calculated the entropy and averaged all of
them, what number would we get as a result? We could just integrate over all
$`p`$'s, and divide by the size of the space of $`p`$. To borrow some physics
intuition, to calculate the average density of an object, you first calculate
the mass of an object by integration, and then divide by the size of the object
(i.e. its volume). Here the "size" of the space happens to be $`1`$. Anyways:

```math
\begin{align*}
\overline{E_2}  &= \frac1{1-0}\int_{0}^{1}{E(p)\mathrm{d}p} =\\
                &= -\int_{0}^{1}{p\ln\left(p\right) + \left(1-p\right)\ln\left(1-p\right) \mathrm{d}p} =\\
                &= ... \mathrm{use\ photomath\ or\ sth} ...\\
                &= \frac12
\end{align*}
```

So the average entropy turns out to be $`\frac12`$. If we were to pick $`p`$ at
random afew times and calculate the average, we should get something in the
vicinity of $`0.5`$. Cute.

## Two's a company, three's a crowd

Let's move a step up. What if we picked a random 3-dimensional "Bernoulli" and
calculated it's entropy. What is the average (or expected) entropy of a random
3-dimensional variable?

First, let's define some stuff. 3-d Bernoulli variable does not exists, as the
term _Bernoulli_ is reserved for 2-dimensional case excusively. Higher
dimensional random variables are caled Multinoulli, presumably because someone
was feeling particularly creative that day. It's entropy is calculated with:

```math
E[X] = -\sum_{i=1}^{N}{p_i\ln(p_i)}
```

There is constraint that $`\sum_i{p_i} = `$ and
$`p_i \le 0, \forall 0 \le i \le N`$. Particular instance of this formula for
the 3-dimensional case is:

```math
E_3(p, q) = -p\ln(p) - q\ln(q) - (1-p-q)\ln(1-p-q)
```

which looks like this:
![Figure 2: 3d graph of the entropy of all multinoulli variables. It is similar to a parabolloid, but slanted. This function has a maximum at $`(p, q) = (\frac13, \frac13)`$.](3d_entropy.png)

How do we calculate the average entropy of this? Using the same process as
above: integrate the function and divide by the "size" of the function's domain.
Here, the domain is a 2D triangle[^domain] determined by the lines $`p \ge 0`$,
$`q \ge 0`$, $`p+q \le 1`$. This triangle is exactly one half of the unit
square, so it has to have an area of $`\frac12`$. The average entropy of a
3-dimensional multinoulli variable is:

```math
\begin{align*}
\overline{E_3}  &= \frac1{\frac12}\int_{0}^{1}{\int_0^{1-p}{E(p, q)}{\mathrm{d}q}}{\mathrm{d}p} =\\
                &= \frac1{\frac12}\int_{0}^{1}{\int_0^{1-p}{-p\ln(p) - q\ln(q) - (1-p-q)\ln(1-p-q)}{\mathrm{d}q}}{\mathrm{d}p} =\\
                &= ... \mathrm{use\ wolfram\ alpha\ or\ sth} ...\\
                &= \frac5{12}
\end{align*}
```

Okay, no visible pattern so far. To quote data scientists, "More data is
needed!". To dimension no.4 :rocket:

## Three is a crowd, four is unthinkable. Literally

Let's try to find out what happens if we calculate the average entropy of a
random 4-dimensional multinoulli variable. This is something we usually cannot
even imagine, however it's quite feasible due to maths. The recipe is the same:
integrate and divide by the volume of the domain.

First, we'll have to add one more variable to the calculation of entropy:

```math
E_4(p, q, w) = -p\ln(p) - q\ln(q) - w\ln(w) - (1-p-q-w)\ln(1-p-q-w)
```

Then, we calculate the volume of the domain. We are now in the 3D so we have
planes instead of lines. The domain is a pyramid between these 4 planes:

- $`p \ge 0`$
- $`q \ge 0`$
- $`w \ge 0`$
- $`p+q+w \le 1`$

and its volume is $`\frac16`$. (This is a good exercise for the reader btw)

And now for the integral...

```math
\begin{align*}
\overline{E_3}  &= \frac1{\frac16}\int_{0}^{1}{\int_0^{1-p}{\int_0^{1-p-q}{E(p, q)}{\mathrm{d}w}}{\mathrm{d}q}}{\mathrm{d}p} =\\
                &= \frac1{\frac16}\int_{0}^{1}{\int_0^{1-p}{\int_0^{1-p-q}{-p\ln(p) - q\ln(q) - w\ln(w) - (1-p-q-w)\ln(1-p-q-w)}{\mathrm{d}w}}{\mathrm{d}q}}{\mathrm{d}p} =\\
                &= ... \mathrm{? ? ? ? ?}
\end{align*}
```

WolframAlpha doesn't really help anymore. :cry: But some other symbollic
computing tools come to rescue, namely [Sympy](https://www.sympy.org)

```pyshell
>>> from sympy import symbols, integrate, ln, simplify
>>> p, q, w = symbols('p q w', real=True)
>>> E = -p*ln(p)-q*ln(q)-w*ln(w)-(1-p-q-w)*ln(1-p-q-w)
>>> domain_volume = 1/6
>>> res = integrate(f, (w,0,1-p-q), (q,0,1-p), (p,0,1))
>>> # seven hungry years later
>>> print(result.real / domain_volume)
13/12
```

The result is $`\frac{13}{12}`$.[^complex] No obvious pattern yet.

And also, these integral solving functions take progressively more and more
time. Running it for 2-dimensional case took ~4sec, for 3-dimensional case took
~20 sec, and for 4-dimensional case it took a whooping 163 sec to get an anwser.
If we assume it's a factorial growth, we're looking forward to ~10 minutes for
5-dimensional case and ~2h for 6 dimensions.

I could, in theory, buy a better laptop but it won't help me much. Therefore,
we'll need to look for other methods that trade computation speed for absolute
precision. See you in the next part.

[^bin]:
    While this is not entirely true, I'll leave it at that for brevity's sake

[^ln]:
    $`\ln()`$ is a so-called _natural logarithm_, logarithm with a base
    $`e`$.[^ent]

[^ent]:
    Usually, the entropy is defined using $`\log_2()`$ and not $`\ln()`$.
    However, using base e will be beneficial for the end result :smile:. The
    only difference anyways is just the scaling factor of $`\ln(2)`$. The volume
    of the domain is the easier part: it is now

[^domain]:
    It is a general pattern that the entropy of an $`d`$-dimensional variable is
    a function of $`d-1`$ variables. This stems from the fact that
    $`\sum{p} = 1`$; you always need one variable less because you can calculate
    it from all the others.

[^complex]:
    An astute reader might be wondering why is there a `.real` attribute acess.
    The truth is - I don't really know haha while solving these integrals, Sympy
    would always return some dubious complex numbers, but the result I needed
    was always the real part. I'm not sure why this keeps happening, bit it
    seems to be working :smile:
