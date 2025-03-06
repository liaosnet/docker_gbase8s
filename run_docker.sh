#!/bin/bash

docker run -d -p 19088:9088 \
  --name node01 --hostname node01 \
  -e SERVERNAME=gbase01 \
  -e USERPASS=GBase123$% \
  -e CPUS=1 \
  -e MEMS=2048 \
  -e ADTS=0 \
  liaosnet/gbase8s:v8.8_3513x25_csdk_x64
