# fips-openjdk-rhel
This repository details how to configure OpenJDK on RHEL 8 using
FIPS 140-2 certified cryptographic libraries.

## Install needed packages
Install the following packages onto a minimal RHEL 8 instance.

    sudo yum -y install java-11-openjdk-devel nss-tools git

## Configure the certificate database
Configuring OpenJDK to use the SunPKCS11 provider delegates
cryptographic functions to the Mozilla Netscape Security Services
(NSS) on RHEL 8.  The NSS libraries are FIPS 140-2 certified, so
when RHEL 8 is run in FIPS enforcing mode, the NSS libraries are
limited to the FIPS approved algorithms.

The `certs` directory should be populated with required certificates
and keys prior to running the above script.  Please refer to the
[instructions](https://github.com/rlucente-se-jboss/fips-openjdk-rhel/blob/master/certs/README.md)
which creates a root CA, an intermediate CA signed by the root, and
client and server keys and certs signed by the intermediate CA.

### Global NSS configuration
The SunPKCS11 provider configuration in the `java.security` policy
file sets a single NSS database for all java processes on the RHEL
host.  When the java command line option `com.redhat.fips=true` is
used, the NSS FIPS configuration within the global `java.security`
file is in effect. An administrator needs to make sure that the NSS
database at `/etc/pki/nssdb` is properly populated with required
CAs, certificates, and keys.

### User-specific NSS configuration
To tailor `java.security` policy to a specific daemon or local user,
java system property overrides can be used. The configuration script
in this project leaves the global `java.security` policy unchanged
by initializings an NSS database that's unique to the local user's
home directory.  The script also creates a system property override
file to change settings in the global `java.security` policy file
to refer to the NSS configuration in the local user home directory.
This method enables each local user or daemon running java to have
their own NSS configuration and database on the same host.

    cd
    git clone https://github.com/rlucente-se-jboss/fips-openjdk-rhel.git
    cd fips-openjdk-rhel
    ./config-fips-java.sh

## Enable FIPS mode
Put RHEL 8 into FIPS compliant mode using the following commands:

    sudo fips-mode-setup --enable
    sudo reboot

After the system has rebooted, check that FIPS mode is correctly
enabled.

    sudo fips-mode-setup --check

## Confirm provider configuration
Use the included java source file to list the configured Java
Cryptography Architecture/Java Cryptography Extension (JCA/JCE) providers.

    cd ~/fips-openjdk-rhel
    javac ListProviders.java
    java -Djava.security.properties=$HOME/java.security.properties \
        -Dcom.redhat.fips=true ListProviders | head

The first listed provider should be `SunPKCS11-NSS-FIPS` which
indicates that FIPS is correctly configured for Java.

If you omit the `com.redhat.fips=true` parameter, the default
non-FIPS JCA/JCE providers are enabled.

    java -Djava.security.properties=$HOME/java.security.properties \
        ListProviders | head

