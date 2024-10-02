#!/bin/bash

if [ -n "${settings.token}" ]; then
    git clone -b ${settings.branch} https://${settings.token}@github.com/${settings.repo}.git /home/jelastic/app
else
    git clone -b ${settings.branch} https://github.com/${settings.repo}.git /home/jelastic/app
fi