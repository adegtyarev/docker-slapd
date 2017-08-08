#!/usr/bin/env bash

#set -x
set -e

: ${LDAP_SUFFIX:=example}
: ${LDAP_ROOT_PW:=root}
: ${LDAP_ROOT_DN:=cn=admin,dc=$LDAP_SUFFIX}
: ${LDAP_DB_DIR:=/var/lib/ldap/$LDAP_SUFFIX}

LDAP_ROOT_SSHA=$(slappasswd -s $LDAP_ROOT_PW)

install -v -d -o openldap -g openldap $LDAP_DB_DIR

# Defaults are taken from Debian package
ldapadd -H ldapi:/// -Y EXTERNAL <<EOF
dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcDbDirectory: $LDAP_DB_DIR
olcSuffix: dc=$LDAP_SUFFIX
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to attrs=shadowLastChange by self write by * read
olcAccess: {2}to * by * read
olcRootDN: $LDAP_ROOT_DN
olcRootPW: $LDAP_ROOT_SSHA
olcDbCheckpoint: 512 30
olcDbIndex: objectClass eq
olcDbIndex: cn,uid eq
olcDbIndex: uidNumber,gidNumber eq
olcDbIndex: member,memberUid eq
olcDbMaxSize: 1073741824
EOF

echo -n $LDAP_ROOT_PW > /etc/ldapscripts/ldapscripts.passwd
