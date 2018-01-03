# Nagios setup for Alfresco

## Table of Contents
- [Introduction](#introduction)
- [Nagios-Icinga configuration for Alfresco Community](#nagios-icinga-configuration-for-alfresco-community)
- [Nagios-Icinga configuration for Alfresco Enterprise](#nagios-icinga-configuration-for-alfresco-enterprise)
- [Using Dockerfile](#using-dockerfile)
- [Using Vagrantfile](#using-vagrantfile)
- [Tested on](#tested-on)
- [Author](#author)
- [Links](#links)

## Introduction

A well known example for Alfresco monitoring via JMX is available [here](https://github.com/toniblyx/alfresco-nagios-and-icinga-plugin), but the most interesting information for this is related to Enterprise Edition (EE). General direct monitoring commands (not JMX-based) may be used for Community Edition (CE) too, for example:

- check_ssh for direct monitorization of ssh port
- check_http for direct monitorization of http(s) service (like 80 or 443)
- check_tcp for checking Tomcat and Alfresco ports (like 8009, 8080, 8443 or 50500)
- check_snmp for checking CPU, RAM, Load & Swap (via standard SNMP protocol) if using SNMP protocol
- check_esxi for checking CPU, RAM, Load from VMware API point of view (if your instance is virtualized)

We can obtain additional monitoring information for Alfresco Community via OOTB Support Tools webscripts (System Performance, Active Sessions and SOLR).

## Nagios-Icinga configuration for Alfresco Community

The files involved in Nagios/Icinga configuration for Alfresco Community are the following:

- objects/hosts-alfresco.cfg (Alfresco hosts definition)
- objects/commands-ootb.cfg (Nagios commands)
- objects/services-ootb.cfg (Non NRPE services)
- nrpe/nrpe-ootb.cfg (NRPE services)
- nrpe/nrpe.cfg (For nrpe-server - only if NRPE)

By the way, shell scripts are usually placed at /usr/lib/nagios/plugins/

- scripts/check_ootb_performance_stats.sh
- scripts/check_ootb_active_sessions.sh
- scripts/check_ootb_solr.sh
- scripts/check_manager_jmxproxy.sh (JMX monitoring)

For using this setup you need some dependencies like curl and jshon in your Nagios Server. In Ubuntu 16.04 LTS, for example:

```
$ sudo apt-get install curl jshon
```

Once installed in your Nagios server, you can the corresponding scripts:

```
$ check_ootb_performance_stats.sh 
USAGE:
  check_ootb_performance_stats.sh <SERVER> <PORT> <USERNAME> <PASSWORD> <VAR> <WARNING> <CRITICAL>

    where VAR=[MaxMemory|TotalMemory|UsedMemory|FreeMemory|ProcessLoad|SystemLoad|ThreadCount|PeakThreadCount]
   
check_ootb_performance_stats.sh alfie.zylk.net 443 monitor secret UsedMemory 1000 2000
WARNING: UsedMemory = 1453 (>1000)
```

Note: If you plan to use NRPE config, you need to configure your Alfresco Server as a Nagios NRPE server.

### Alfresco CE configuration

For consuming OOTB webscripts, you need to create a dedicated user for Alfresco Monitoring, for example monitor, with admin rights (belonging to ALFRESCO_ADMINISTRATORS group). Take into consideration that this password is used in Nagios scripts. You should use SSL in http requests, or running monitoring processes locally in Alfresco server via NRPE protocol (safer). Previously you need to install OOTB Support Tools addon in your Alfresco server.

### Enabling JMXProxy servlet

With JMXProxy servlet, you may get JMX information about Garbage Collector, Memory, Threads or Operating System in your Tomcat instance. The essential info may be obtained from OOTB Support Tools webscripts too, but other important parameters from Operating System or Garbage Collector may be extracted this way. Please note that this JMX information is related to the default mbeans in a Tomcat container, and not related to the Alfresco JMX objects contained in Alfresco Enterprise (aka Alfresco Content Services). For illustrating this, we will monitor the number of opened file descriptors in the operating system. It is also an alternative to [Jolokia](https://jolokia.org/tutorial.html) or check_jmx methods.

If you use the default installer in Alfresco, the Tomcat manager application is deployed under webapps directory. You may enable JMXProxy servlet for monitoring JMX variables in Alfresco Community: 

- Create $ALF_HOME/tomcat/conf/Catalina/localhost/manager.xml

```
<Context antiResourceLocking="false" privileged="true" useHttpOnly="true" 
override="true">
  <Valve className="org.apache.catalina.authenticator.BasicAuthenticator" securePagesWithPragma="false" 
/>
</Context>

```

- Edit credentials and roles for manager user at $ALF_HOME/tomcat/conf/tomcat-users.xml

```
<tomcat-users>
  <user username="CN=Alfresco Repository Client, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB" roles="repoclient" password="null"/>
  <user username="CN=Alfresco Repository, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB" roles="repository" password="null"/>
  <role rolename="manager-jmx"/>
  <user username="monitor" password="secret" roles="manager-jmx"/>
</tomcat-users>
```

Finally you need to restart Alfresco service. And for checking it you can type:

```
$ curl -u monitor:secret "http://127.0.0.1:8080/manager/jmxproxy/?get=java.lang:type=OperatingSystem&att=OpenFileDescriptorCount"
```

### OOTB Support Tools helper for monitoring Alfresco Community

![Nagios Alfresco](images/alfresco-nagios.png)
 
With [OOTB Support Tools addon for Alfresco Community Edition](https://github.com/OrderOfTheBee/ootbee-support-tools), it is possible to extract useful information about JVM, threads, logged users or SOLR via curl command, for generating alerts and graphs in Nagios. We can use the JSON information from the available webscripts of the addon:

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

## Nagios-Icinga configuration for Alfresco Enterprise

The files involved in Nagios/Icinga configuration for Alfresco Enterprise are the following:

- jmx/hosts-alfresco.cfg (Alfresco hosts definition)
- jmx/commands-jmx.cfg (Nagios commands)
- jmx/services-jmx.cfg (Non NRPE services)

By the way, check_alfresco script and check_alfresco.jar is usually placed at /usr/lib/nagios/plugins/

Finally, you need to have Java installed on your Nagios-Icinga server for executing check_alfresco 

### Enabling JMX in Alfresco Enterprise

Alfresco Enterprise (aka Alfresco Content Services) provides custom mbeans via JMX, not available in Alfresco Community. A good example for getting monitor information via JMX (check_jmx) is given [here](https://github.com/toniblyx/alfresco-nagios-and-icinga-plugin).    

In recent versions of Alfresco Enterprise you should enable JMX via $JAVA_OPTS and alfresco-global.properties:

 * In $ALF_HOME/tomcat/bin/setenv.sh, you should set -Dcom.sun.management.jmxremote between your $JAVA_OPTS
 * In alfresco-global.properties, you should configure alfresco.jmx.connector.enabled=true
 * In alfresco-global.properties, it is useful to adequate alfresco.jmx.dir=/opt/alfresco/tomcat/shared/jmx for changing JMX default passwords including in alfresco-jmxrmi.access and alfresco-jmxrmi.password files

You can test it with a JMX Console such as JConsole or even via check_jmx commands. For more details, you can check [Alfresco docs](https://docs.alfresco.com/5.0/tasks/jmx-access.html)

## Using Dockerfile

You can check this basic Nagios/Icinga setup using Docker in Ubuntu 16.04 LTS. It includes a template for using it in Alfresco Enterprise via check_jmx, and also in Alfresco Community via OOTB Support Tools webscripts and JMXProxy. You need to enable JMX in Alfresco Enterprise, and to install OOTB Support Tools addon and JMXProxy in Alfresco Community targets. 

0. Clone this project
```
$ git clone https://github.com/zylklab/alfresco-nagios
$ cd alfresco-nagios
```

1. Configure Alfresco templates in Dockerfile according to your Alfresco repository targets to monitor.

```
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
```

2. Run docker commands

```
$ sudo docker build -t zylklab/icingalf .
$ sudo docker run -i -t zylklab/icingalf
```

3. Login http://docker-server-ip/icinga with icingaadmin/admin credentials.

Note: Take into consideration that email alerts are not configured. You should configure postfix and Icinga/Nagios contacts.

## Using Vagrantfile

Other way of testing this setup is via Vagrantfile. This creates a Virtualbox VM based on Ubuntu 14.04 LTS and it provisions the needed Icinga installation and configuration. The template variables for the Alfresco targets are included in scripts/icinga-provision-script.sh  

```
$ git clone https://github.com/zylklab/alfresco-nagios
$ cd alfresco-nagios
# Edit scripts/icinga-provision-script.sh for setting Alfresco target vars
$ vagrant up
$ vagrant ssh
# Once you finish you may exit VM, vagrant halt (or even vagrant destroy -f)
```

Then login in http://vagrant-server-ip/icinga with icingaadmin/admin credentials

## Tested on

- Alfresco 2017XXGA + OOTB Support Tools Addon >0.1
- Alfresco 5.0.25 EE 
- Nagios/Icinga 3
- Docker version 1.12.6
- Vagrant 1.8.1 

## Author

- [Cesar Capillas](http://github.com/CesarCapillas)

## Links

- [Alfresco Nagios Setup for Alfresco Enterprise](https://github.com/toniblyx/alfresco-nagios-and-icinga-plugin)
- [OOTB Support Tools](https://github.com/OrderOfTheBee/ootbee-support-tools)
- [Using the JMX Proxy Servlet](https://tomcat.apache.org/tomcat-7.0-doc/manager-howto.html#Using_the_JMX_Proxy_Servlet)
- [Enabling JMX in Alfresco Enterprise](https://docs.alfresco.com/5.0/tasks/jmx-access.html)
- [Jolokia tutorial](https://jolokia.org/tutorial.html)
- [Blog Post - Monitoring Alfresco in Nagios via OOTB Support Tools](http://www.zylk.net/es/web-2-0/blog/-/blogs/monitoring-alfresco-in-nagios-via-ootb-support-tools-addon)
- [Blog Post - More on monitoring Alfresco in Nagios via OOTB Support Tools](http://www.zylk.net/es/web-2-0/blog/-/blogs/more-on-monitoring-alfresco-in-nagios-via-ootb-support-tools)
