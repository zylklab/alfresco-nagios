#!/bin/bash
#
#  Author: Cesar Capillas
#
#  https://github.com/CesarCapillas
#
#  License: see accompanying LICENSE file
#

# Helper for comparing non integer values
int () { awk "BEGIN{ print int($*) }" ;}

SERVER=$1
PORT=$2
USERNAME=$3
PASSWORD=$4
OBJ=$5
ATT=$6
KEY=$7
WARNING=${8:-100}
CRITICAL=${9:-200}

if [ "$PORT" = "443" ]; then
   PROTOCOL="https" 
else
   PROTOCOL="http" 
fi

ENDPOINT="$PROTOCOL://${SERVER}:${PORT}/manager/jmxproxy/?get=$OBJ&att=$ATT&key=$KEY"

if [[ "$1" == "" ]]; then
  echo "USAGE:"
  echo "  check_manager_jmxproxy.sh <SERVER> <PORT> <USERNAME> <PASSWORD> <OBJ> <ATT> <KEY> <WARNING> <CRITICAL>"
  echo 
  echo "  check_manager_jmxproxy.sh localhost 8080 monitor s3cret java.lang:type=Memory HeapMemoryUsage used 1000000000 2000000000"
  echo "  check_manager_jmxproxy.sh localhost 8080 monitor s3cret java.lang:type=Threading ThreadCount - 150 200"
  echo "  check_manager_jmxproxy.sh localhost 8080 monitor s3cret java.lang:type=OperatingSystem OpenFileDescriptorCount - 4096 8192"
  #echo "  check_manager_jmxproxy.sh localhost 8080 monitor s3cret java.lang:type=OperatingSystem SystemCpuLoad - 4 8"
  #echo "  check_manager_jmxproxy.sh localhost 8080 monitor s3cret java.lang:type=OperatingSystem ProcessCpuLoad - 4 8"
  #echo "  check_manager_jmxproxy.sh localhost 8080 monitor s3cret java.lang:type=OperatingSystem SystemLoadAverage - 4 8"
  echo "  Note: <WARNING> and <CRITICAL> must be integer."
  exit
fi
CURL=`curl --silent -u ${USERNAME}:${PASSWORD} -X GET ${ENDPOINT}`
CHCK=`echo $CURL | grep "$ATT"`

if [[ "$CHCK" == "" ]]; then
   CHECK="Failed"
else
   CHECK="OK"
   MYVAR=`echo $CURL | awk -F"= " '{print $2}'`
fi

if [[ "$CHECK" == "OK" ]]; then
   if ((`int $MYVAR` >= $CRITICAL));then
      echo "CRITICAL: $OBJ $ATT $KEY = $MYVAR (>=$CRITICAL)"
      exit 2
   fi
   if ((`int $MYVAR` >= $WARNING));then
      echo "WARNING: $OBJ $ATT $KEY = $MYVAR (>=$WARNING)"
      exit 1 
   fi

   echo "INFO: JMXPROXY ($OBJ $ATT $KEY) = $MYVAR"
   exit 0
elif [[ "$CHECK" == "Failed" ]]; then
   echo "CRITICAL: ${SERVER}"
   exit 2
else
   echo "Check failed."
   exit 3
fi
