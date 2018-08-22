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
STORE=$5
VAR=$6
WARNING=${7:-100}
CRITICAL=${8:-200}

if [ "$PORT" = "443" ]; then
   PROTOCOL="https" 
else
   PROTOCOL="http" 
fi

# Endpoint for Alfresco CE with OOTB Support Tools
ENDPOINT="$PROTOCOL://${SERVER}:${PORT}/alfresco/service/ootbee/admin/solr-tracking?format=json"

if [[ "$1" == "" ]]; then
  echo "USAGE:"
  echo "  check_ootb_solr.sh <SERVER> <PORT> <USERNAME> <PASSWORD> <STORE> <VAR> <WARNING> <CRITICAL>"
  echo "     where STORE [alfresco|archive]"
  echo "     where VAR   [numDocs|maxDocs|deletedDocs|diskUsage|memoryUsage|DeletedHealth]"
  exit
fi

CURL=`curl --silent -u ${USERNAME}:${PASSWORD} -X GET ${ENDPOINT}`
CHCK=`echo $CURL | grep "$STORE"`

if [[ "$VAR" == "DeletedHealth" ]]; then
   CHECK="OK"
elif [[ "$CHCK" == "" ]]; then
   CHECK="Failed"
else
   CHECK="OK"
   SOLR_VAR=`echo $CURL | jshon -e $STORE | jshon -e $VAR | sed 's/"//g'`
fi

if [[ "$CHECK" == "OK" ]]; then

   if [[ "$VAR" == "DeletedHealth" ]]; then
      CHCK1=`echo $CURL | jshon -e alfresco | jshon -e "numDocs"`
      CHCK2=`echo $CURL | jshon -e alfresco | jshon -e "deletedDocs"`
      MYDIV=`echo "$CHCK2 $CHCK1" | awk '{print int($1*100/$2)}'`
      if (($MYDIV > $CRITICAL));then
        echo "CRITICAL: SOLR ($VAR) = $MYDIV (>$CRITICAL)"
        exit 2
      fi
      if (($MYDIV > $WARNING));then
        echo "WARNING: SOLR ($VAR) = $MYDIV (>$WARNING)"
        exit 1
      fi
      echo "INFO: SOLR ($VAR) = $MYDIV"
      exit 0
   fi

   if (($SOLR_VAR > $CRITICAL));then
      echo "CRITICAL: SOLR ($VAR) = $SOLR_VAR (>$CRITICAL) | $VAR = $SOLR_VAR"
      exit 2
   fi
   if (($SOLR_VAR > $WARNING));then
      echo "WARNING: SOLR ($VAR) = $SOLR_VAR (>$WARNING) | $VAR = $SOLR_VAR"
      exit 1 
   fi

   echo "INFO: SOLR ($VAR) = $SOLR_VAR | $VAR = $SOLR_VAR"
   exit 0
elif [[ "$CHECK" == "Failed" ]]; then
   echo "CRITICAL: ${SERVER}"
   exit 2
else
   echo "Check failed."
   exit 3
fi
