#!/bin/bash
for PORT in {9999,8080,8090,9000};do
	result=`echo -e "\n" | telnet 127.0.0.1 $PORT 2> /dev/null | grep Connected | wc -l`
	if [ $result -eq 1 ]; then
	    echo "Network is Open."
    else
        echo bad
        exit 1
    fi
done
