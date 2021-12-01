#!/bin/bash

Hostname=$(echo $HOSTNAME | sed -e "s/.local/${replace}/g")
Username=$(id -F)

echo "${Hostname} :: ${Username}"
