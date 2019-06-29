# Enabling Alfresco JMX

## Enabling JMX in Alfresco Enterprise

Alfresco Enterprise (aka Alfresco Content Services) provides custom mbeans via JMX, not available in Alfresco Community. A good example for getting monitor information via JMX (check_jmx) is given [here](https://github.com/toniblyx/alfresco-nagios-and-icinga-plugin).    

In recent versions of Alfresco Enterprise you should enable JMX via $JAVA_OPTS and alfresco-global.properties:

 * In $ALF_HOME/tomcat/bin/setenv.sh, you should set -Dcom.sun.management.jmxremote between your $JAVA_OPTS
 * In alfresco-global.properties, you should configure alfresco.jmx.connector.enabled=true
 * In alfresco-global.properties, it is useful to adequate alfresco.jmx.dir=/opt/alfresco/tomcat/shared/jmx for changing JMX default passwords including in alfresco-jmxrmi.access and alfresco-jmxrmi.password files

You can test it with a JMX Console such as JConsole or even via check_jmx commands. For more details, you can check [Alfresco docs](https://docs.alfresco.com/5.0/tasks/jmx-access.html)

## Enabling Jolokia

Another possibility is to use the JMX-HTTP bridge provided by Jolokia:

- Copy jolokia.war to $ALF_HOME/tomcat/webapps
- Create $ALF_HOME/tomcat/conf/Catalina/localhost/jolokia.xml

```
<Context antiResourceLocking="false" privileged="true" useHttpOnly="true" 
override="true">
  <Valve className="org.apache.catalina.authenticator.BasicAuthenticator" securePagesWithPragma="false" 
/>
</Context>

```

- Edit credentials and roles for jolokia role at $ALF_HOME/tomcat/conf/tomcat-users.xml

```
<tomcat-users>
  <user username="CN=Alfresco Repository Client, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB" roles="repoclient" password="null"/>
  <user username="CN=Alfresco Repository, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB" roles="repository" password="null"/>
  <role rolename="manager-jmx"/>
  <role rolename="jolokia"/>
  <user username="monitor" password="secret" roles="manager-jmx,jolokia"/>
</tomcat-users>
```

Finally you need to restart Alfresco service. And for checking it you can type:

```
$ curl -u monitor:secret http://localhost:8080/jolokia/read/java.lang:type=Memory/HeapMemoryUsage | jq
{
  "request": {
    "mbean": "java.lang:type=Memory",
    "attribute": "HeapMemoryUsage",
    "type": "read"
  },
  "value": {
    "init": 3221225472,
    "committed": 3151495168,
    "max": 3151495168,
    "used": 938455384
  },
  "timestamp": 1561798953,
  "status": 200
}
```

## Enabling JMXProxy servlet 

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

## Author

- [Cesar Capillas](http://github.com/CesarCapillas)

## Links

- [Enabling JMX in Alfresco (blog post)](https://www.zylk.net/en/web-2-0/blog/-/blogs/enabling-jmx-in-alfresco)
- [Using the JMX Proxy Servlet](https://tomcat.apache.org/tomcat-7.0-doc/manager-howto.html#Using_the_JMX_Proxy_Servlet)
- [Using Jolokia](https://jolokia.org/tutorial.html)
- [Enabling JMX in Alfresco Enterprise](https://docs.alfresco.com/5.0/tasks/jmx-access.html)
