# fips-openjdk-rhel
This repository details how to configure FIPS cryptography with
OpenJDK on RHEL 8.

## Install needed packages
Install the following packages onto a minimal RHEL 8 instance.

    sudo yum -y install java-11-openjdk-devel nss-tools git

## Configure the certificate database
OpenJDK delegates cryptographic functions to the Mozilla Netscape
Security Services (NSS) on RHEL 8.

The `certs` directory should be populated with required certificates
and keys prior to running the above script.  Please refer to the
[instructions](https://github.com/rlucente-se-jboss/fips-openjdk-rhel/blob/master/certs/README.md)
which creates a root CA, intermediate CA signed by the root, and
client and server keys and certs signed by the intermediate CA.

Use the script included in this repository to initialize that
database in a local user home directory.  The script will also
modify the global `java.security` policy file to refer to the NSS
database in the local user home directory.

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
Cryptography Architecture (JCA) providers.

    cd ~/fips-openjdk-rhel
    javac ListProviders.java
    java -Dcom.redhat.fips=true ListProviders | head

The first listed provider should be `SunPKCS11-NSS-FIPS` which
indicates that FIPS is correctly configured for Java.

