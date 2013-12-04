#!/bin/bash 
#
# $Id: gi_profile.sh 819 2013-07-17 18:10:26Z tbr $
# 
set_env()
{
	OLR_CFG=/etc/oracle/olr.loc
	ORATAB=/etc/oratab
	CRS_STATFILTER="((STATE = OFFLINE) OR (STATE = INTERMEDIATE)) AND (TYPE != ora.ons.type) AND (TYPE != ora.gsd.type) AND (AUTO_START != never)"

	CRS_HOME=`grep "^crs_home" ${OLR_CFG} | cut -d"=" -f2`
	ORACLE_HOME=${CRS_HOME}
	CRSCTL=${ORACLE_HOME}/bin/crsctl
	OLSNODES=${ORACLE_HOME}/bin/olsnodes

	LOCALNODE=`${OLSNODES} -l`

	alertlog=${ORACLE_HOME}/log/${LOCALNODE}/alert${LOCALNODE}.log

	ORACLE_SID=`grep ":${ORACLE_HOME}:" ${ORATAB} | grep "^+ASM"|cut -d":" -f1`

	PATH=${PATH}:${ORACLE_HOME}/bin

	export ORACLE_SID ORACLE_HOME PATH
}

create_aliases()
{
	alias cstat="${CRSCTL} stat res -t"
	alias ginotonline="${CRSCTL} stat res -t -w "\"${CRS_STATFILTER}\"
	alias sqasm="sqlplus / as sysasm"
	alias tal="less ${alertlog}"

	alias kfoddiskall='kfod disks=all status=TRUE dscvgroup=TRUE verbose=TRUE asm_diskstring='
}

set_env
create_aliases
