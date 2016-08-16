#!/bin/bash

s=`date +%s`
echo "docker.images $s `docker images -q|wc -l`"
echo "docker.contatiners.active $s `docker ps -q|wc -l`"
echo "docker.contatiners.all $s `docker ps -a -q|wc -l`"