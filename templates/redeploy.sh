#!/bin/bash
# change master to main if main is your deploy branch
git pull -f origin master   #(OR git pull --ff-only)
npm install                #(OR yarn install)
pm2 reload all
pm2 save