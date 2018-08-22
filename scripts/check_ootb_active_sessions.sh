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
WARNING=${6:-100}
CRITICAL=${7:-200}

if [ "$PORT" = "443" ]; then
   PROTOCOL="https" 
else
   PROTOCOL="http" 
fi

# Endpoint for Alfresco CE with OOTB Support Tools
ENDPOINT="$PROTOCOL://${SERVER}:${PORT}/alfresco/service/ootbee/admin/active-sessions?format=json"
# Endpoint for Alfresco EE with Support Tools addon
#ENDPOINT="$PROTOCOL://${SERVER}:${PORT}/alfresco/service/enterprise/admin/admin-activesessions?format=json"

if [[ "$1" == "" ]]; then
  echo "USAGE:"
  echo "  check_ootb_active_sessions.sh <SERVER> <PORT> <USERNAME> <PASSWORD> <VAR>"
  echo 
  echo "    where VAR=[NumActive|MaxActive|NumIdle|UserCountNonExpired|TicketCountNonExpired]"
  echo
  exit
fi

CURL=`curl --silent -u ${USERNAME}:${PASSWORD} -X GET ${ENDPOINT}`
CHCK=`echo $CURL | grep "$5"`

if [[ "$CHCK" == "" ]]; then
   CHECK="Failed"
else
   CHECK="OK"
   ACTIVE_SESSION_VAR=`echo $CURL | jshon -e $5 | sed 's/"//g'`
fi
 
if [[ "$CHECK" == "OK" ]]; then
   if (($ACTIVE_SESSION_VAR > $CRITICAL));then
      echo "CRITICAL: $5 = $ACTIVE_SESSION_VAR (>$CRITICAL) $5 = $ACTIVE_SESSION_VAR"
      exit 2
   fi
   if (($ACTIVE_SESSION_VAR > $WARNING));then
      echo "WARNING: $5 = $ACTIVE_SESSION_VAR (>$WARNING) | $5 = $ACTIVE_SESSION_VAR"
      exit 1 
   fi

   echo "INFO: Sessions ($5) = $ACTIVE_SESSION_VAR | $5 = $ACTIVE_SESSION_VAR"
   exit 0
elif [[ "$CHECK" == "Failed" ]]; then
   echo "CRITICAL: ${SERVER}"
   exit 2
else
   echo "Check failed."
   exit 3
fi
