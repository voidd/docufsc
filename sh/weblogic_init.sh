#!/bin/sh
#
# chkconfig: - 99 01
# description: Starts and stops the Weblogic Application Server

startManagedServers() {
  if [ -r ${USER_CONFIG_FILE} ] && [ -r ${USER_KEY_FILE} ] && [ x${ADMIN_SERVER_URL} != x ] && [ ! -f ${DOMAIN_HOME}/bin/startup.py ]; then
    cat > ${DOMAIN_HOME}/bin/startup.py <<__EOF__
connect(userConfigFile='${USER_CONFIG_FILE}',userKeyFile='${USER_KEY_FILE}',url='${ADMIN_SERVER_URL}')
svrs = cmo.getServers()
domainRuntime()
for server in svrs:
  if server.getName() != '${WEBLOGIC_SERVER}':
    cd('/ServerLifeCycleRuntimes/' + server.getName() )
    serverState = cmo.getState()
    if serverState != 'RUNNING':
      start(server.getName(),'Server',block='false')
disconnect()
exit()
__EOF__
  fi

  if [ -r ${DOMAIN_HOME}/bin/startup.py ]; then
    ${WL_HOME}/wlserver_10.3/common/bin/wlst.sh ${DOMAIN_HOME}/bin/startup.py </dev/null >/dev/null 2>&1
  fi
}

stopManagedServers() {
  if [ -r ${USER_CONFIG_FILE} ] && [ -r ${USER_KEY_FILE} ] && [ x${ADMIN_SERVER_URL} != x ] && [ ! -f ${DOMAIN_HOME}/bin/shutdown.py ]; then
    cat > ${DOMAIN_HOME}/bin/shutdown.py <<__EOF__
connect(userConfigFile='${USER_CONFIG_FILE}',userKeyFile='${USER_KEY_FILE}',url='${ADMIN_SERVER_URL}')
svrs = cmo.getServers()
domainRuntime()
for server in svrs:
  if server.getName() != '${WEBLOGIC_SERVER}':
    cd('/ServerLifeCycleRuntimes/' + server.getName() )
    serverState = cmo.getState()
    if serverState != 'SHUTDOWN':
      shutdown(server.getName(),'Server','true',1000,force='true',block='false')
disconnect()
exit()
__EOF__
  fi

  if [ -r ${DOMAIN_HOME}/bin/shutdown.py ]; then
    ${WL_HOME}/wlserver_10.3/common/bin/wlst.sh ${DOMAIN_HOME}/bin/shutdown.py </dev/null >/dev/null 2>&1
  fi
}



# Source function library.
if [ -f /etc/init.d/functions ]; then
  . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ]; then
  . /etc/rc.d/init.d/functions
else
  exit 0
fi

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "${NETWORKING}" = "yes" ] || exit 0

# Find the name of the script
NAME=`basename $0`
if [ ${NAME:0:1} = "S" -o ${NAME:0:1} = "K" ]; then
  NAME=${NAME:3}
fi
NAME=${NAME##weblogic_}

# For SELinux we need to use 'runuser' not 'su'
if [ -x /sbin/runuser ]; then
  SU=runuser
else
  SU=su
fi

if [ -f /etc/sysconfig/weblogic/${NAME} ]; then
  . /etc/sysconfig/weblogic/${NAME}
fi

#if [ -r ${DOMAIN_HOME}/servers/${WEBLOGIC_SERVER}/data/nodemanager/${WEBLOGIC_SERVER}.url ]; then
#  ADMIN_SERVER_URL=${ADMIN_SERVER_URL-`cat ${DOMAIN_HOME}/servers/${WEBLOGIC_SERVER}/data/nodemanager/${WEBLOGIC_SERVER}.url`}
#fi
USER_CONFIG_FILE=${USER_CONFIG_FILE-$DOMAIN_HOME/security/localConfigFile}
USER_KEY_FILE=${USER_KEY_FILE-$DOMAIN_HOME/security/localUserKey}

RETVAL=0

startAdminServer() {
  echo -n $"Starting WebLogic service: "

  START_CMD="linux32 nohup ${WL_HOME}/wlserver_10.3/common/bin/wlscontrol.sh"
  START_CMD="${START_CMD} -d ${WEBLOGIC_DOMAIN} -s ${WEBLOGIC_SERVER} -r ${DOMAIN_HOME} -c -f ${START_SCRIPT} START"
  START_CMD="${START_CMD} </dev/null >/dev/null 2>&1"

  if [ `id -u` = 0 ]; then
    $SU $WEBLOGIC_USER -c -p "${START_CMD}"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
      touch /var/lock/subsys/weblogic_${NAME}
    fi
  else
    ${START_CMD}
    RETVAL=$?
  fi

  sleep 20
  echo
  return $RETVAL
}

startNodeManager() {
  echo -n $"Starting WebLogic service: "

  START_CMD="nohup ${WL_HOME}/wlserver_10.3/server/bin/startNodeManager.sh"
  START_CMD="${START_CMD} </dev/null >/dev/null 2>&1 &"

  if [ `id -u` = 0 ]; then
    $SU $WEBLOGIC_USER -c -p "${START_CMD}"
    RETVAL=$?
  else
    ${START_CMD}
    RETVAL=$?
  fi

  echo
  return $RETVAL
}


stopAdminServer() {
  echo -n $"Shutting down WebLogic service: "

  STOP_CMD="linux32 ${WL_HOME}/wlserver_10.3/common/bin/wlscontrol.sh"
  STOP_CMD="${STOP_CMD} -d ${WEBLOGIC_DOMAIN} -s ${WEBLOGIC_SERVER} -r ${DOMAIN_HOME} KILL"
  STOP_CMD="${STOP_CMD} </dev/null >/dev/null 2>&1"

  if [ `id -u` = 0 ]; then
    $SU $WEBLOGIC_USER -c -p "${STOP_CMD}"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
      rm -f /var/lock/subsys/weblogic_${NAME}
    fi
  else
    ${STOP_CMD}
    RETVAL=$?
  fi

  echo
  return $RETVAL
}

restart() {
  stopManagedServers
  stopAdminServer
  startAdminServer
  startManagedServers
}


case "$1" in
  start)
    startNodeManager
    startAdminServer
    startManagedServers
    ;;
  stop)
    stopManagedServers
    stopAdminServer
    ;;
  restart)
    restart
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?