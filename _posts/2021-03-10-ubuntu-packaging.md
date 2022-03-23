---
title: Basic Ubuntu packaging
excerpt: >
  Packaging your software to be published in a PPA for the first time is a
  pain.
snippets_root_directory: snippets/ubuntu_packaging
snippets_language: plain
snippets:
  basic:
    - basic/changelog
    - basic/control
    - basic/copyright
    - basic/rules
  install:
    - install/test.install
  gbp:
    - gbp/gbp.conf
---
It took me about an hour to make a PKGBUILD for my simple, non-compiled
piece of software to be published on [AUR].
In contrast, it took me a few days to figure out how to build suitable .deb
packages for publishing in a PPA on [Launchpad].
In this post, I'll try to describe some of the initial pain points of mine.

[AUR]: https://aur.archlinux.org/
[Launchpad]: https://launchpad.net/

Basics
------

The Debian package format is really old, and it shows.
There's a billion of metadata files to take care of, and barely any suitable
tutorials for beginners.
At best, you'll learn how to build _binary_ packages, not suitable for
publishing in a PPA (which only accept _source_ packages and builds the
binaries itself).

First, you need to realize that there are source packages and binary packages.
Binary packages are the .deb files that actually contain the software.
A source package is, confusingly, multiple files, and you need to submit them
all to Launchpad.
You can distribute binary packages directly to your users, but they would have
to fetch & install the new version manually every time there's an upgrade.
If you could set up a repository and just point the users to it, they would get
the new versions naturally via the package manager (`apt`).

Canonical's Launchpad provides a very handy PPA (Personal Package Archive)
service so that anyone can set up a repository.
Users could then use `add-apt-repository ppa:...` and get the packages in a
standard and convenient way.

Tools
-----

