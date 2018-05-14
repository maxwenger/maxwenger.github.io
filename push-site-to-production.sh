#!/bin/bash

JEKYLL-DIR=./trophy-jekyll
COMMIT-MESSAGE='Pushed to production.'
REMOTE-REPOSITORY-URL='https://github.com/maxwenger/maxwenger.github.io'
PRODUCTION-BRANCH='gh-pages'

read -p "Are you sure you want to push this site to production? [yN] " -n 1 -r
echo # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  docker-compose restart
  cd $JEKYLL-DIR/_site
  git init . &&
  git add . &&
  git commit -m $COMMIT-MESSAGE &&
  git remote add origin $REMOTE-REPOSITORY-URL &&
  git checkout $PRODUCTION-BRANCH &&
  git push origin $PRODUCTION-BRANCH ||
  return 1 
fi
