Egor's blog
===========

Egor's blog on programming.
Hosted on [GitHub Pages] at https://egor-tensin.github.io/blog/.

[GitHub Pages]: https://pages.github.com

Development
-----------

[Jekyll] is used to build a set of static HTML pages from a collection of
templates and resources.
[Bundler] is used to manage project's dependencies.
Make sure you have the `bundler` gem installed; project dependencies can then
be installed by executing

    bundle install

in the project's root directory.

To run a local web server, run

    bundle exec jekyll serve --watch --drafts --config _config.yml,_config_dev.yml

You can then review your changes at http://localhost:4000/.

Or you can use [jekyll-docker] to set up a development environment in Docker
and not bother with installing everything locally.

[jekyll-theme] is used as a remote Jekyll theme.

[Jekyll]: https://jekyllrb.com/
[Bundler]: http://bundler.io/
[jekyll-docker]: https://github.com/egor-tensin/jekyll-docker
[jekyll-theme]: https://github.com/egor-tensin/jekyll-theme

### Access via file://

Jekyll doesn't provide native support for generating a static website which can
be browsed without running an instance of Jekyll's web server.
One easy workaround is to `wget` the website and convert the links:

    wget --no-verbose --recursive --convert-links --adjust-extension -- http://localhost:4000/

License
-------

Distributed under the MIT License.
See [LICENSE.txt] for details.

[LICENSE.txt]: LICENSE.txt
