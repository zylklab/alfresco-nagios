##
## Dockerfile
## 
##  Icinga / Nagios for Alfresco and Alfresco Search Services (CE/EE)
##
##   by Cesar Capillas

FROM ubuntu:14.04 
LABEL maintainer="cesar at zylk.net"
LABEL collaborator="mikel.asla at zylk.net"

##
## Icinga Config
##
ENV ICINGA_CONFIG="/etc/icinga/objects" ICINGA_PLUGIN="/usr/lib/nagios/plugins" ICINGA_ADMIN="admin"

##
## Alfresco Community Template
## 
ENV ALF_HOST="alf-ce.melmac.net" ALF_PORT="8080"
# Alfresco admin user for monitoring
ENV ALF_USER="monitor" ALF_PASS="secret"
# Alfresco JMXProxy manager user
ENV JMXPROXY_USER="monitor" JMXPROXY_PASS="s3cret"

##
## Alfresco Enterprise Template
##
ENV ACS_HOST="alf-ee.zylk.net" ACS_PORT="8080"
# JMX User
ENV JMX_USER="monitorRole" JMX_PASS="change_asap"

##
## Alfresco Search Services
## 
ENV ASS_HOST="alf-ce.zylk.net" ASS_PORT="8983"

##
## Ubuntu Packages
##
RUN set -x \
	&& echo "debconf debconf/frontend select Noninteractive" | debconf-set-selections \
	&& echo "postfix postfix/mailname string localhost" | debconf-set-selections \
	&& echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections \
	&& echo "icinga-common icinga/check_external_commands select true" | debconf-set-selections \
	&& echo "icinga-cgi icinga/adminpassword string $ICINGA_ADMIN" | debconf-set-selections \
	&& echo "icinga-cgi icinga/adminpassword-repeat string $ICINGA_ADMIN" | debconf-set-selections \
	&& apt-get update && apt-get install -y postfix icinga vim jshon curl openjdk-7-jre python-urllib3 pnp4nagios python-setuptools python-dev build-essential \
	&& easy_install pip \
	&& pip install nagiosplugin \
	&& sed -i "s/check_external_commands=0/check_external_commands=1/" /etc/icinga/icinga.cfg \
	&& dpkg-statoverride --update --add nagios www-data 2710 /var/lib/icinga/rw/ \
	&& dpkg-statoverride --update --add nagios nagios 751 /var/lib/icinga/ \
	&& sed -i "s#/cgi-bin/nagios3#/icinga/cgi-bin#" /etc/pnp4nagios/config.php \
	&& sed -i "s/process_performance_data=0/process_performance_data=1/" /etc/icinga/icinga.cfg \
	&& echo "broker_module=/usr/lib/pnp4nagios/npcdmod.o config_file=/etc/pnp4nagios/npcd.cfg" >> /etc/icinga/icinga.cfg \
	&& sed -i 's/RUN="no"/RUN="yes"/' /etc/default/npcd \
	&& sed -i "s/nagios3/icinga/" /etc/pnp4nagios/apache.conf \
	&& echo "Include /etc/pnp4nagios/apache.conf" >> /etc/icinga/apache2.conf \
	&& mv /usr/share/pnp4nagios/html/install.php /usr/share/pnp4nagios/html/install.php.orig \
	&& cp /usr/share/doc/pnp4nagios/examples/ssi/status-header.ssi /usr/share/icinga/htdocs/ssi/ \
	&& ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load \
	&& cp /usr/share/icinga/htdocs/images/action.gif /usr/share/icinga/htdocs/images/action.gif.orig \
	&& cp /usr/share/icinga/htdocs/images/stats.gif /usr/share/icinga/htdocs/images/action.gif

##
## Alfresco Icinga/Nagios configuration
##
ADD pnp/generic-host_icinga.cfg /etc/icinga/objects/generic-host_icinga.cfg  
ADD pnp/generic-service_icinga.cfg /etc/icinga/objects/generic-service_icinga.cfg  
# Alfresco Community 
ADD objects/hosts-alfresco.cfg $ICINGA_CONFIG/hosts-alfresco.cfg
ADD objects/services-ootb.cfg $ICINGA_CONFIG/services-ootb.cfg
ADD objects/commands-ootb.cfg $ICINGA_CONFIG/commands-ootb.cfg
# Scripts
ADD scripts/check_manager_jmxproxy.sh $ICINGA_PLUGIN/check_manager_jmxproxy.sh 
ADD scripts/check_ootb_active_sessions.sh $ICINGA_PLUGIN/check_ootb_active_sessions.sh
ADD scripts/check_ootb_performance_stats.sh $ICINGA_PLUGIN/check_ootb_performance_stats.sh
ADD scripts/check_ootb_solr.sh $ICINGA_PLUGIN/check_ootb_solr.sh
# Images
ADD images/alfresco.gif /usr/share/nagios/htdocs/images/logos/base/alfresco.gif
ADD images/alfresco.png /usr/share/nagios/htdocs/images/logos/base/alfresco.png
# Alfresco Enterprise
ADD jmx/commands-jmx.cfg $ICINGA_CONFIG/commands-jmx.cfg
ADD jmx/services-jmx.cfg $ICINGA_CONFIG/services-jmx.cfg
ADD jmx/check_alfresco $ICINGA_PLUGIN/check_alfresco
ADD jmx/check_alfresco.jar $ICINGA_PLUGIN/check_alfresco.jar
# Alfresco Search services
ADD scripts/check_alfresco_solr.py $ICINGA_PLUGIN/check_alfresco_solr.py
ADD objects/commands-ass.cfg $ICINGA_CONFIG/commands-ass.cfg
ADD objects/services-ass.cfg $ICINGA_CONFIG/services-ass.cfg
ADD entrypoint.sh /entrypoint.sh

RUN set -x \
	&& chmod +x $ICINGA_PLUGIN/check_ootb* $ICINGA_PLUGIN/check_manager_jmxproxy.sh \
	&& chmod +x /entrypoint.sh	
 
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh", "run"]
