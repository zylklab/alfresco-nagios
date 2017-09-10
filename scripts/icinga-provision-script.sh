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
JMXPROXY_USER=manager
JMXPROXY_PASS=s3cret

# Ubuntu xenial fix for Vagrant Box
# Icinga automate install and dependencies
echo "postfix postfix/mailname string localhost" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
echo "icinga-common icinga/check_external_commands select true" | debconf-set-selections
echo "icinga-cgi icinga/adminpassword string admin" | debconf-set-selections
echo "icinga-cgi icinga/adminpassword-repeat string admin" | debconf-set-selections
apt-get update && apt-get install -y postfix icinga vim jshon curl openjdk-7-jre

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

service icinga restart
service apache2 restart
