# Network Analytics Server

## Building the SSO library

### Requirements

- OpenJDK 11 (Spotfire 10 libraries are compiled with Java 11).
- The Spotfire server API library available locally.

### Configuring the local repository

In order to compile the SSO library, it needs the Spotfire API server library available locally.
There should be a dependency listed in the pom file `sso-pom.xml`, something like:

```xml
<dependencies>
    <dependency>
        <groupId>com.spotfire</groupId>
        <artifactId>server-parent</artifactId>
        <version>10.10.1-68</version>
    </dependency>
</dependencies>
```

In order to Maven to find the above library, it needs to install it locally (or in the Nexus server).
In order to install the Spotfire Server API JAR file in the local Maven repository:

```
mvn install:install-file \
-Dfile=spotfire-public-java-api.jar \
-DgroupId=com.spotfire \
-DartifactId=server-parent \
-Dversion=10.10.1-68 \
-Dpackaging=jar
```

Please pay attention that the `groupId`, `artifactId`  and `version` should match between the above command and the 
declared dependency in the `sso-pom.xml`.


### Building the package with Maven:

```
mvn clean package -f sso-pom.xml
```