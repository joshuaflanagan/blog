source "https://rubygems.org"

gem "jekyll"

## From http://jekyllrb.com/docs/github-pages/
require 'json'
require 'open-uri'
versions = JSON.parse(open('https://pages.github.com/versions.json').read)
gem 'github-pages', versions['github-pages']
##
