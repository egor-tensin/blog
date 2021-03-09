---
title: Recurring decimals
excerpt: >
  Eighth-grader thoughts on recurring decimals.
category: Math
mathjax: true
---
First, let's determine that

$$
\newcommand\naturals{\mathbb{N}}
\newcommand\rationals{\mathbb{Q}}
\newcommand\reals{\mathbb{R}}

\newcommand\xs{x_{1}x_{2}\dots x_n}
\newcommand\nines{\overbrace{99\dots 9}^n}
\newcommand\pq{\frac{p}{q}}
\newcommand\qp{\frac{q}{p}}

0.(9) = 1
$$

This may seem counter-intuitive, but demonstrably true.
If $$0.(9) \neq 1$$, then $$\exists n \in \reals: 0.(9) < n < 1$$.
To put it another way, there must be a number greater than 0.(9) and lesser
than 1, equal to neither.
Thinking about it makes it obvious this is not true.

Slightly more formally,

$$
\begin{align*}
1 - 0.9 &= \frac{1}{10} \\
1 - 0.99 &= \frac{1}{100} \\
1 - 0.999 &= \frac{1}{10^{-3}} \\
\dots \\
1 - 0.\nines &= \frac{1}{10^n} \\
\end{align*}
$$

If $$0.(9) \neq 1$$, the following must hold:

$$
\forall n \in \naturals, \exists x \in \reals: x < \frac{1}{10^n}
$$

It's clear that the only such number is 0, making 0.(9) and 1 equal.

Let $$n \in [1,9]$$.
Is there $$\pq \in \rationals: \pq = 0.(n)$$?

For $$n = 9$$, we've established $$p = 1, q = 1$$.
For the other values of $$n$$ we can observe that

$$
\begin{align*}
0.(1) \times 9 &= 0.(9) = 1 \\
0.(2) \times 9/2 &= 0.(9) = 1 \\
0.(3) \times 9/3 &= 0.(9) \\
\dots \\
0.(8) \times 9/8 &= 0.(9) \\
0.(9) \times 1 &= 0.(9)
\end{align*}
$$

So,

$$
\forall n \in [1,9], \frac{n}{9} = 0.(n)
$$

In general, let's demonstrate that

$$
\forall n \in \naturals, n > 0, \forall 0.(x_{1}x_{2}\dots x_n), \exists \pq \in \rationals: \pq = 0.(\xs)
$$

Let $$p = \xs, q =\,\nines$$.
It's clear that

$$
\begin{align*}
0.(\xs) \times \qp &= 0.(\xs) \times \frac{\nines}{\xs} \\
&= \left(\frac{\xs}{10^n} + \frac{\xs}{10^{2n}} + \dots\right) \times \frac{\nines}{\xs} \\
&= \left(\frac{1}{10^n} + \frac{1}{10^{2n}} + \dots\right) \times\,\nines \\
&= 0.(9) \\
&= 1
\end{align*}
$$

Finally, $$0.(\xs) \times \qp = 1 \implies \pq = 0.(\xs)$$.
