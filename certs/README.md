This directory should have four files:

* ca.cert.pem - the root CA that signed the intermediate CA
* intermediate.cert.pem - the intermediate CA that signed both the server and client certificate
* client.p12 - the client certificate and key in PKCS #12 format
* server.p12 - the server certificate and key in PKCS #12 format

You can use [this github repository](https://github.com/rlucente-se-jboss/intranet-test-certs) to generate the above files.

