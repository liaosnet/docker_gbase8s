#!/bin/bash
###########################################################
# FILENAME: docker_entrypoint.sh
# FUNCTION: init_start / stop docker
# WRITE BY: liaosnet@gbasedbt.com 2024-04-02
# UPDATE  : 2025-03-10
###########################################################
export LANG=C
_loginfo(){
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

_checkstatus(){
  su - gbasedbt -c "onstat -" >/dev/null 2>&1
  LASTSTATUS=$?
  sleep 2
  su - gbasedbt -c "onstat -" >/dev/null 2>&1
  CURRSTATUS=$?
  if [ ! ${LASTSTATUS} -eq ${CURRSTATUS} ]; then
    _loginfo "DATABASE STATUS CHANGE! LAST STATUS: ${LASTSTATUS}, CURRENT: ${CURRSTATUS}."
  fi
}

stop(){
  _loginfo "Stop database server."
  su - gbasedbt -c "onmode -ky"
  exit 0
}

trap "stop" SIGTERM

init_start(){
# user password
USERPASS=${USERPASS:-GBase123$%}
echo "gbasedbt:${USERPASS}" | chpasswd
_loginfo "Use password : ${USERPASS}"

# dbservername
SERVERNAME=${SERVERNAME:-gbase01}
_loginfo "GBASEDBTSERVER : ${SERVERNAME}"
HADINIT=1

# cpu mem
SYSCPU=$(awk '/^processor/{p++}END{print p}' /proc/cpuinfo)
SYSMEM=$(awk '/^MemTotal:/{printf("%d",$(NF-1)/1024)}' /proc/meminfo)
ENVCPU=${CPUS:-1}
ENVMEM=${MEMS:-2048}
ENVADT=${ADTS:-0}
if [ ${SYSCPU:-1} -le ${ENVCPU} ]; then
  ENVCPU=${SYSCPU}
fi
if [ ${ENVCPU} -lt 1 ]; then
  ENVCPU=1
fi
_loginfo "Number of cpus used: ${ENVCPU}"
if [ ${SYSMEM:-2048} -le ${ENVMEM} ]; then
  ENVMEM=${SYSMEM}
fi
if [ ${ENVMEM} -lt 1024 ]; then
  _loginfo "Memory less then 1024 MB, exit."
  exit 1 
fi
_loginfo "Number of memory used: ${ENVMEM} MB"
if [ ${ENVADT} -eq 1 ]; then
  _loginfo "Database start with audit."
  sed -i "s#^ADTMODE.*#ADTMODE 7#g" /opt/gbase/aaodir/adtcfg
else
  sed -i "s#^ADTMODE.*#ADTMODE 0#g" /opt/gbase/aaodir/adtcfg
fi

# for cluster hac, accept: standard|primary|secondary
ENVMODE=${MODE:-standard}
ENVLOCALIP=${LOCALIP:-0.0.0.0}
ENVPAIREIP=${PAIREIP:-172.20.0.22}
ENVPAIRENAME=${PAIRENAME:-gbase02}
if [ ! x"${ENVMODE}" = "xprimary" -a ! x"${ENVMODE}" = "xsecondary" ]; then
  ENVMODE="standard"
fi
_loginfo "ENVMODE is ${ENVMODE}"
if [ x"${ENVPAIRENAME}" = x"${SERVERNAME}" ]; then
  _loginfo "Servername and Paireaname need to be defferent!"
  exit 1
fi
if [ ! x"${ENVMODE}" = "xstandard" ]; then
  _loginfo "SERVERNAME is ${SERVERNAME}, and PAIRENAME is ${ENVPAIRENAME}"
fi
# for cluster hac end.

if [ -d /opt/gbase/data ]; then
  chown gbasedbt:gbasedbt /opt/gbase/data
  chmod 755 /opt/gbase/data
fi

_loginfo "Unarchive datafiles."
if [ ! -f /opt/gbase/data/rootchk ]; then
  if [ -f /opt/gbase/temp/data.tar.gz ]; then
    tar -zxf /opt/gbase/temp/data.tar.gz -C /opt/gbase/data/
  fi
  HADINIT=0
fi

_loginfo "Optimize parameters for Database."
CFGFILE=/opt/gbase/etc/onconfig.gbase01
sed -i "s/^VPCLASS cpu.*/VPCLASS cpu,num=${ENVCPU}/g" $CFGFILE

if [ ${ENVMEM} -lt 2048 ]; then
  CFG_LOCKS=50000
  CFG_SHMVIRTSIZE=384000
  CFG_2KPOOL=20000
  CFG_16KPOOL=10000 
elif [ ${ENVMEM} -lt 4096 ]; then
  CFG_LOCKS=200000
  CFG_SHMVIRTSIZE=512000
  CFG_2KPOOL=50000
  CFG_16KPOOL=20000 
elif [ ${ENVMEM} -le 8192 ]; then
  MUTI=$(expr ${ENVMEM} / 2000)
  [ $MUTI -eq 0 ] && MUTI=1
  CFG_LOCKS=1000000
  CFG_SHMVIRTSIZE=512000
  CFG_2KPOOL=500000
  CFG_16KPOOL=100000
elif [ ${ENVMEM} -le 32768 ]; then
  MUTI=$(expr ${ENVMEM} / 8000)
  [ $MUTI -eq 0 ] && MUTI=2
  CFG_LOCKS=5000000
  CFG_SHMVIRTSIZE=$(awk -v n="$MUTI" 'BEGIN{print (n-1)*1024000}')
  CFG_2KPOOL=500000
  CFG_16KPOOL=$(awk -v n="$MUTI" 'BEGIN{print (n-1)*200000}')
else
  CFG_LOCKS=5000000
  CFG_SHMVIRTSIZE=4096000
  CFG_2KPOOL=1000000
  CFG_16KPOOL=1000000
fi
CFG_SHMADD=$(expr ${CFG_SHMVIRTSIZE:-1024000} / 4)
CFG_SHMTOTAL=$(expr ${ENVMEM} \* 900)

sed -i "s#^DS_TOTAL_MEMORY.*#DS_TOTAL_MEMORY 1024000#g" $CFGFILE
sed -i "s#^DS_NONPDQ_QUERY_MEM.*#DS_NONPDQ_QUERY_MEM 256000#g" $CFGFILE
if [ ${ENVMEM} -le 4096 ]; then
  sed -i "s#^DS_TOTAL_MEMORY.*#DS_TOTAL_MEMORY 128000#g" $CFGFILE
  sed -i "s#^DS_NONPDQ_QUERY_MEM.*#DS_NONPDQ_QUERY_MEM 32000#g" $CFGFILE
fi

# dynamic value
sed -i "s#^LOCKS.*#LOCKS ${CFG_LOCKS}#g" $CFGFILE
sed -i "s#^SHMVIRTSIZE.*#SHMVIRTSIZE ${CFG_SHMVIRTSIZE}#g" $CFGFILE
sed -i "s#^SHMADD.*#SHMADD ${CFG_SHMADD}#g" $CFGFILE
sed -i "s#^SHMTOTAL.*#SHMTOTAL ${CFG_SHMTOTAL}#g" $CFGFILE
sed -i "s#^BUFFERPOOL.*size=2.*#BUFFERPOOL size=2K,buffers=${CFG_2KPOOL},lrus=32,lru_min_dirty=50,lru_max_dirty=60#g" $CFGFILE
sed -i "s#^BUFFERPOOL.*size=16.*#BUFFERPOOL size=16K,buffers=${CFG_16KPOOL},lrus=128,lru_min_dirty=50,lru_max_dirty=60#g" $CFGFILE

_loginfo "Change GBASEDBTSERVER to ${SERVERNAME}"
sed -i "s#^DBSERVERNAME.*#DBSERVERNAME ${SERVERNAME}#g" $CFGFILE
sed -i "s#^export GBASEDBTSERVER.*#export GBASEDBTSERVER=${SERVERNAME}#g" /home/gbase/.bash_profile

if [ ! x"${ENVMODE}" = "xstandard" ]; then
  sed -i "s#^DRAUTO.*#DRAUTO 1#g" $CFGFILE
  sed -i "s#^HA_ALIAS.*#HA_ALIAS ${SERVERNAME}#g" $CFGFILE
  sed -i "s#^REMOTE_SERVER_CFG.*#REMOTE_SERVER_CFG host.trust#g" $CFGFILE
  if [ ! -f /opt/gbase/etc/host.trust ]; then
    echo "+ gbasedbt" > /opt/gbase/etc/host.trust
    chown gbasedbt:gbasedbt /opt/gbase/etc/host.trust
    chmod 644 /opt/gbase/etc/host.trust
  fi

  if [ ! -f /opt/gbase/etc/sqlhosts ]; then
    _loginfo "Build GBASEDBTSQLHOSTS."
    if [ x"${ENVMODE}" = "xprimary" ]; then
      cat <<EOF > /opt/gbase/etc/sqlhosts
gdb	group		-		-	i=1,e=${ENVPAIRENAME}
${SERVERNAME}	onsoctcp	${LOCALIP}	9088	g=gdb
${ENVPAIRENAME}	onsoctcp	${PAIREIP}	9088	g=gdb
EOF
    else
      cat <<EOF > /opt/gbase/etc/sqlhosts
gdb	group           -               -       i=1,e=${SERVERNAME}
${ENVPAIRENAME}	onsoctcp        ${PAIREIP}      9088    g=gdb
${SERVERNAME}	onsoctcp        ${LOCALIP}      9088    g=gdb
EOF
    fi
    chown gbasedbt:gbasedbt /opt/gbase/etc/sqlhosts
    chmod 644 /opt/gbase/etc/sqlhosts
  fi 
else
  if [ ! -f /opt/gbase/etc/sqlhosts ]; then
    echo "${SERVERNAME} onsoctcp 0.0.0.0 9088" > /opt/gbase/etc/sqlhosts
    chown gbasedbt:gbasedbt /opt/gbase/etc/sqlhosts
    chmod 644 /opt/gbase/etc/sqlhosts
  fi
fi

# check owner for oninit
ONOWNER=$(ls -al /opt/gbase/bin/oninit | awk '{print $3}')
ONGROUP=$(ls -al /opt/gbase/bin/oninit | awk '{print $4}')
if [ x"$ONOWNER" = xroot -a x"$ONGROUP" = xgbasedbt ]; then
  _loginfo "Check owner and group for oninit."  
else
  _loginfo "Change owner and group for software."
  cd /opt/gbase && sh RUNasroot.installserver >/dev/null 2>&1
  cd /opt/gbase && find . -nouser | xargs chown gbasedbt:gbasedbt
  cd /home && chown -R gbasedbt:gbasedbt gbase 2>/dev/null
fi

# start server
if [ x"${ENVMODE}" = "xstandard" ]; then
  su - gbasedbt -c "oninit -vy"
  _loginfo "Start database as standard mode."  
else
  if [ ${HADINIT} -eq 1 ]; then
    su - gbasedbt -c "oninit -vy"
    _loginfo "Normal start as cluster mode."
  else
    if [ x"${ENVMODE}" = "xprimary" ]; then
      _loginfo "Start database as primary mode."
      su - gbasedbt -c "oninit -vy"
      DBSTATUS=$(su - gbasedbt -c "onstat -|grep 'On-Line'|wc -l")
      while [ ${DBSTATUS} -eq 0 ]
      do
        sleep 3
        DBSTATUS=$(su - gbasedbt -c "onstat -|grep 'On-Line'|wc -l")
      done
      _loginfo "Change mode to PRIMARY."
      su - gbasedbt -c "onmode -d primary ${ENVPAIRENAME}"
    else
      _loginfo "Start database as secondary mode."
      su - gbasedbt -c "oninit -PHY"
      DBSTATUS=$(su - gbasedbt -c "onstat -|grep 'Fast Recovery'|wc -l")
      while [ ${DBSTATUS} -eq 0 ]
      do
        sleep 3
        DBSTATUS=$(su - gbasedbt -c "onstat -|grep 'Fast Recovery'|wc -l")
      done
      _loginfo "Add database to cluster as secondary mode."
      su - gbasedbt -c "onmode -d secondary ${ENVPAIRENAME}"
    fi
  fi
fi
}

init_start

while true :
do
  _checkstatus
done
