#!/bin/bash
cd $(dirname "$0")/..
pm2 startOrReload deploy/pm2.config.js
