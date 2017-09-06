##
## Dockerfile
## 
##  for Icinga / Nagios for Alfresco CE/EE
##
##  by Cesar Capillas
##
##  To run this Dockerfile:
##
##   git clone https://github.com/zylklab/alfresco-nagios
##   cd alfresco-nagios
##   sudo docker build -t zylklab/icingalf .
##   sudo docker run -i -t zylklab/icingalf
##

FROM ubuntu 
MAINTAINER cesar at zylk.net

##
## Icinga Config
##
ENV ICINGA_CONFIG /etc/icinga/objects
ENV ICINGA_PLUGIN /usr/lib/nagios/plugins
ENV ICINGA_ADMIN admin 

##
## Alfresco Community Template
## 
ENV ALF_HOST alf-ce.melmac.net 
ENV ALF_PORT 8080 
ENV ALF_ADDR 127.0.0.1
# Alfresco admin user for monitoring
ENV ALF_USER monitor
ENV ALF_PASS secret
# Alfresco JMXProxy manager user
ENV JMXPROXY_USER manager
ENV JMXPROXY_PASS s3cret

##
## Alfresco Enterprise Template
##
ENV ACS_HOST alf-ee.melmac.net 
ENV ACS_ADDR 127.0.0.1 
# JMX User
ENV JMX_USER monitorRole
ENV JMX_PASS change_asap 

# Packages
RUN echo "postfix postfix/mailname string localhost" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
RUN echo "icinga-common icinga/check_external_commands select true" | debconf-set-selections
RUN echo "icinga-cgi icinga/adminpassword string $ICINGA_ADMIN" | debconf-set-selections
RUN echo "icinga-cgi icinga/adminpassword-repeat string $ICINGA_ADMIN" | debconf-set-selections
RUN apt-get update && apt-get install -y postfix icinga vim jshon curl openjdk-8-jre

# Icinga config
RUN sed -i "s/check_external_commands=0/check_external_commands=1/" /etc/icinga/icinga.cfg 
RUN dpkg-statoverride --update --add nagios www-data 2710 /var/lib/icinga/rw/
RUN dpkg-statoverride --update --add nagios nagios 751 /var/lib/icinga/

##
## Alfresco Icinga/Nagios configuration
##

ADD objects/hosts-alfresco.cfg $ICINGA_CONFIG/hosts-alfresco.cfg

# Alfresco Community 
ADD objects/services-ootb.cfg $ICINGA_CONFIG/services-ootb.cfg
ADD objects/commands-ootb.cfg $ICINGA_CONFIG/commands-ootb.cfg

ADD scripts/check_manager_jmxproxy.sh $ICINGA_PLUGIN/check_manager_jmxproxy.sh 
ADD scripts/check_ootb_active_sessions.sh $ICINGA_PLUGIN/check_ootb_active_sessions.sh
ADD scripts/check_ootb_performance_stats.sh $ICINGA_PLUGIN/check_ootb_performance_stats.sh
ADD scripts/check_ootb_solr.sh $ICINGA_PLUGIN/check_ootb_solr.sh

RUN chmod +x $ICINGA_PLUGIN/check_ootb* $ICINGA_PLUGIN/check_manager_jmxproxy.sh

RUN sed -i "s/alf5.melmac.net/$ALF_HOST/" $ICINGA_CONFIG/hosts-alfresco.cfg 
RUN sed -i "s/alf5.melmac.net!443/$ALF_HOST!$ALF_PORT/" $ICINGA_CONFIG/services-ootb.cfg 
RUN sed -i "s/monitor!secret/$ALF_USER!$ALF_PASS/" $ICINGA_CONFIG/services-ootb.cfg 
RUN sed -i "s/monitor2!secret2/$JMXPROXY_USER!$JMXPROXY_PASS/" $ICINGA_CONFIG/services-ootb.cfg 

# Alfresco Enterprise
ADD jmx/commands-jmx.cfg $ICINGA_CONFIG/commands-jmx.cfg
ADD jmx/services-jmx.cfg $ICINGA_CONFIG/services-jmx.cfg
ADD jmx/check_alfresco $ICINGA_PLUGIN/check_alfresco
ADD jmx/check_alfresco.jar $ICINGA_PLUGIN/check_alfresco.jar

RUN chmod +x $ICINGA_PLUGIN/check_alfresco*
RUN sed -i "s/acs5.melmac.net/$ACS_HOST/" $ICINGA_CONFIG/hosts-alfresco.cfg 
RUN sed -i "s/monitor!secret/$JMX_USER!$JMX_PASS/" $ICINGA_CONFIG/services-jmx.cfg 

WORKDIR $ICINGA_PLUGIN 

EXPOSE 80
ENTRYPOINT service apache2 restart && service icinga restart && echo "$ALF_ADDR $ALF_HOST" >> /etc/hosts && echo "$ACS_ADDR $ACS_HOST" >> /etc/hosts && bash
