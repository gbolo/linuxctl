#!/bin/bash

# nfcapd should start like this:
# nfcapd -p12345 -x "/opt/scripts/nfdump-to-logstash.sh %f edge_to" -t 60 -s 1000 -z -w -e -T all,-10,-11,-12,-13,-14 -D -l /dev/shm/edge_to

base_dir='/dev/shm'
index_pre=$2
index_date=`date +"%F"`
ls_ip='127.0.0.1'

# generate data
nfdump -qr ${base_dir}/${index_pre}/$1 -o "pipe" | nc -w 1 -u $ls_ip 12401


# clean up
rm -f ${base_dir}/${index_pre}/$1

