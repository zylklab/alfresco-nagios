# Alfresco Nagios plugin for Alfresco Community

A well known example for Alfresco monitoring is available: 

https://github.com/toniblyx/alfresco-nagios-and-icinga-plugin

The most interesting information of this plugin is for Enterprise Edition (EE), although general direct monitoring commands (not JMX-based) may be used for Community Edition (CE) too. For example:

- check_http for direct monitorization of http(s) service (like 80 or 443)
- check_tcp for checking Tomcat and Alfresco ports (like 8009, 8080, 8443 or 50500)
- check_snmp for checking CPU, RAM, Load & Swap (via standard SNMP protocol)
- check_esxi for checking CPU, RAM, Load from VMware API point of view (if your instance is virtualized) 
- check_tomcat for monitoring threads and JVM 
- check_mysql for monitoring your database pool connections

Other important thing to monitor in Alfresco are your disk sizes (and inodes) and processes like Libreoffice. 

With OOTB Support Tools addon for Community Edition, it is possible to extract useful information about JVM, threads, logged users or SOLR via curl command, for generating alerts and graphs. We can use the JSON information from the available webscripts:

- JVM Used Memory
- Number of Threads
- Number of active database connections
- Number of logged users
- Number of tickets
- Process Load
- System Load
- SOLR numDocs (for any core)
- SOLR deletedDocs
- SOLR Health
- SOLR indices size (for any core)

## Nagios Icinga configuration

Files involved in Nagios/Icinga config

- hosts.cfg (Alfresco host)
- ootb-commands.cfg (OOTB curl commands)
- services_ootb.cfg (Alfresco services - non NRPE)
- nrpe_ootb.cfg (Alfresco services - only if NRPE)
- nrpe.cfg (For nrpe-server - only if NRPE)

By the way, shell scripts are usually placed at /usr/lib/nagios/plugins/

- check_ootb_active_sessions.sh
- check_ootb_performance_stats.sh
- check_ootb_solr.sh

For using this plugin you need some dependencies like curl and jshon. In Ubuntu 16.04 LTS, for example:

```
$ sudo aptitude install curl jshon
```

## Alfresco Config

Mainly, you need to create a dedicated user for Alfresco Monitoring, for example monitor, with admin rights (belonging to ALFRESCO_ADMINISTRATORS group). Take into consideration that this password is used in Nagios scripts. You should use SSL in http requests, or running monitoring processes locally in Alfresco server via NRPE protocol. 

## Tested

- Alfresco 2017XXGA
- OOTB Support Tools Addon >0.1
- Nagios/Icinga 3

## Author

- [Cesar Capillas](http://github.com/CesarCapillas)

## Links

- https://github.com/toniblyx/alfresco-nagios-and-icinga-plugin
- http://www.zylk.net/es/web-2-0/blog/-/blogs/monitoring-alfresco-in-nagios-via-ootb-support-tools-addon
- http://www.zylk.net/es/web-2-0/blog/-/blogs/more-on-monitoring-alfresco-in-nagios-via-ootb-support-tools
- https://github.com/OrderOfTheBee/ootbee-support-tools
