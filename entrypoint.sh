#!/bin/bash
set -e

if [ "$1" == "run" ]
then
	sed -i "s/alf5.melmac.net/$ALF_HOST/" $ICINGA_CONFIG/hosts-alfresco.cfg 
	sed -i "s/alf5.melmac.net!443/$ALF_HOST!$ALF_PORT/" $ICINGA_CONFIG/services-ootb.cfg 
	sed -i "s/monitor!secret/$ALF_USER!$ALF_PASS/" $ICINGA_CONFIG/services-ootb.cfg 
	sed -i "s/monitor2!secret2/$JMXPROXY_USER!$JMXPROXY_PASS/" $ICINGA_CONFIG/services-ootb.cfg 
	sed -i "s/acs5.melmac.net/$ACS_HOST/" $ICINGA_CONFIG/hosts-alfresco.cfg 
	sed -i "s/monitor!secret/$JMX_USER!$JMX_PASS/" $ICINGA_CONFIG/services-jmx.cfg 
	sed -i "s/ass.melmac.net/$ASS_HOST/" $ICINGA_CONFIG/hosts-alfresco.cfg 
	sed -i "s/ass.melmac.net!8983/$ASS_HOST!$ASS_PORT/" $ICINGA_CONFIG/services-ass.cfg 
	chmod +x $ICINGA_PLUGIN/check_alfresco* 

	service npcd start
	service icinga start
	/usr/sbin/apache2ctl -D FOREGROUND
else
	exec "$@"
fi