# $Id: oradb_resource_restart.sh 1063 2013-11-23 17:26:51Z tbr $
#
# Database
ORACLE_SID=trac1
ORACLE_SHUTDOWN_MODE=abort
ORACLE_STARTUP_MODE=MOUNT
DG_DEPENDENCIES="ora.GRID.dg"

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
"ATTRIBUTE=STARTUP_MODE,TYPE=STRING,FLAGS=REQUIRED",\
"ATTRIBUTE=SHUTDOWN_MODE,TYPE=STRING,FLAGS=REQUIRED"

}
#############################################################################################
delete_all() {
echo "#######################################"
echo "        delete_all"
echo "#######################################"
	crsctl delete resource ${ORACLE_SID}.oracledb -f
	crsctl delete type oracledb.type
}



#############################################################################################
add_resources(){
echo "#######################################"
echo "        add_resources"
echo "#######################################"

crsctl add res ${ORACLE_SID}.oracledb \
 -type oracledb.type \
-attr "ORACLE_SID=${ORACLE_SID}",\
"STARTUP_MODE=${ORACLE_STARTUP_MODE}",\
"SHUTDOWN_MODE=${ORACLE_SHUTDOWN_MODE}"
}

#############################################################################################
add_dependencies(){
echo "#######################################"
echo "        add_dependencies"
echo "#######################################"

crsctl modify res ${ORACLE_SID}.oracledb \
-attr "START_DEPENDENCIES='hard(${DG_DEPENDENCIES}) pullup:always(${DG_DEPENDENCIES})'",\
"STOP_DEPENDENCIES='hard(${DG_DEPENDENCIES})'"

}

#############################################################################################

delete_all
create_types
add_resources
add_dependencies

