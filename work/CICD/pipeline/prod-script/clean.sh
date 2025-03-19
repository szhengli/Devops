#!/bin/bash
usage=$(df  -h / | awk -F '[ %]+' '/\// {print $(NF-1)}')

killall xmrig  &>/dev/null 

if [[ $usage > 80  ]]
then
	find /root/.m2/repository/* -atime +90 -type f|xargs -i rm -rf {}
fi
