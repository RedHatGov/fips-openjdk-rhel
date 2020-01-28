#!/usr/bin/env bash

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

# check that fips mode is enabled
modutil -chkfips true -dbdir $NSSDB

# clean up the password file
rm -f $PASSFILE

# determine directory for the java.security policy file
JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 | grep java.home | awk '{print $NF}')
SEC_CONF=$JAVA_HOME/conf/security

# modify java.security policy to point to the local user directory
echo "Provide your password to execute sudo"
sudo sed -i 's/\(^fips.provider.1=SunPKCS11 \)..*/\1\${user.home}\/nss.fips.cfg/g' $SEC_CONF/java.security
cp $SEC_CONF/nss.fips.cfg $HOME

# point local user NSS config to the user's NSS database
ESCHOME=$(echo $HOME | sed 's/\//\\\//g')
echo "$ESCHOME"
sed -i 's/\/etc\/pki\/nssdb/'$ESCHOME'\/nssdb/g' $HOME/nss.fips.cfg

