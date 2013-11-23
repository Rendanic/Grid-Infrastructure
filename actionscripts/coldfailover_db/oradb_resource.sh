# $Id: oradb_resource.sh 1042 2013-10-14 18:29:24Z tbr $
#
# Database
ORACLE_SID=trac1
ORACLE_OWNER=oracle
ORACLE_OSDBA=dba
ORACLE_SHUTDOWN_MODE=abort
DG_DEPENDENCIES="ora.GRID.dg"

# VIP
VIP_NAME=${ORACLE_SID}.vip
VIP_IP=192.168.100.29

# Listener
LISTENER_NAME=${ORACLE_SID}

# Wichtige Infos:
 
# Attribute einer Resource ändern:
# crsctl modify resource <Resource> -attr "ENABLED=0"

# FAILURE_THRESHOLD=1
# => Resource wird NICHT auf einen anderen Knoten verschoben.
#
# RESTART_ATTEMPTS
# => Wie häufig soll die Resource restartet werden?
# => Nach Anzahl versuchen wird ein Failover initiiert, wenn FAILURE_THRESHOLD >= 2
#
# ENABLED=0
# => Resource wird nicht mehr gestart, kann weiterhin noch laufen und gestoppt werden

#############################################################################################
create_types(){
echo "#######################################"
echo "        create_types"
echo "#######################################"

crsctl add type  listener.type \
-basetype ora.cluster_resource.type \
-attr "ATTRIBUTE=CHECK_INTERVAL,TYPE=INT,DEFAULT_VALUE=120",\
"ATTRIBUTE=OFFLINE_CHECK_INTERVAL,TYPE=INT,DEFAULT_VALUE=1800",\
"ATTRIBUTE=SCRIPT_TIMEOUT,TYPE=INT,DEFAULT_VALUE=30",\
"ATTRIBUTE=CARDINALITY,TYPE=STRING,DEFAULT_VALUE=1",\
"ATTRIBUTE=ACTIVE_PLACEMENT,TYPE=INT,DEFAULT_VALUE=1",\
"ATTRIBUTE=STOP_TIMEOUT,TYPE=INT,DEFAULT_VALUE=30",\
"ATTRIBUTE=START_TIMEOUT,TYPE=INT,DEFAULT_VALUE=30",\
"ATTRIBUTE=RESTART_ATTEMPTS,TYPE=INT,DEFAULT_VALUE=2",\
"ATTRIBUTE=FAILURE_THRESHOLD,TYPE=INT,DEFAULT_VALUE=2",\
"ATTRIBUTE=FAILURE_INTERVAL,TYPE=INT,DEFAULT_VALUE=10",\
"ATTRIBUTE=UPTIME_THRESHOLD,TYPE=STRING,DEFAULT_VALUE=10m",\
"ATTRIBUTE=ACTION_SCRIPT,TYPE=STRING,DEFAULT_VALUE=$ORACLE_HOME/crs/public/action_listener_failover.sh",\
"ATTRIBUTE=DESCRIPTION,TYPE=STRING,DEFAULT_VALUE=Listener Resource",\
"ATTRIBUTE=PLACEMENT,TYPE=STRING,DEFAULT_VALUE=balanced",\
"ATTRIBUTE=LISTENER_NAME,TYPE=STRING,FLAGS=REQUIRED"



crsctl add type  oracledb.type \
-basetype ora.cluster_resource.type \
-attr "ATTRIBUTE=CHECK_INTERVAL,TYPE=INT,DEFAULT_VALUE=120",\
"ATTRIBUTE=OFFLINE_CHECK_INTERVAL,TYPE=INT,DEFAULT_VALUE=1800",\
"ATTRIBUTE=SCRIPT_TIMEOUT,TYPE=INT,DEFAULT_VALUE=30",\
"ATTRIBUTE=CARDINALITY,TYPE=STRING,DEFAULT_VALUE=1",\
"ATTRIBUTE=ACTIVE_PLACEMENT,TYPE=INT,DEFAULT_VALUE=1",\
"ATTRIBUTE=STOP_TIMEOUT,TYPE=INT,DEFAULT_VALUE=300",\
"ATTRIBUTE=START_TIMEOUT,TYPE=INT,DEFAULT_VALUE=300",\
"ATTRIBUTE=RESTART_ATTEMPTS,TYPE=INT,DEFAULT_VALUE=2",\
"ATTRIBUTE=FAILURE_THRESHOLD,TYPE=INT,DEFAULT_VALUE=2",\
"ATTRIBUTE=FAILURE_INTERVAL,TYPE=INT,DEFAULT_VALUE=10",\
"ATTRIBUTE=UPTIME_THRESHOLD,TYPE=STRING,DEFAULT_VALUE=10m",\
"ATTRIBUTE=ACTION_SCRIPT,TYPE=STRING,DEFAULT_VALUE=$ORACLE_HOME/crs/public/action_oradb_failover.sh",\
"ATTRIBUTE=DESCRIPTION,TYPE=STRING,DEFAULT_VALUE=Database Failover Resource",\
"ATTRIBUTE=PLACEMENT,TYPE=STRING,DEFAULT_VALUE=balanced",\
"ATTRIBUTE=ORACLE_SID,TYPE=STRING,FLAGS=REQUIRED",\
"ATTRIBUTE=SHUTDOWN_MODE,TYPE=STRING,FLAGS=REQUIRED"

}
#############################################################################################
delete_all() {
echo "#######################################"
echo "        delete_all"
echo "#######################################"
	crsctl delete resource ${ORACLE_SID}.oracledb -f
	crsctl delete type oracledb.type
	crsctl delete resource ${LISTENER_NAME}.listener
	crsctl delete type listener.type
	appvipcfg delete -vipname=${VIP_NAME}
}



#############################################################################################
add_resources(){
echo "#######################################"
echo "        add_resources"
echo "#######################################"

appvipcfg create -network=1 -ip=${VIP_IP} -vipname=${VIP_NAME} -user=${ORACLE_OWNER} -failback=0

crsctl add res ${LISTENER_NAME}.listener \
 -type listener.type \
-attr "LISTENER_NAME=${LISTENER_NAME}",\
"ACL='owner:${ORACLE_OWNER}:rwx,pgrp:${ORACLE_OSDBA}:r--,other::r--'"

crsctl add res ${ORACLE_SID}.oracledb \
 -type oracledb.type \
-attr "ORACLE_SID=${ORACLE_SID}",\
"ACL='owner:${ORACLE_OWNER}:rwx,pgrp:${ORACLE_OSDBA}:r--,other::r--'".\
"SHUTDOWN_MODE=${ORACLE_SHUTDOWN_MODE}"
}

#############################################################################################
add_dependencies(){
echo "#######################################"
echo "        add_dependencies"
echo "#######################################"

crsctl modify res ${ORACLE_SID}.oracledb \
-attr "START_DEPENDENCIES='hard(${DG_DEPENDENCIES},${LISTENER_NAME}.listener) pullup:always(${LISTENER_NAME}.listener,${DG_DEPENDENCIES})'",\
"STOP_DEPENDENCIES='hard(${LISTENER_NAME}.listener,${DG_DEPENDENCIES})'"

crsctl modify res ${LISTENER_NAME}.listener \
-attr "START_DEPENDENCIES='hard(${VIP_NAME}) pullup:always(${VIP_NAME})'",\
"STOP_DEPENDENCIES='hard(${VIP_NAME})'"

}

#############################################################################################

delete_all
create_types
add_resources
add_dependencies

