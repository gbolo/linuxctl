#!/bin/bash

# nfcapd should start like this:
# nfcapd -p12345 -x "/opt/scripts/nfdump-to-es.sh %f edge_to" -t 60 -s 1000 -z -w -e -T all,-10,-11,-12,-13,-14 -D -l /dev/shm/edge_to

base_dir='/dev/shm'
index_pre=$2
index_date=`date +"%F"`
es_ip='127.0.0.1'

# generate data
nfdump -qr ${base_dir}/${index_pre}/$1 -o "fmt:{ \"create\": { \"_index\": \"netflow_${index_pre}-${index_date}\", \"_type\": \"netflow\"}}\n{\"start_time\": \"%ts\", \"src_ip\": \"%sa\", \"src_port\": \"%sp\", \"dst_ip\": \"%da\", \"dst_port\": \"%dp\", \"bytes\": \"%byt\", \"packets\": \"%pkt\", \"if_in\": \"%in\", \"if_out\": \"%out\", \"protocol\": \"%pr\", \"duration\": \"%td\", \"flows\": \"%fl\", \"bps\": \"%bps\", \"pps\": \"%pps\", \"bpp\": \"%bpp\", \"tos\": \"%tos\" }" | sed 's/
*" */"/g' | sed 's/\\n/\n/g' > ${base_dir}/${index_pre}/$1.json

# send to elasticsearch
curl -s -o /dev/null -XPOST ${es_ip}:9200/_bulk --data-binary @${base_dir}/${index_pre}/$1.json; 

# clean up
rm -f ${base_dir}/${index_pre}/$1.json
rm -f ${base_dir}/${index_pre}/$1
