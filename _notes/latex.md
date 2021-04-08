---
title: Basic LaTeX document
---
A more-or-less complete, but still very basic LaTeX document follows.

```tex
\documentclass[11pt]{article}

% Basic setup
\usepackage{cmap}
\usepackage[utf8]{inputenc}
\usepackage[T2A]{fontenc}
\usepackage[russian]{babel}

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

Привет, \LaTeX!
Ссылка на репозиторий: \href{https://github.com/egor-tensin/notes}{https://github.com/egor-tensin/notes}.

\end{document}
```
