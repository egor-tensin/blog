My blog
=======

[![Jekyll](https://github.com/egor-tensin/blog/actions/workflows/jekyll.yml/badge.svg)](https://github.com/egor-tensin/blog/actions/workflows/jekyll.yml)

My blog, hosted at https://egort.name/blog/.

Development
-----------

This is a "static" website, generated using [Jekyll].

Make sure you have Ruby and [Bundler] set up.
[GNU Make] is used for shortcuts.

* Install dependencies by running `make deps`.
* Build the website by running `make build`.
* Launch a local web server by running `make serve`.
Access the website at http://localhost:4000/blog/.

[jekyll-theme] is used as a remote Jekyll theme.

[Jekyll]: https://jekyllrb.com/
[Bundler]: https://bundler.io/
[GNU Make]: https://www.gnu.org/software/make/
[jekyll-theme]: https://github.com/egor-tensin/jekyll-theme

### Access via file://

Jekyll doesn't provide native support for generating a static website which can
be browsed without running a web server.
One workaround is to `wget` the website (use `make wget`).
The truly static version will be downloaded to the .wget/ directory.

License
-------

Distributed under the MIT License.
See [LICENSE.txt] for details.

[LICENSE.txt]: LICENSE.txt
