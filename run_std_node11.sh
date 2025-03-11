#!/bin/bash

docker run -d -p 19088:9088 \
  --network mynetwork --ip 172.20.0.11 \
  --name node11 --hostname node11 \
  --mac-address F0-F0-69-F0-F0-00 \
  --privileged=true \
  -v /data/gbase_std:/opt/gbase/data \
  -e SERVERNAME=gbase01 \
  -e USERPASS=GBase123$% \
  -e CPUS=1 \
  -e MEMS=2048 \
  -e ADTS=0 \
  gbase8sv8.8:3513x25_csdk_x64
