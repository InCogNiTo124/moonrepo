---
date: 2022-01-13
title: "The C method"
subtitle: "An analytical knee/elbow searching method"
tags:
  - math
  - machine-learning
  - optimization
grammarly_score_start: 67
grammarly_score_end: 84
---
<meta name=viewport content="width=device-width,initial-scale=1">  
<meta charset="utf-8"/>
<script src="https://www.geogebra.org/apps/deployggb.js"></script>
<script>
    var params = {
        "appName": "graphing", 
        "width": 600, 
        "height": 600, 
        "showToolBar": false, 
        "showAlgebraInput": false, 
        "showMenuBar": false,
        "showResetIcon": false,
        "enableLabelDrags": false,
        "enableShiftDragZoom": true,
        "enableRightClick": false,
        "material_id": "kb8pta79"
    };
    var ggbApplet = new GGBApplet(params, true);
    window.addEventListener("load", function() { 
        ggbApplet.inject('ggb-element');
    });
</script>

!!!TOC!!!

Real systems in nature, including computer systems, economy, physics,  etc. may reach a point where the changes of the cost outweigh the performance changes with respect to some tunable parameter. This renders the further changes "not worth it" and sometimes maybe even harmful. Therefore, in many cases it is important to manage tradeoffs between the cost and performance. One particular point of interest in reaching a balanced tradeoff is called **the knee** or **the elbow**. Various definitions of a knee exist but the most popular one defines the knee as a point in which a graph obtains maximum curvature, or equivalently, an osculating circle at that point has the smallest radius.

Knee searching is quite important operation. In this post I'll describe the method I personally developed: the **C-method**.

## Description

