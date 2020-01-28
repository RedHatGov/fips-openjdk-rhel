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

The SunPKCS11 provider configuration in the `java.security` policy
file sets a single NSS database for all java processes on the RHEL
host.  To tailor that to specific local users or daemon processes
that have a defined home directory, the configuration script in
this project initializes an NSS database that's unique to the local
user's home directory.  The script will also modify the global
`java.security` policy file to refer to the NSS configuration in
the local user home directory.  Each local user or daemon running
java can have their own NSS configuration and database on the same
host.

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
    java -Dcom.redhat.fips=true ListProviders | head

The first listed provider should be `SunPKCS11-NSS-FIPS` which
indicates that FIPS is correctly configured for Java.

If you omit the `com.redhat.fips=true` parameter, the default
non-FIPS JCA/JCE providers are enabled.

    java ListProviders | head

