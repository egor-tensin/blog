Workspace setup
---------------

* To reduce pain, set up [rbenv] to manage your Ruby versions.
Install one that's known to work:

      make ruby

    * Otherwise, make sure you have Ruby and [Bundler] set up.

* Install dependencies:

      make deps

* Make sure builds are working:

      make build

[rbenv]: https://github.com/rbenv/rbenv
[Bundler]: https://bundler.io/

Development
-----------

* Build the website and serve it at http://localhost:4000/blog/:

      make serve

    * It will pick up changes and reload pages automatically.

Upgrading dependencies
----------------------

    bundle update

Building static pages
---------------------

If you try to copy the _site directory and open index.html without running the
web server, it won't work: all links will be messed up.
Jekyll doesn't provide native support for generating a static website which can
be browsed without running a web server.

One workaround is to `wget` the website:

    make serve LIVE_RELOAD=0    # Live reloading breaks wget
    make wget

The truly static version will be downloaded to the .wget/ directory.
