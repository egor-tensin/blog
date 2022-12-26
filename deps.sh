#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
shopt -s inherit_errexit lastpipe

rbenv install --skip-existing "$( cat .ruby-version )"
rbenv rehash

gem install bundler -v "$( tail -n 1 Gemfile.lock )"
rbenv rehash

bundle install
rbenv rehash

pyenv install --skip-existing "$( cat .python-version )"
pyenv rehash

pip install -r requirements.txt
pyenv rehash
