# fips-openjdk-rhel
This repository details how to configure OpenJDK on RHEL 8 to use
FIPS 140-2 validated cryptographic modules or FIPS 140-2 modules
in process of being validated.  RHEL 8 aligns OpenJDK behavior with
the system-wide cryptographic policy for FIPS mode. Additonally,
RHEL 8 introduces a new java command line parameter
`com.redhat.fips=true|false` and `fips.provider` settings that
greatly simplify configuring for FIPS.

## Install needed packages
Install the following packages onto a minimal RHEL 8 instance.

    sudo yum -y install java-11-openjdk-devel nss-tools git

Alternatively, you can install the `java-1.8.0-openjdk-devel`
package.

## Configure the certificate database
Configuring OpenJDK to use the SunPKCS11 provider delegates
cryptographic functions to the Mozilla Netscape Security Services
(NSS) on RHEL 8.  The NSS libraries are currently FIPS 140-2 validated
for RHEL 7 and earlier and they are validated or in the final steps
of being validated by NIST for RHEL 8.  When RHEL 8 is run in FIPS
enforcing mode, the NSS libraries are limited to the approved FIPS
algorithms.

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
policy when the `security.overridePropertiesFile=true` property in the
global policy file is set to `true`.  The java command line option

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

This will also cause OpenJDK by default to use only FIPS approved
algorithms.  After the system has rebooted, check that FIPS mode
is correctly enabled.

    sudo fips-mode-setup --check

## Confirm provider configuration
Use the included java source file to list the configured Java
Cryptography Architecture/Java Cryptography Extension (JCA/JCE) providers.

    cd ~/fips-openjdk-rhel
    javac ListProviders.java
    java -Djava.security.properties=$HOME/java.security.properties \
        ListProviders | head

The first listed provider should be `SunPKCS11-NSS-FIPS` which
indicates that FIPS is correctly configured for Java. The optional
command line parameter, `com.redhat.fips` defaults to `true` when
the system is in FIPS mode.

When in FIPS mode, setting the `com.redhat.fips=false` parameter
enables the default non-FIPS JCA/JCE providers.

    java -Djava.security.properties=$HOME/java.security.properties \
        -Dcom.redhat.fips=false ListProviders | head

## List the keys in the NSS database
The overrides in the `java.security.properties` file can also be
used by `keytool` to dump the certificates in the NSS database.
Simply type the following:

    keytool -J-Djava.security.properties=$HOME/java.security.properties \
        -keystore NONE -storetype PKCS11 -storepass 'admin1jboss!' \
        -list -v

Since the system is in FIPS mode, `com.redhat.fips` defaults to
`true` so it can be omitted from the `keytool` command.  The password
`admin1jboss!` matches the password that was used to initialize the
NSS database in the `config-fips-java.sh` script.  If you modified
that password, then change the above command accordingly.