There's a myriad of tools to build and maintain Debian packages.
The [Debian New Maintainers' Guide] provides a [short summary] of how these
tools interact.
This tutorial assumes that your software lives in a Git repository and you'd
like to use Git to maintain the packaging metadata in the same repository.
This process is greatly aided by the [git-buildpackage] tool.
We still need to install a bunch of other stuff though; the complete command
line to install the required tools would be something like

    sudo apt install -y build-essential devscripts dh-make git-buildpackage

Many of the tools pick up particular metadata (like the maintainer name and
email address) from environment variables.
You can put something like

    export DEBFULLNAME='John Doe'
    export DEBEMAIL='John.Doe@example.com'

in your .bashrc to set them globally.

[Debian New Maintainers' Guide]: https://www.debian.org/doc/manuals/maint-guide
[short summary]: https://www.debian.org/doc/manuals/maint-guide/build.en.html#hierarchy
[git-buildpackage]: http://honk.sigxcpu.org/projects/git-buildpackage/manual-html/gbp.html

Getting started
---------------

Let's create a repository to try things out.
It'll contain a single executable shell script test.sh, which only outputs the
string "test".

    mkdir test
    cd test
    git init
    cat <<'EOF' > test.sh
    #!/usr/bin/env bash
    echo test
    EOF
    chmod +x test.sh
    git add .
    git commit -m 'initial commit'

This is going to be version 1.0 of our project, let's tag it as such.

    git tag -a -m 'Release 1.0' v1.0

All of the Debian packaging tools are tailored to the following use-case.

1. There's an upstream distribution, which releases the software in tarballs.
2. There's a maintainer (who's not the software author), who takes care of
packaging and is disconnected from the development.

This disconnect means that maintaining the Debian packaging files in the
`master` branch is inconvenient using the existing tools.
At the very least, you should create a separate branch for doing packaging
work.

In addition, Debian (and hence, Ubuntu) is not a rolling-release distribution.
That means that there're regular releases, and the software version shouldn't
change too much during a lifetime of a single release.
Once Debian makes a release, the software version is more or less fixed, and
security fixes from future versions should be backported separately for each of
the supported Debian/Ubuntu releases.

Except there _is_ a rolling-release distribution of Debian, and it's called
"unstable" or "sid".
The bleeding-edge packaging work should target the "unstable" distribution.

So, let's create a new branch `debian` for our packaging work:

    git checkout -b debian

All the packaging tools assume there's a separate folder "debian" that contains
the package metadata files.
There's a handy tool `dh_make` that creates the directory and populates it with
a number of template metadata files.
Using it is not so simple though.
First of all, it assumes that there's a properly named tarball with the project
sources available in the parent directory.
Why?
Who knows.
Let's create said tarball:

    git archive --format=tar --prefix=test_1.0/ v1.0 | gzip -c > ../test_1.0.orig.tar.gz

The tarball name should follow the NAME_VERSION.orig.tar.gz pattern exactly!
Anyway, now is the time to run `dh_make`:

    dh_make --indep --copyright mit --packagename test_1.0 --yes

I'm using the MIT License for our little script, hence the `--copyright mit`
argument.
In addition, every package in Debian is either "single", "arch-independent",
"library" or "python".
I'm not sure what the exact differences between those are, but a shell script
is clearly CPU architecture-independent, hence the `--indep` argument.
If it was a compiled executable, it would be a "single" (`--single`) package.

`dh_make` created the "debian" directory for us, filled with all kinds of
files.
The only required ones are "changelog", "control", "source", "rules" and the
"source" directory.
Let's remove every other file for now:

    rm -f -- debian/*.ex debian/*.EX debian/README.* debian/*.docs

You can study the exact format of the metadata files in the [Debian New
Maintainers' Guide], but for now let's keep it simple:

{% include jekyll-theme/snippets/section.html section_id='basic' %}

The "control" and "copyright" files are fairly straighforward.
The "changelog" file has a strict format and is supposed to be maintained using
the `dch` tool (luckily, git-buildpackage helps with that; more on that later).

The "rules" file is an _executable_ Makefile, and actually controls how the
software is built.
Building a package involves invoking many predefined targets in this Makefile;
for now, we'll resort to delegating everything to the `dh` tool.
It's the Debhelper tool; it's a magic set of scripts that contain an
unbelievable amount of hidden logic that's supposed to aid package maintainers
in building the software.
For example, if the package is supposed to be built using the standard
`./configure && make && make install` sequence, it'll do this automatically.
If it's a Python package with setup.py, it'll use the Python package-building
utilities, etc.
We don't want any of that, we just want to copy test.sh to /usr/bin.
It can be taken care of using the `dh_install` script.
While building the package, it'll get executed by `dh`, read the
"debian/test.install" file and copy the files listed there to the specified
directories.
Our test.install should look like this:

{% include jekyll-theme/snippets/section.html section_id='install' %}

At this point, we can actually build a proper Debian package!

    dpkg-buildpackage -uc -us

This command will generate a bunch of files in the parent directory.
The one of interest to us is "test_1.0-1_all.deb".
We can install it using `dpkg`:

    sudo dpkg -i ../test_1.0-1_all.deb

We can now execute `test.sh`, and it'll hopefully print the string "test".

This .deb file can be distributed to other users, but is no good for uploading
to Launchpad.
For one, it's a binary package, and we need source packages for Launchpad to
build itself.
Second, it's unsigned, which is also a no-no.

I'm not going to describe how to set up a GnuPG key and upload it to the Ubuntu
keyserver (keyserver.ubuntu.com), but it's pretty straightforward once you know
the basics of GnuPG key handling.

One disadvantage of the `dpkg-buildpackage` tool is that it creates a lot of
files in the "debian" directory; their purpose is unclear to me.
For now, you can delete them, leaving only the original "changelog", "control",
"copyright", "rules", "test.install" and the "source" directory.

git-buildpackage
----------------

git-buildpackage is a wonderful tool that helps with managing the packaging
work in the upstream repository.
Please refer to its manual to learn how to use it properly.
We need to configure it so that it knows how the release tags look like
(`vVERSION`), how the packaging branch is called (`debian`) and where to put
the generated files.
Create "debian/gbp.conf" with the following contents:

{% include jekyll-theme/snippets/section.html section_id='gbp' %}

One unclear line here is `pristine-tar = False`.
It turns out, a lot of Debian package maintainers use the `pristine-tar` tool
to create "pristine", byte-for-byte reproducible tarballs of the upstream
software.
This is just more headache for us, so we're not going to use that;
git-buildpackage will just use the normal `git archive` to create tarballs.

First, commit the packaging work we just made:

    git add debian/
    git commit -m 'initial Debian release'

We can now build the package using git-buildpackage:

    gbp buildpackage

The tool will try to sign the packages, so this assumes that you have your
GnuPG key set up!

If all went right, it just built the packages in the ../build-area directory.
And it hasn't crapped all over the working directory too!
Similar to `dpkg-buildpackage`, it builds binary packages by default.
To build _source_ packages, it needs to be invoked with the `-S` argument:

    gbp buildpackage -S

It'll build the source package in the same directory (you'll notice a lot of
files having the "_source" suffix).
If all is well, we can tag the packaging work we've just completed:

    gbp buildpackage --git-tag-only

This will create the `debian/1.0-1` tag in the repository.

We are now ready to upload the source package to Launchpad.
It's done using the `dput` tool.
The naive way would fail:

    dput ppa:john-doe/test ../build-area/test_1.0-1_source.changes

This is due to the fact that we've specified that we're targetting the
"unstable" distribution in debian/changelog.
There's no "unstable" distribution of Ubuntu though; we need to manually
specify the minimal-supported version (e.g. "bionic"):

    dput ppa:john-doe/test/ubuntu/bionic ../build-area/test_1.0-1_source.changes

What about other distributions?
Well, if the binary package doesn't need recompiling, we can use Launchpad's
"Copy packages" feature; this is well-described in this [Ask Ubuntu question].

[Ask Ubuntu question]: https://askubuntu.com/q/23227/844205

New versions
------------

When a new version is released, git-buildpackage helps to integrate it to the
packaging branch.
Let's say the new version is tagged `v1.1`:

    git checkout debian
    git merge v1.1
    gbp dch

The above command will update debian/changelog; modify it manually to target
the usual "unstable" distribution instead of "UNRELEASED" and update the
version to something like "1.1-1".

    git add debian/
    git commit -m 'Debian release 1.1'
    gbp buildpackage -S

This will build the source package for the new version in the ../build-area
directory; you can then upload it Launchpad and copy the built binary packages.

Aftermath
---------

This fucking sucks.
What's the way to sanely manage the repository if the build/runtime
dependencies are different for different Ubuntu versions?
I have no idea.
Some pointers to help you understand what's going on in this tutorial more
deeply:

* [When upstream uses Git: Building Debian Packages with git-buildpackage](https://honk.sigxcpu.org/projects/git-buildpackage/manual-html/gbp.import.upstream-git.html)
* [Using Git for Debian packaging](https://www.eyrie.org/~eagle/notes/debian/git.html)

Good luck with this, because I'm definitely overwhelmed.
