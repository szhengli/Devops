#!/bin/bash
 echo "random: ${RANDOM}"
 exec kopf run --priority ${RANDOM} /src/eph.py --verbose