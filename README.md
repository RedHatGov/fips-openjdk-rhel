# fips-openjdk-rhel
This repository details how to configure OpenJDK on RHEL 8 to use
FIPS 140-2 validated cryptographic modules or FIPS 140-2 modules
in process of being validated.

## Install needed packages
Install the following packages onto a minimal RHEL 8 instance.

    sudo yum -y install java-11-openjdk-devel nss-tools git

## Configure the certificate database
Configuring OpenJDK to use the SunPKCS11 provider delegates
cryptographic functions to the Mozilla Netscape Security Services
(NSS) on RHEL 8.  The NSS libraries are currently FIPS 140-2 validated
for RHEL 7 and earlier and they are in the process of being validated
by NIST for RHEL 8.  When RHEL 8 is run in FIPS enforcing mode, the
NSS libraries are limited to the approved FIPS algorithms.

The `certs` directory should be populated with required certificates
and keys prior to running the above script.  Please refer to these
[instructions](https://github.com/rlucente-se-jboss/fips-openjdk-rhel/blob/master/certs/README.md)
which create test certificates consisting of a root certificate
authority (CA), an intermediate CA signed by the root, and client
and server keys and certs signed by the intermediate CA.

### Global NSS configuration
The SunPKCS11 provider configuration in the `java.security` policy
file sets a single NSS database for all java processes on the RHEL
8 host.  When the java command line option `com.redhat.fips=true`
is used, the NSS FIPS configuration within the global `java.security`
file is in effect. An administrator needs to make sure that the NSS
database at `/etc/pki/nssdb` is properly populated with required
CAs, certificates, and keys.

### User-specific NSS configuration
Java processes can specify overrides to the global `java.security`
policy when the `security.useSystemPropertiesFile` property in the
global `java.security` policy file is set to `true`.  The java
command line option

    -Djava.security.properties=your-override-file

will override specific global policy settings with your specific
properties.  If you use the same command line option with two equal
signs

    -Djava.security.properties==your-override-file

then your policy entirely replaces the global `java.security` policy.
"With great power comes great responsibility" so be careful.

The configuration script in this project leaves the global
`java.security` policy unchanged by initializing an NSS database
that's unique to the local user's home directory.  The script also
creates a system property override file to change one property from
the global `java.security` policy file to refer to the NSS configuration
in the local user's home directory.

    cd
    git clone https://github.com/rlucente-se-jboss/fips-openjdk-rhel.git
    cd fips-openjdk-rhel
    ./config-fips-java.sh

## Enable FIPS mode
Put RHEL 8 into FIPS enforcing mode using the following commands:

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