![Figure 1: A typical trade-off curves. A balancing point, a.k.a. a knee, might be found at 30% for the blue curve and below 20% for the red curve.](https://www.ncss.com/wp-content/uploads/2013/01/ROC-Curve-21.png)

It all started with an observation: many tradeoff curves I've come across with vaguely look like $`\frac1x`$ or $`1-\frac1x`$. The most generic form of this equation is therefore:

```math
f\left(x\right) = a+ \frac{b}{x+c}
```

It has three shape parameters: $`a`$, $`b`$, and $`c`$, and fitting these parameters should be enough. However, I felt that this is way too much degrees of freedom; if I restrict the function with some constraints, I should ideally get the functional form with only one shape parameter. Most of my experience was that most of the time the function graphs are anchored to pass through the points $`(0, 0)`$ and $`(1, 1)`$, so I restricted the function such that $`f(0) = 0`$ and $`f(1) = 1`$.

### Constraint 1
When $`f(0)=0`$ is fed into the equation form results in a relation:
```math
\begin{align*}
0 = f(0) &= a+\frac{b}{0+c} =\\
         &= a+\frac{b}c\\
       b &= -ac \\
\end{align*}
```
Feeding the relation back into the equation results with:
```math
\begin{align*}
    f(x) &= a - \frac{ac}{x+c} =\\
         &= a\left(1 - \frac{c}{x+c}\right) =\\
         &= a\left(\frac{x+c}{x+c} - \frac{c}{x+c}\right) =\\
         &= \frac{ax}{x+c}
\end{align*}
```
which is cute and simple.[^1]

### Constaint 2
Feeding $`f(1)=1`$ gets us a quick win:
```math
\begin{align*}
f(1) &= \frac{a}{1+c} = 1\\
a &= 1+c \\
\end{align*}
```
and feeding it back results in:
```math
f(x) = \frac{\left(1+c\right)x}{x+c}
```

## Analysis and reparametrization
The result has several properties:
1. $`\lim_{c \rightarrow 0} = 1`$
2. $`\lim_{c \rightarrow +\infty} = x`$
3. When $`c \lt 0`$, the curve "flips", meaning the curve avoids the unit square.

I decided I did not like this as, while perfectly mathematically correct, it does not match my intuition at all :sweat_smile: to me, ideally $`\lim_{c \rightarrow 0}`$ should go to $`x`$ and $`\lim_{c \rightarrow +\infty}`$ should go to $`x`$. Also, I would like to restrict $`c`$ to all positive reals.

All of my problems are solved with a following substitution: $`c \rightarrow \frac1{e^c}`$.[^2] Doing the substitution gave me:
```math
\begin{align*}
f(x) = \frac{\left(1+c\right)x}{x+c} \Rightarrow f(x) &= \frac{\left(1+\frac1{e^c}\right)x}{x+\frac1{e^c}} = \\
    &= \frac{x\left(e^c+1\right)}{xe^c + 1}\\
\end{align*}
```
Much better, IMHO. It's got a nice visual which is easy to remember. The only difference is the parantheses :smile:

<figure>
<div id="ggb-element"></div>
<figcaption>The GeoGebra plugin animating the function as the $`c`$ parameter changes</figcaption>
</figure>


### Analysis
1. $`\lim_{c \rightarrow -\infty} = x`$, which was what I wanted
2. $`\lim_{c \rightarrow +\infty} = 1`$, which was also what I wanted
3. Flipping is now disabled

## How to use it to find a knee?
Three ways: the intuitive way, the technical way, and the hacky way.

### The intuitive way
The intuitive way starts with an observation that the function graph is symmetric with respect to the line $`y=1-x`$. Intersecting the graph with the line gives:
```math
\begin{align*}
1-x &= \frac{x\left(e^c+1\right)}{xe^c+1} \\
\left(1-x\right)\left(xe^c+1\right) &= x\left(e^c+1\right) \\
e^cx+1-e^cx^2-e^cx-x&=0 \\
e^cx^2+2x-1&=0 \\
\end{align*}
```

The quadratic equation has two solutions, however I must disregard one of them as it's smaller than $`0`$. Therefore, the knee point is at:
```math
x=\frac{-1+\sqrt{1+e^c}}{e^c}
```

### The technical way
The second way is way more technical as it involves a lot of calculus. If I define a curvature function $`K(x)=\frac{f''}{\left(1+f'^2\right)^\frac32}`$, I could find an extreme point by setting $`\frac{d}{dx}K\left(x\right) = 0`$. Before substitution, let's play with the expression first:
```math
\begin{align*}
\frac{d}{dx}K\left(x\right) &= \frac{d}{dx}\left(\frac{f''}{\left(1+f'^2\right)^\frac32}\right) = 0 \\
\frac{d}{dx}f''\cdot\left(1+f'^2\right)^{\frac32} &= f''\cdot\frac{d}{dx}\left(\left(1+f'^2\right)^{\frac32}\right) \\
f'''\left(1+f'^2\right)^{\frac32} &= f''\cdot\frac32\left(1+f'^2\right)^{\frac12}\cdot2f'f''\\
f'''\left(1+f'^2\right) &= 3f''^2f' \\
\end{align*}
```

The higher derivatives of $`f(x)`$ are as follows:
```math
\begin{align*}
f(x) &= \frac{x\left(e^c+1\right)}{xe^c+1} \\
f'(x) = \frac{d}{dx}f(x)&=\frac{e^c+1}{\left(xe^c+1\right)^2} \\
f''(x) = \frac{d}{dx}f'(x)&=-\frac{2e^c\left(e^c+1\right)}{\left(xe^c+1\right)^3} \\
f'''(x) = \frac{d}{dx}f''(x)&=\frac{6e^{2c}\left(e^c+1\right)}{\left(xe^c+1\right)^4} \\
\end{align*}
```
Substituting these equations leads to:
```math
\begin{align*}
f'''\left(1+f'^2\right) &= 3f''^2f'\\
\frac{6e^{2c}\left(e^c+1\right)}{\left(xe^c+1\right)^4}\left(1+\left(\frac{e^c+1}{\left(xe^c+1\right)^2}\right)^2\right) &= 3\left(-\frac{2e^c\left(e^c+1\right)}{\left(xe^c+1\right)^3}\right)^2\frac{e^c+1}{\left(xe^c+1\right)^2} \\
\frac{6e^{2c}\left(e^c+1\right)}{\left(xe^c+1\right)^4}\frac{\left(xe^c+1\right)^4 + \left(e^c+1\right)^2}{\left(xe^c+1\right)^4} &= 12\frac{e^{2c}\left(e^c+1\right)^2}{\left(xe^c+1\right)^6}\frac{e^c+1}{\left(xe^c+1\right)^2} \\
\left(xe^c+1\right)^4+\left(e^c+1\right)^2 &= 2\left(e^c+1\right)^2 \\
\left(xe^c+1\right)^4 &= 2\left(e^c+1\right)^2 \\
\left(xe^c+1\right)^2 &= e^c+1 \\
xe^c+1 &= \sqrt(e^c+1) \\
x &= \frac{\sqrt{e^c+1}-1}{e^c} \\
\end{align*}
```
which is what we've already obtained in the last step, which is great!

### The hacky way
The third approach is rather hacky. By invoking a [Mean Value Theorem](https://en.wikipedia.org/wiki/Mean_value_theorem), we know there must be a point on the curve of $`f(x)`$ in which the slope of the tangent is equal to the slope of the secant between $`(0, 0)`$ and $`(1, 1)`$. That slope is, obviously, 1. Therefore, finding the derivative and evaluating it with 1 gives:
```math
\begin{align*}
\frac{d}{dx}f(x) &= 1 \\
\frac{d}{dx}\frac{x\left(e^c+1\right)}{xe^c+1} &= 1 \\
\frac{e^c+1}{\left(xe^c+1\right)^2} &= 1\\
\end{align*}
```
which, once again, results with $`x = \frac{\sqrt{e^c+1}-1}{e^c}`$.

After three different proofs, I guess it's safe to say that $`x = \frac{\sqrt{e^c+1}-1}{e^c}`$ is a good estimator of the theoretical knee.

## Estimating the c
After this theoretical derivation, the next problem is fitting the $`c`$ coefficient to the real world data, $`N`$-dimensional vectors $`\textbf{x}`$ and $`\textbf{y}`$. The first, and only insofar, fitting procedure I've come up with is the ordinary least squares: minimization of:

```math
E = \sum_{i=1}^{N}{\left(y_i - f(x_i)\right)^2} = \sum_{i=1}^{N}{\left(y_i - \frac{x_i\left(e^c+1)\right)}{x_ie^c+1}\right)^2} 
```

I've implemented a $`c`$-fitting procedure in my project called [knarrow](https://github.com/InCogNiTo124/knarrow.git) in the form of the Newton-Raphson method.
```math
\begin{align*}
\frac{\partial E}{\partial c} &= \frac{\partial}{\partial c}\left(\sum_{i=1}^N{\left(y_i - f(x_i)\right)^2}\right) \\
&= 2 \sum_{i=1}^N{\left(f(x_i)-y_i\right)\frac{\partial}{\partial c}f(x_i)}\\
&= 2 \sum_{i=1}^N{\left(y_i-\frac{x_i\left(e^c+1\right)}{x_ie^c+1}\right)}\frac{\left(x_i-1\right)x_i\mathrm{e}^c}{\left(x_i\mathrm{e}^c+1\right)^2}\\

\frac{\partial^2 E}{\partial c^2} &= \frac{\partial^2}{\partial c^2}\left(\sum_{i=1}^N{\left(y_i - f(x_i)\right)^2}\right) \\
&= 2\sum_{i=1}^N{\left(\frac{\partial}{\partial c}f(x_i)\right)^2} + 2\sum_{i=1}^N{\left(f(x_i) - y_i\right)\frac{\partial^2}{\partial c^2}f(x_i)} \\
&= 2\sum_{i=1}^N{\left(\frac{x_i\left(e^c+1\right)}{x_ie^c+1}\right)^2 + \left(\frac{x_i\left(e^c+1\right)}{xe^c+1}-y_i\right)\dfrac{\left(x_i-1\right)x_i\mathrm{e}^c\left(x_i\mathrm{e}^c-1\right)}{\left(x_i\mathrm{e}^c+1\right)^3}}\\
\end{align*}
```

These equations are then simply converted to an update rule:
```math
c_{n+1} \leftarrow c_n - \frac{\frac{\partial E}{\partial c}}{\frac{\partial^2 E}{\partial c^2}}
```
which works for any starting value $`c_0`$. This procedure is repeated until a satisfactory level of precision is reached. The resulting shape parameter $`c`$ is then fed into the equation above to get the knee point. Optionally, one can also calculate which of the input $`x_i`$'s is the closest to the theoretical knee and denote that particular $`x_i`$ as a knee.

## What's next?
- I would be most happy if I found that $`f'(x)`$ could be written in terms of $`f(x)`$ or $`f''(x)`$ could be written in terms of $`f'(x)`$ in a nice manner (just like the derivative of a sigmoid). However, I am not _that_ good in algebra.
- Efficient implementation. Currenctly it's implemented as a brain-dead _verbatim_ implementation using only numpy. I'm even calling other functions to calculate the derivatives, which turned out to be rather slow. If I ever accomplished the point above, this would easily follow.
- Sometimes, the graphs which are in need of the knee/elbow search do not behave like $`1-\frac1x`$ but more like $`1-\frac1{x^2}`$ or $`1-\frac1{\sqrt{x}}`$. It would be great to investigate such possibilities and allow for one more shape parameter.

Thank you for your time and until next time,
Marijan Smetko
QED

[^1]: However it should be emphasised that this was only possible because the degree of the denominator was 1. Future generalizations which would allow for a different exponent

[^2]: Mathematicians probably hate me right now.
