#!/bin/bash
#
#  Author: Cesar Capillas
#
#  https://github.com/CesarCapillas
#
#  License: see accompanying LICENSE file
#

SERVER=$1
PORT=$2
USERNAME=$3
PASSWORD=$4
VAR=$5
WARNING=${6:-10000}
CRITICAL=${7:-10000}
if [ "$PORT" = "443" ]; then
   PROTOCOL="https" 
else
   PROTOCOL="http" 
fi

# Endpoint for Alfresco CE with OOTB Support Tools
ENDPOINT="$PROTOCOL://${SERVER}:${PORT}/alfresco/service/ootbee/admin/admin-performance?format=json"
# Endpoint for Alfresco EE with Support Tools addon
#ENDPOINT="$PROTOCOL://${SERVER}:${PORT}/alfresco/service/enterprise/admin/admin-performance?format=json"

# Most useful are UsedMemory (JVM) and ThreadCount 
#   Memory is in Mb Ej; 4096M
#   Load is in percentage
 
if [[ "$1" == "" ]]; then
  echo "USAGE:"
  echo "  check_ootb_performance_stats.sh <SERVER> <PORT> <USERNAME> <PASSWORD> <VAR> <WARNING> <CRITICAL>"
  echo 
  echo "    where VAR=[MaxMemory|TotalMemory|UsedMemory|FreeMemory|ProcessLoad|SystemLoad|ThreadCount|PeakThreadCount]"
  echo 
  echo $CURL 
  exit
fi

CURL=`curl --silent -u ${USERNAME}:${PASSWORD} -X GET ${ENDPOINT}`
CHCK=`echo $CURL | grep "$5"`

if [[ "$CHCK" == "" ]]; then
   CHECK="Failed"
else
   CHECK="OK"
   PERFORMANCE_VAR=`echo $CURL | jshon -e $5`
fi
 
if [[ "$CHECK" == "OK" ]]; then
   if (($PERFORMANCE_VAR > $CRITICAL));then
      echo "CRITICAL: $5 = $PERFORMANCE_VAR (>$CRITICAL) | $5 = $PERFORMANCE_VAR"
      exit 2
   fi
   if (($PERFORMANCE_VAR > $WARNING));then
      echo "WARNING: $5 = $PERFORMANCE_VAR (>$WARNING) | $5 = $PERFORMANCE_VAR"
      exit 1 
   fi

   echo "INFO: $5 = $PERFORMANCE_VAR | $5 = $PERFORMANCE_VAR"
   exit 0

elif [[ "$CHECK" == "Failed" ]]; then
   echo "CRITICAL: ${SERVER}"
   exit 2
else
   echo "Check failed."
   exit 3
fi
