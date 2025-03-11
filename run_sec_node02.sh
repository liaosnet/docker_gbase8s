#!/bin/bash

docker run -d -p 19288:9088 \
  --network mynetwork --ip 172.20.0.22 \
  --name node02 --hostname node02 \
  --mac-address F0-F0-69-F0-F0-02 \
  --privileged=true \
  -v /data/gbase_sec:/opt/gbase/data \
  -e SERVERNAME=gbase02 \
  -e MODE=secondary \
  -e LOCALIP=172.20.0.22 \
  -e PAIRENAME=gbase01 \
  -e PAIREIP=172.20.0.21 \
  -e USERPASS=GBase123$% \
  -e CPUS=1 \
  -e MEMS=2048 \
  -e ADTS=0 \
  gbase8sv8.8:3513x25_csdk_x64
