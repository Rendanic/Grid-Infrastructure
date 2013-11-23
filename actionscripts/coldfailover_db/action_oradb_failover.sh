#!/bin/bash
#
# $Id: action_oradb_failover.sh 1041 2013-10-14 18:20:21Z tbr $
#
# Copyright 2013 (c) Thorsten Bruhns (tbruhns@gmx.de)
#
# _CRS_ORACLE_SID     	ORACLE_SID from Database
# _CRS_SHUTDOWN_MODE  	Shutdown-Mode from Resource-Configuration
# _CRS_STARTUP_MODE  	Startup-Mode from Resource-Configuration
# _CRS_ORACLE_BASE  	This parameter must be set for databases <=10.2
#
# ORACLE_HOME must be set in /etc/oratab, otherwise the database could not be started
#
# How could we handle a manualy mounted database who is not open?
# We try to stop the database with abort
# Check of database goes to OFFLINE and cluster try to start the database
# => 1st we do a shutdown abort and then a startup

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


set_env() {
	
	ORATAB=/etc/oratab

	if [ ${_CRS_ORACLE_SID:-"-1"} = "-1" ]
	then
		echo "_CRS_ORACLE_SID not set in clusterware environment."
		echo "aborting script!"
		exit 1
	else
		ORACLE_SID=${_CRS_ORACLE_SID}
	fi

	if [ ${_CRS_STARTUP_MODE:-"-1"} = "-1" ]
	then
		# use open as default when parameter is missing
		_CRS_STARTUP_MODE=OPEN
	fi

	# does the entry exists in oratab?
	ORACLE_HOME=$(grep "^${ORACLE_SID}:" ${ORATAB} | cut -d":" -f2) > /dev/null 2>&1
	if [ ! -d ${ORACLE_HOME} ]
	then
		echo ${ORACLE_SID}" does not exists in "${ORATAB}" or ORACLE_HOME invalid "${ORACLE_HOME}
		echo "aborting script!"
		exit 1
	fi

	PATH=${PATH}:${ORACLE_HOME}/bin

	if [ ${_CRS_ORACLE_BASE:-"empty"} = "empty" ]
	then
		# ORACLE_BASE not set in clusterenvironemt as parameter
		# => do we have orabase as script?
		ORABASE=${ORACLE_HOME}/bin/orabase
		if [ -x ${ORABASE} ]
		then
			# we get ORACLE_BASE from ORACLE_HOME
			ORACLE_BASE=$(ORABASE)
		else
			# we got no ORACLE_BASE from cluster environment
			# we are unable to set ORACLE_BASE!!
			echo "ORACLE_BASE not valid!"
			exit 10
		fi
	fi

	# is ORACLE_BASE a valid directory?
	ORACLE_BASE=$(${ORACLE_HOME}/bin/orabase)
	if [ ! -d ${ORACLE_BASE} ]
	then
		echo "ORACLE_BASE not valid. "${ORACLE_BASE}
		exit 10
	
	fi
	
	SQLPLUS=${ORACLE_HOME}/bin/sqlplus
	if [ ! -x ${SQLPLUS} ]
	then
		echo "sqlplus is missing. "${SQLPLUS}
		exit 10
	fi

	DB_SHUTDOWN_MODE=${_CRS_SHUTDOWN_MODE:-"IMMEDIATE"}
	export ORACLE_HOME ORACLE_SID
}

check_database() {
	echo "check database state for "${ORACLE_SID}" as user: "$(id)
	#
	# 1st we check for an existing pmon
	ps -elf | grep "ora_pmon_${ORACLE_SID}$" > /dev/null 2>&1
	retcode=${PIPESTATUS[1]}
	if [ ${retcode} -ne 0 ]
	then
		# Database not running!
		echo "Instance is down! pmon for "${ORACLE_SID}" not found!"
		exit 1
	fi

	# Check Startup_Mode
	# => we only check for executing a query when STARTUP_MODE=OPEN
	if [ ${_CRS_STARTUP_MODE} = "OPEN" ]
	then
		${SQLPLUS} -S -L /nolog  << _EOF_
		whenever sqlerror exit 1  rollback
		set termout off
		conn / as sysdba
		PROMPT Doing a Query against DBA_USERS to check for an open database
		select username from dba_users where username='SYS';
_EOF_
		if [ ${?} -ne 0 ]
		then
			echo "Instance not open!"
			exit 1
		fi
	fi
	
	
}

stop_database() {
	echo "stop database state for "${ORACLE_SID}" as user: "$(id)
	${SQLPLUS} -S -L /nolog << _EOF_
	connect / as sysdba
	PROMPT shutdown ${DB_SHUTDOWN_MODE}
	shutdown ${DB_SHUTDOWN_MODE}
_EOF_
}


start_database() {
	# We try to stop the database with abort
	# How could we handle a manualy mounted database who is not open?
	# Check of database goes to OFFLINE and cluster try to start the database
	# => 1st we do a shutdown abort and then a startup
	echo "start database state for "${ORACLE_SID}" as user: "$(id)
	${SQLPLUS} -S -L /nolog << _EOF_
	whenever sqlerror continue none
	connect / as sysdba
	shutdown abort
	whenever sqlerror exit 1 rollback
	startup 
_EOF_
	exit 1
	exit ${?}
}

clean_database() {
	# clean does a shutdown abort
	# 
	DB_SHUTDOWN_MODE=abort
	stop_database
}

set_env

case $1 in
'start')
	start_database
;;
'stop')
	stop_database
;;
'check')
	check_database
;;
'clean')
	clean_database
;;
esac
exit $RET

