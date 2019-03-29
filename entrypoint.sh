#!/bin/bash
set -e

if [ "$1" == "run" ]
then

	sed -i "s/@@ASS_HOST@@/$ASS_HOST/" $ICINGA_CONFIG/host-ass.cfg 
	sed -i "s/@@ALF_HOST@@/$ALF_HOST/" $ICINGA_CONFIG/host-acs.cfg
	sed -i "s/@@ASS_HOST@@/$ASS_HOST/" $ICINGA_CONFIG/services-ass.cfg
	sed -i "s/@@ASS_PORT@@/$ASS_PORT/" $ICINGA_CONFIG/services-ass.cfg 
	rm -rf $ICINGA_CONFIG/services_icinga.cfg

	if [ "$MODE" == "CE" ]
	then

		rm -rf $ICINGA_CONFIG/*-ee.cfg
		sed -i "s/@@ALF_HOST@@/$ALF_HOST/" $ICINGA_CONFIG/services-ce.cfg
		sed -i "s/@@ALF_PORT@@/$ALF_PORT/" $ICINGA_CONFIG/services-ce.cfg
		sed -i "s/@@ASS_HOST@@/$ASS_HOST/" $ICINGA_CONFIG/services-ce.cfg
		sed -i "s/@@ASS_PORT@@/$ASS_PORT/" $ICINGA_CONFIG/services-ce.cfg 
		sed -i "s/@@ALF_USER@@!@@ALF_PASS@@/$ALF_USER!$ALF_PASS/" $ICINGA_CONFIG/services-ce.cfg 
		sed -i "s/@@JMXPROXY_USER@@!@@JMXPROXY_PASS@@/$JMXPROXY_USER!$JMXPROXY_PASS/" $ICINGA_CONFIG/services-ce.cfg 

	elif [ "$MODE" == "EE" ]
	then
		rm -rf $ICINGA_CONFIG/*-ce.cfg
		sed -i "s/@@ALF_HOST@@/$ALF_HOST/" $ICINGA_CONFIG/services-ee.cfg
		sed -i "s/@@ALF_PORT@@/$ALF_PORT/" $ICINGA_CONFIG/services-ee.cfg
		sed -i "s/@@ASS_HOST@@/$ASS_HOST/" $ICINGA_CONFIG/services-ee.cfg
		sed -i "s/@@ASS_PORT@@/$ASS_PORT/" $ICINGA_CONFIG/services-ee.cfg 
		sed -i "s/@@JMX_USER@@!@@JMX_PASS@@/$JMX_USER!$JMX_PASS/" $ICINGA_CONFIG/services-ee.cfg 
	fi


	chmod +x $ICINGA_PLUGIN/check_alfresco* 

	service npcd start
	service icinga start
	/usr/sbin/apache2ctl -D FOREGROUND
else
	exec "$@"
fi
