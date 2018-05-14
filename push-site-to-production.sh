#!/bin/bash

read -p "Are you sure you want to push this site to production? [yN] " -n 1 -r
echo # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  
  if [ -d $PWD/trophy-jekyll/_site]; then
    rm -rf $PWD/trophy-jekyll/_site  
  fi

  docker-compose restart
  cd $PWD/trophy-jekyll/_site
  git init . &&
  git remote add origin https://github.com/maxwenger/maxwenger.github.io
  
  git fetch &&
  git add . &&
  git commit -m "Pushed to production" &&
  git push -f origin master 
fi
