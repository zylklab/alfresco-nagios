#!/bin/bash
##
## Icinga script for vagrant provision
##
 
##
## Icinga Config
##
ICINGA_CONFIG=/etc/icinga/objects
ICINGA_PLUGIN=/usr/lib/nagios/plugins
ICINGA_ADMIN=admin 

##
## Alfresco Enterprise Template
##
ACS_HOST=alf-ee.melmac.net
ACS_ADDR=127.0.0.1
JMX_USER=monitorRole
JMX_PASS=change_asap

##
## Alfresco Community Template
## 
ALF_HOST=alf-ce.melmac.net
ALF_PORT=8080 
ALF_ADDR=127.0.0.1
# Alfresco admin user for monitoring
ALF_USER=monitor 
ALF_PASS=secret
# Alfresco JMXProxy manager user
JMXPROXY_USER=monitor
JMXPROXY_PASS=s3cret

##
## Alfresco Search Services
## 
ASS_HOST=ass.melmac.net 
ASS_PORT=8983 
ASS_ADDR=127.0.0.1 

# Icinga automate install and dependencies
echo "debconf debconf/frontend select Noninteractive" | debconf-set-selections
echo "postfix postfix/mailname string localhost" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
echo "icinga-common icinga/check_external_commands select true" | debconf-set-selections
echo "icinga-cgi icinga/adminpassword string admin" | debconf-set-selections
echo "icinga-cgi icinga/adminpassword-repeat string admin" | debconf-set-selections
apt-get update && apt-get install -y apache2 postfix 
apt-get install -y icinga vim jshon curl openjdk-7-jre python-urllib3 pnp4nagios python-setuptools python-dev build-essential
easy_install pip
pip install nagiosplugin

# Icinga config
sed -i "s/check_external_commands=0/check_external_commands=1/" /etc/icinga/icinga.cfg
dpkg-statoverride --update --add nagios www-data 2710 /var/lib/icinga/rw/
dpkg-statoverride --update --add nagios nagios 751 /var/lib/icinga/

cp /home/vagrant/objects/* /etc/icinga/objects
cp /home/vagrant/jmx/*cfg /etc/icinga/objects
cp /home/vagrant/jmx/check_alfresco* /usr/lib/nagios/plugins
cp /home/vagrant/scripts/* /usr/lib/nagios/plugins
cp /home/vagrant/images/alfresco.gif /usr/share/nagios/htdocs/images/logos/base/
cp /home/vagrant/images/alfresco.png /usr/share/nagios/htdocs/images/logos/base/
chmod +x /usr/lib/nagios/plugins/*

# PNP4Nagios
sed -i "s#/cgi-bin/nagios3#/icinga/cgi-bin#" /etc/pnp4nagios/config.php
sed -i "s/process_performance_data=0/process_performance_data=1/" /etc/icinga/icinga.cfg
echo "broker_module=/usr/lib/pnp4nagios/npcdmod.o config_file=/etc/pnp4nagios/npcd.cfg" >> /etc/icinga/icinga.cfg
sed -i 's/RUN="no"/RUN="yes"/' /etc/default/npcd
sed -i "s/nagios3/icinga/" /etc/pnp4nagios/apache.conf 

cp /home/vagrant/pnp/generic-host_icinga.cfg /etc/icinga/objects/generic-host_icinga.cfg  
cp /home/vagrant/pnp/generic-service_icinga.cfg /etc/icinga/objects/generic-service_icinga.cfg  

echo "Include /etc/pnp4nagios/apache.conf" >> /etc/icinga/apache2.conf
mv /usr/share/pnp4nagios/html/install.php /usr/share/pnp4nagios/html/install.php.orig
cp /usr/share/doc/pnp4nagios/examples/ssi/status-header.ssi /usr/share/icinga/htdocs/ssi/
ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load
cp /usr/share/icinga/htdocs/images/action.gif /usr/share/icinga/htdocs/images/action.gif.orig
cp /usr/share/icinga/htdocs/images/stats.gif /usr/share/icinga/htdocs/images/action.gif

# Alfresco Community config
sed -i "s/alf5.melmac.net/$ALF_HOST/" $ICINGA_CONFIG/hosts-alfresco.cfg 
sed -i "s/alf5.melmac.net!443/$ALF_HOST!$ALF_PORT/" $ICINGA_CONFIG/services-ootb.cfg 
sed -i "s/monitor!secret/$ALF_USER!$ALF_PASS/" $ICINGA_CONFIG/services-ootb.cfg
sed -i "s/monitor2!secret2/$JMXPROXY_USER!$JMXPROXY_PASS/" $ICINGA_CONFIG/services-ootb.cfg 
echo "$ALF_ADDR $ALF_HOST" >> /etc/hosts

# Alfresco Entrerprise config
sed -i "s/acs5.melmac.net/$ACS_HOST/" $ICINGA_CONFIG/hosts-alfresco.cfg 
sed -i "s/monitor!secret/$JMX_USER!$JMX_PASS/" $ICINGA_CONFIG/services-jmx.cfg 
echo "$ACS_ADDR $ACS_HOST" >> /etc/hosts

# Alfresco Search services
sed -i "s/ass.melmac.net/$ASS_HOST/" $ICINGA_CONFIG/hosts-alfresco.cfg
sed -i "s/ass.melmac.net!8983/$ASS_HOST!$ASS_PORT/" $ICINGA_CONFIG/services-ass.cfg
echo "$ASS_ADDR $ASS_HOST" >> /etc/hosts

service npcd restart
service icinga restart
service apache2 restart
