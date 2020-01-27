#!/usr/bin/env bash

WORKDIR=$(pushd $(dirname $0) &> /dev/null && pwd && popd &> /dev/null)

rm -fr $WORKDIR/nssdb
mkdir $WORKDIR/nssdb

PASSFILE=$WORKDIR/password.internal
echo 'admin1jboss!' > $PASSFILE

certutil -N -d $WORKDIR/nssdb -f $PASSFILE
certutil -A -d $WORKDIR/nssdb -a -n rootca \
  -i $WORKDIR/certs/ca.cert.pem -t CT,C,C -f $PASSFILE
certutil -A -d $WORKDIR/nssdb -a -n subrootca \
  -i $WORKDIR/certs/intermediate.cert.pem -t CT,C,C -f $PASSFILE
pk12util -i certs/server.p12 -d $WORKDIR/nssdb -k $PASSFILE -w $PASSFILE
certutil -L -d $WORKDIR/nssdb -h all
certutil -K -d $WORKDIR/nssdb -h all -f $PASSFILE

# modutil -fips true -dbdir $WORKDIR/nssdb
# modutil -chkfips true -dbdir $WORKDIR/nssdb

rm -f $PASSFILE

