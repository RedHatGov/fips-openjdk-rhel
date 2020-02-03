#!/usr/bin/env bash

# determine JRE home directory from the java properties
JRE_HOME=$(java -XshowSettings:properties -version |& grep java.home | \
    awk '{print $NF}')

# abort if java system property overrides are disabled
SEC_CONF=$(find -L $JRE_HOME -type f -name java.security)
if [[ -z "$(grep 'security.overridePropertiesFile=true' $SEC_CONF)" ]]
then
    echo
    echo "Make sure that OpenJDK allows system property overrides."
    echo "Edit $SEC_CONF"
    echo "and set 'security.overridePropertiesFile=true'."
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

# get the fips.provider.1 configuration from the java.security file
FIPS_PROVIDER=$(grep 'fips.provider.1=' $SEC_CONF | sed 's/^\(..*SunPKCS11\)..*/\1 \${user.home}\/nss.fips.cfg/g')

# create security property override file for the local user
cat > $HOME/java.security.properties <<END1
#
# This file overrides the values in the java.security policy file
# which can be found at:
#
#    $SEC_CONF
#
$FIPS_PROVIDER
END1

# point local user NSS config to the user's NSS database
cp $(dirname $SEC_CONF)/nss.fips.cfg $HOME
ESCHOME=$(echo $HOME | sed 's/\//\\\//g')
sed -i 's/\/etc\/pki\/nssdb/'$ESCHOME'\/nssdb/g' $HOME/nss.fips.cfg

