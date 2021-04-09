---
title: Markdown style guide
---
* `diff`- and HTML-friendliness is valued over human-readability.
* Every sentence starts on a new line ("semantic newlines").
* Lines are at most 79 characters long, not counting neither the carriage
return, nor the line feed characters.
    * Not 80 characters, because when you display a 80-character line with a
line feed at the end in Windows' `cmd`, an extra empty line is added.
* No hanging indents in lists.
    * Nested lists are indented with 4 spaces.
    * No hanging indents in those also.
    * Longer items wrap at 79 characters and continue from the leftmost
character column.
Additional sentences start there also.
* Prefer reference-style links over inline links.
Omit the second pair of brackets `[]` entirely where appropriate.
For example, [Google] is preferred over both [Google](https://ya.ru) and
[I'm feeeling lucky][google] (see [this document's source]).
* First- and second-level headers are underlined with strings of `=` and `-`.
The number of `=`/`-` signs must be equal to the number of characters in the
header.
* File paths are enclosed in double quotes.
Environment variable names are enclosed in a pair of backticks (\`) unless it's
a part of a path.
Executable names are enclosed in a pair of backticks (\`) unless it's a part of
a path, a link or a header.
* Code blocks are indented with 4 spaces.

      Code blocks inside lists are indented according to the spec
      (https://github.github.com/gfm/#list-items), i.e. the column of the first
      non-whitespace character in the item + 4.

* Don't mix fenced code blocks with indented code blocks in a single document.

| In a table, | the first | row   | is underlined.
| ----------- | --------- | ----- | --------------
| Leftmost    | vertical  | lines | are required.
| Rightmost   | vertical  | lines | are omitted.
{: .table .table-bordered }

[Google]: https://www.google.com/
[this document's source]: https://raw.githubusercontent.com/{{ site.github.repository_nwo }}/{{ site.github.source.branch }}/{{ page.path }}
