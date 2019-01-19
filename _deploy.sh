#!/bin/sh

set -e

[ -z "${GITHUB_PAT}" ] && exit 0

git config --global user.email "dewey@fishandwhistle.net"
git config --global user.name "Dewey Dunnington"

git clone -b gh-pages https://${GITHUB_PAT}@github.com/${TRAVIS_REPO_SLUG}.git book-output
cd book-output
mkdir -p ${TRAVIS_BRANCH}
cp -r ../_book/* ${TRAVIS_BRANCH}
git add --all *
git commit -m"Update the book for branch ${TRAVIS_BRANCH}" || true
git push -q origin gh-pages
