#!/bin/bash
#
# $Id: action_listener_failover.sh 798 2013-05-18 06:27:12Z tbr $
#
# Copyright 2013 (c) Thorsten Bruhns (tbruhns@gmx.de)
#
# _CRS_LISTENER_NAME    Name of Listener
#
# Listener is started under ORACLE_HOME from CRS_OWNER
#
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

	OLR_CFG=/etc/oracle/olr.loc
	ORATAB=/etc/oratab

	CRS_HOME=`grep "^crs_home" ${OLR_CFG} | cut -d"=" -f2`

	ORACLE_HOME=${CRS_HOME}

	ORACLE_SID=`grep ":${ORACLE_HOME}:" ${ORATAB} | grep "^+ASM"|cut -d":" -f1`

	PATH=${PATH}:${ORACLE_HOME}/bin
	export ORACLE_SID ORACLE_HOME PATH


	if [ ${_CRS_LISTENER_NAME:-"-1"} = "-1" ]
	then
		echo "_CRS_LISTENER_NAME not set in clusterware environment."
		echo "aborting script!"
		exit 1
	fi

	LSNRCTL=${ORACLE_HOME}/bin/lsnrctl
	if [ ! -x ${LSNRCTL} ]
	then
		echo "tnslsnr is missing. "${LSNRCTL}
		exit 10
	fi

}

check_listener() {
	echo "check listener  state for "${ORACLE_SID}" as user: "$(id)
	${LSNRCTL} status ${_CRS_LISTENER_NAME}
	exit ${?}
}

stop_listener() {
	echo "stop listener  state for "${ORACLE_SID}" as user: "$(id)
	${LSNRCTL} stop ${_CRS_LISTENER_NAME}
	exit ${?}
}

start_listener() {
	echo "start listener  state for "${ORACLE_SID}" as user: "$(id)
	${LSNRCTL} start ${_CRS_LISTENER_NAME}
	exit ${?}
}

clean_listener() {
	stop_listener
}

set_env

case $1 in
'start')
	start_listener
;;
'stop')
	stop_listener
;;
'check')
	check_listener
;;
'clean')
	clean_listener
;;
esac
exit $RET

