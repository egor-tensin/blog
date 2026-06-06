---
title: LaTeX
subtitle: document template
---
A more-or-less complete, but still very basic LaTeX document follows.

```tex
\documentclass[11pt]{article}

% Basic setup
\usepackage{cmap}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc} % Use T2A for non-ASCII scripts
\usepackage[english]{babel}

% Completely arbitrary settings follow:

% Sans serif font by default
\renewcommand\familydefault{\sfdefault}

% Document margins
\usepackage[margin=2.5cm]{geometry}

% Paragraph indents
\usepackage{parskip}
\setlength\parindent{0cm}
\setlength\parskip{0cm}

% URLs
\usepackage[colorlinks=true,urlcolor=blue]{hyperref}

\begin{document}

Hello, \LaTeX!
Repository link: \href{https://github.com/egor-tensin/blog}{https://github.com/egor-tensin/blog}.

\end{document}
```
