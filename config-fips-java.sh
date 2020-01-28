#!/usr/bin/env bash

# determine JRE home directory from the java properties
JRE_HOME=$(java -XshowSettings:properties -version |& grep java.home | \
    awk '{print $NF}')

# abort if java system property overrides are not enabled
SEC_CONF=$(find -L $JRE_HOME -type f -name java.security)
if [[ -z "$(grep 'security.useSystemPropertiesFile=true' $SEC_CONF)" ]]
then
    echo
    echo "Make sure that OpenJDK is configured to enable system property overrides."
    echo "Edit $JRE_HOME/conf/security/java.security"
    echo "and set 'security.useSystemPropertiesFile=true'."
    echo
    exit 1
fi

WORKDIR=$(pushd $(dirname $0) &> /dev/null && pwd && popd &> /dev/null)
NSSDB=$HOME/nssdb

# set default NSS database type to use legacy for Java compatibility
export NSS_DEFAULT_DB_TYPE="dbm"

# create password file for the NSS database
PASSFILE=$WORKDIR/password.internal
echo 'admin1jboss!' > $PASSFILE

# initialize the NSS database
rm -fr $NSSDB
mkdir $NSSDB
certutil -N -d $NSSDB -f $PASSFILE

# add the root CA
certutil -A -d $NSSDB -a -n rootca \
  -i $WORKDIR/certs/ca.cert.pem -t CT,C,C -f $PASSFILE

# add the intermediate CA
certutil -A -d $NSSDB -a -n subrootca \
  -i $WORKDIR/certs/intermediate.cert.pem -t CT,C,C -f $PASSFILE

# import the server cert and key
pk12util -i certs/server.p12 -d $NSSDB -k $PASSFILE -w $PASSFILE

# list all the certs and keys
certutil -L -d $NSSDB -h all
certutil -K -d $NSSDB -h all -f $PASSFILE

# clean up the password file
rm -f $PASSFILE

# create security property override file for the local user
cat > $HOME/java.security.properties <<END1
#
# This file overrides the values in the java.security policy file
# which can be found at:
#
#    JRE_HOME=$JRE_HOME
#    \$JRE_HOME/conf/security/java.security
#
fips.provider.1=SunPKCS11 \${user.home}/nss.fips.cfg
END1

# point local user NSS config to the user's NSS database
cp $JRE_HOME/conf/security/nss.fips.cfg $HOME
ESCHOME=$(echo $HOME | sed 's/\//\\\//g')
sed -i 's/\/etc\/pki\/nssdb/'$ESCHOME'\/nssdb/g' $HOME/nss.fips.cfg

