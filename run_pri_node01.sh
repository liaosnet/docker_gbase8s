#!/bin/bash

docker run -d -p 19188:9088 \
  --network mynetwork --ip 172.20.0.21 \
  --name node01 --hostname node01 \
  --privileged=true \
  -v /data/gbase_pri:/opt/gbase/data \
  -e SERVERNAME=gbase01 \
  -e MODE=primary \
  -e LOCALIP=172.20.0.21 \
  -e PAIRENAME=gbase02 \
  -e PAIREIP=172.20.0.22 \
  -e USERPASS=GBase123$% \
  -e CPUS=1 \
  -e MEMS=2048 \
  -e ADTS=0 \
  gbase8sv8.8:3513x25_csdk_x64
